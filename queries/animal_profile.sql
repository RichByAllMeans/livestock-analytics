-- Feature: Animal profile (single record with current state and totals)
-- Params: :tenant_id, :animal_id
SELECT a.id AS animal_id,
       a.tag_number,
       a.name,
       a.species,
       COALESCE(b.name, a.breed_name_raw)              AS breed,
       a.sex,
       a.date_of_birth,
       a.date_of_birth_is_estimated,
       date_part('year', age(a.date_of_birth))::int    AS age_years,
       a.status,
       a.origin,
       a.origin_source,
       a.rfid_code,
       a.current_owner,
       a.acquisition_date,
       a.acquisition_cost,
       a.sale_date,
       a.sale_price,
       g.name                                          AS current_group,
       pg.name                                         AS parent_group,
       dam.tag_number                                  AS dam_tag_number,
       dam.name                                        AS dam_name,
       sire.tag_number                                 AS sire_tag_number,
       sire.name                                       AS sire_name,
       w.weight_kg                                     AS current_weight_kg,
       w.event_date                                    AS last_weighed_on,
       (SELECT h.event_type::text
          FROM health_records h
         WHERE h.tenant_id = a.tenant_id AND h.animal_id = a.id
         ORDER BY h.occurred_at DESC
         LIMIT 1)                                     AS last_health_event,
       (SELECT max(h.occurred_at)::date
          FROM health_records h
         WHERE h.tenant_id = a.tenant_id AND h.animal_id = a.id) AS last_health_date,
       (SELECT min(h.next_due_date)
          FROM health_records h
         WHERE h.tenant_id = a.tenant_id
           AND h.animal_id = a.id
           AND h.record_status = 'scheduled')         AS next_health_due,
       (SELECT count(*) FROM health_records h
         WHERE h.tenant_id = a.tenant_id AND h.animal_id = a.id) AS health_events,
       (SELECT COALESCE(sum(h.cost), 0) FROM health_records h
         WHERE h.tenant_id = a.tenant_id AND h.animal_id = a.id) AS health_spend,
       (SELECT COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'income'), 0)
          FROM transactions t
         WHERE t.tenant_id = a.tenant_id AND t.related_animal_id = a.id) AS income,
       (SELECT COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'expense'), 0)
          FROM transactions t
         WHERE t.tenant_id = a.tenant_id AND t.related_animal_id = a.id) AS expense,
       (SELECT count(*) FROM animals c
         WHERE c.tenant_id = a.tenant_id
           AND (c.dam_id = a.id OR c.sire_id = a.id)) AS registered_progeny,
       a.photo_url,
       a.notes,
       a.is_legacy,
       a.created_at,
       a.updated_at
FROM animals a
LEFT JOIN breeds b ON b.id = a.breed_id
LEFT JOIN groups g ON g.id = a.current_group_id
LEFT JOIN groups pg ON pg.id = g.parent_group_id
LEFT JOIN animals dam ON dam.id = a.dam_id
LEFT JOIN animals sire ON sire.id = a.sire_id
LEFT JOIN v_animal_current_weight w ON w.animal_id = a.id
WHERE a.tenant_id = :tenant_id
  AND a.id = :animal_id;
