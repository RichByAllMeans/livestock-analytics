-- Feature: Dashboard overview (single-row numeric readouts)
-- Params: :tenant_id
WITH herd AS (
  SELECT count(*) FILTER (WHERE status = 'active')                AS active_animals,
         count(DISTINCT species) FILTER (WHERE status = 'active') AS species_count,
         count(*) FILTER (WHERE status = 'quarantined')           AS quarantined_animals
  FROM animals
  WHERE tenant_id = :tenant_id
),
health AS (
  SELECT count(*) AS health_due_30
  FROM health_records h
  JOIN animals a ON a.id = h.animal_id
  WHERE h.tenant_id = :tenant_id
    AND h.record_status = 'scheduled'
    AND h.next_due_date IS NOT NULL
    AND h.next_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 30
    AND a.status NOT IN ('dead', 'deceased', 'sold', 'transferred', 'archived')
),
breeding AS (
  SELECT count(*) AS breeding_due_60
  FROM breeding_events b
  WHERE b.tenant_id = :tenant_id
    AND b.breeding_status IN ('planned', 'confirmed_pregnant')
    AND b.expected_due_date BETWEEN CURRENT_DATE AND CURRENT_DATE + 60
),
stock AS (
  SELECT count(*) AS low_stock_items
  FROM inventory_items ii
  WHERE ii.tenant_id = :tenant_id
    AND ii.current_stock <= ii.reorder_level
),
supply AS (
  SELECT count(*) AS open_purchase_orders
  FROM purchase_orders po
  WHERE po.tenant_id = :tenant_id
    AND po.status NOT IN ('received', 'cancelled')
),
finance AS (
  SELECT COALESCE(sum(vb.balance), 0) AS outstanding_receivables,
         count(*) FILTER (WHERE i.due_date < CURRENT_DATE) AS overdue_invoices
  FROM v_invoice_balance vb
  JOIN invoices i ON i.id = vb.invoice_id
  WHERE vb.tenant_id = :tenant_id
    AND i.status <> 'cancelled'
    AND vb.balance > 0
),
ledger AS (
  SELECT COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'income'), 0)  AS income_mtd,
         COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'expense'), 0) AS expense_mtd,
         COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'income'), 0)
         - COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'expense'), 0) AS net_mtd
  FROM transactions t
  WHERE t.tenant_id = :tenant_id
    AND t.occurred_at::date >= date_trunc('month', CURRENT_DATE)::date
    AND t.occurred_at::date <= CURRENT_DATE
),
work AS (
  SELECT (SELECT count(*) FROM task_assignments ta
           WHERE ta.tenant_id = :tenant_id
             AND ta.status IN ('pending', 'in_progress'))          AS open_tasks,
         (SELECT count(*) FROM notifications n
           WHERE n.tenant_id = :tenant_id
             AND n.status = 'pending')                             AS pending_notifications,
         (SELECT count(*) FROM attendance at
           WHERE at.tenant_id = :tenant_id
             AND at.work_date >= CURRENT_DATE - 7
             AND at.acknowledged_at IS NULL)                       AS unacknowledged_attendance_7d
),
mortality AS (
  SELECT count(*) AS deaths_mtd
  FROM mortality_log m
  WHERE m.tenant_id = :tenant_id
    AND m.date_of_death >= date_trunc('month', CURRENT_DATE)::date
)
SELECT CURRENT_DATE AS as_of,
       herd.active_animals,
       herd.species_count,
       herd.quarantined_animals,
       health.health_due_30,
       breeding.breeding_due_60,
       stock.low_stock_items,
       supply.open_purchase_orders,
       finance.outstanding_receivables,
       finance.overdue_invoices,
       ledger.income_mtd,
       ledger.expense_mtd,
       ledger.net_mtd,
       work.open_tasks,
       work.pending_notifications,
       work.unacknowledged_attendance_7d,
       mortality.deaths_mtd
FROM herd, health, breeding, stock, supply, finance, ledger, work, mortality;
