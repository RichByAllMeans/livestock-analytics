-- Dimensions -----------------------------------------------------------------

-- dim_tenant.sql
CREATE OR REPLACE VIEW dim_tenant AS
SELECT id AS tenant_id, name AS tenant_name, subscription_plan,
       subscription_status, created_at
FROM tenants;

-- dim_group.sql
CREATE OR REPLACE VIEW dim_group AS
SELECT g.id AS group_id, g.tenant_id, g.name AS group_name, g.type AS group_type,
       g.parent_group_id, g.capacity, g.location
FROM groups g;

-- dim_animal.sql
CREATE OR REPLACE VIEW dim_animal AS
SELECT a.id AS animal_id, a.tenant_id, a.tag_number, a.name, a.sex,
       a.origin, a.status, a.date_of_birth,
       b.name AS breed_name, a.species,
       a.dam_id, a.sire_id,
       date_part('year', age(a.date_of_birth))::int AS age_years,
       a.rfid_code,
       a.current_group_id,
       g.name AS group_name,
       a.acquisition_date,
       a.current_owner,
       a.date_of_birth_is_estimated,
       a.is_legacy
FROM animals a
LEFT JOIN breeds b ON b.id = a.breed_id
LEFT JOIN groups g ON g.id = a.current_group_id;

-- dim_worker.sql
CREATE OR REPLACE VIEW dim_worker AS
SELECT w.id AS worker_id, w.tenant_id, w.user_id, w.full_name, w.role,
       w.role_title, w.email, w.phone, w.hired_date, w.is_active, w.is_legacy
FROM workers w;

-- dim_inventory_item.sql
CREATE OR REPLACE VIEW dim_inventory_item AS
SELECT ii.id AS inventory_item_id, ii.tenant_id, ii.category_id,
       c.name AS category_name, ii.name, ii.sku, ii.unit,
       ii.reorder_level, ii.reorder_quantity, ii.unit_cost,
       ii.preferred_supplier_id, ii.storage_location
FROM inventory_items ii
JOIN inventory_categories c ON c.id = ii.category_id;

-- dim_medication.sql
CREATE OR REPLACE VIEW dim_medication AS
SELECT m.id AS medication_id, m.tenant_id, m.name, m.type, m.manufacturer,
       m.unit, m.cost_per_unit, m.withdrawal_period_meat_days,
       m.withdrawal_period_milk_days
FROM medications m;

-- dim_date.sql  (calendar spine; generate a range wide enough for trends)
CREATE OR REPLACE VIEW dim_date AS
SELECT d::date AS date_key,
       extract(year  FROM d)::int  AS year,
       extract(month FROM d)::int  AS month,
       to_char(d, 'Mon')           AS month_name,
       extract(quarter FROM d)::int AS quarter,
       date_trunc('month', d)::date AS month_start
FROM generate_series('2020-01-01'::date, '2035-12-31'::date, '1 day') AS d;

-- Facts -----------------------------------------------------------------------

-- fct_health_event.sql (append-only source → immutable fact)
CREATE OR REPLACE VIEW fct_health_event AS
SELECT h.id AS health_event_id, h.tenant_id, h.animal_id, h.event_type,
       h.occurred_at::date AS occurred_on, h.cost, h.currency, h.medication,
       h.record_status, h.next_due_date, h.medication_id, h.vet_id, h.is_legacy
FROM health_records h;

-- fct_breeding_event.sql
CREATE OR REPLACE VIEW fct_breeding_event AS
SELECT b.id AS breeding_event_id, b.tenant_id, b.dam_id, b.sire_id,
       b.event_type, b.breeding_method, b.breeding_status,
       b.occurred_at::date AS breeding_date, b.expected_due_date,
       b.actual_birth_date, b.is_legacy
FROM breeding_events b;

-- fct_mortality.sql
CREATE OR REPLACE VIEW fct_mortality AS
SELECT m.id AS mortality_id, m.tenant_id, m.animal_id,
       m.date_of_death, m.cause_of_death, m.diagnosed_by,
       m.necropsy_performed, m.disposal_method
FROM mortality_log m;

-- fct_transaction.sql
CREATE OR REPLACE VIEW fct_transaction AS
SELECT t.id AS transaction_id, t.tenant_id, t.txn_type,
       t.occurred_at::date AS occurred_on, t.amount, t.currency, t.category,
       t.category_code, t.related_animal_id, t.related_group_id,
       t.related_invoice_id, t.payment_method, t.is_legacy
FROM transactions t;

-- fct_payment.sql
CREATE OR REPLACE VIEW fct_payment AS
SELECT p.id AS payment_id, p.tenant_id, p.invoice_id,
       p.payment_date, p.amount, p.payment_method
FROM payments p;

-- fct_attendance.sql
CREATE OR REPLACE VIEW fct_attendance AS
SELECT a.id AS attendance_id, a.tenant_id, a.worker_id, a.work_date,
       a.status, (a.acknowledged_at IS NOT NULL) AS acknowledged
FROM attendance a;

-- fct_stock_movement.sql (legacy feed ledger)
CREATE OR REPLACE VIEW fct_stock_movement AS
SELECT m.id AS movement_id, m.tenant_id, m.feed_item_id, m.movement_type,
       m.quantity, m.occurred_at::date AS occurred_on
FROM stock_movements m;

-- fct_stock_transaction.sql (general inventory ledger)
CREATE OR REPLACE VIEW fct_stock_transaction AS
SELECT s.id AS stock_transaction_id, s.tenant_id, s.inventory_item_id,
       s.transaction_type, s.quantity, s.transaction_date::date AS occurred_on,
       s.related_animal_id, s.related_group_id, s.performed_by
FROM stock_transactions s;

-- fct_inventory_snapshot.sql (current state, one row per item)
CREATE OR REPLACE VIEW fct_inventory_snapshot AS
SELECT ii.id AS inventory_item_id, ii.tenant_id, ii.category_id,
       ii.current_stock, ii.reorder_level,
       (ii.current_stock <= ii.reorder_level) AS is_low_stock,
       ii.unit_cost,
       ii.current_stock * COALESCE(ii.unit_cost, 0) AS stock_value
FROM inventory_items ii;
