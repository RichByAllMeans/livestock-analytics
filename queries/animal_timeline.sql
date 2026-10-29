-- Feature: Animal timeline (unified, newest first)
-- Params: :tenant_id, :animal_id
WITH events AS (
  SELECT h.occurred_at AS event_at,
         'health'::text AS event_type,
         h.event_type::text
           || COALESCE(' - ' || h.diagnosis, '')
           || CASE WHEN h.record_status = 'scheduled' THEN ' (scheduled)' ELSE '' END
           AS summary,
         h.id AS reference_id
  FROM health_records h
  WHERE h.tenant_id = :tenant_id
    AND h.animal_id = :animal_id

  UNION ALL

  SELECT l.event_date,
         'history'::text,
         CASE l.event_type
           WHEN 'weight' THEN 'Weight: ' || l.weight_kg || ' kg'
           WHEN 'location' THEN 'Location: ' || COALESCE(l.location_from, '?')
                                || ' -> ' || COALESCE(l.location_to, '?')
           WHEN 'ownership' THEN 'Owner: ' || COALESCE(l.previous_owner, '?')
                                 || ' -> ' || COALESCE(l.new_owner, '?')
           ELSE l.event_type::text || COALESCE(': ' || l.new_value, '')
         END,
         l.id
  FROM animal_history_log l
  WHERE l.tenant_id = :tenant_id
    AND l.animal_id = :animal_id

  UNION ALL

  SELECT gh.start_date::timestamptz,
         'group_change'::text,
         'Group: ' || COALESCE(g.name, '?') || COALESCE(' (' || gh.reason || ')', ''),
         gh.id
  FROM animal_group_history gh
  LEFT JOIN groups g ON g.id = gh.group_id
  WHERE gh.tenant_id = :tenant_id
    AND gh.animal_id = :animal_id

  UNION ALL

  SELECT b.occurred_at,
         'breeding'::text,
         b.event_type::text || ' (' || b.breeding_status::text || ')'
           || COALESCE(' - ' || b.notes, ''),
         b.id
  FROM breeding_events b
  WHERE b.tenant_id = :tenant_id
    AND (b.dam_id = :animal_id OR b.sire_id = :animal_id)

  UNION ALL

  SELECT m.date_of_death::timestamptz,
         'mortality'::text,
         'Died: ' || COALESCE(m.cause_of_death, 'unknown cause')
           || COALESCE(' (' || m.disposal_method || ')', ''),
         m.id
  FROM mortality_log m
  WHERE m.tenant_id = :tenant_id
    AND m.animal_id = :animal_id

  UNION ALL

  SELECT t.occurred_at,
         'financial'::text,
         t.txn_type::text || ': ' || t.currency || ' ' || t.amount
           || COALESCE(' - ' || t.description, ''),
         t.id
  FROM transactions t
  WHERE t.tenant_id = :tenant_id
    AND t.related_animal_id = :animal_id
)
SELECT event_at,
       event_type,
       summary,
       reference_id
FROM events
ORDER BY event_at DESC;
