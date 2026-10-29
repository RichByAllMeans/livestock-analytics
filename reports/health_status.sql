-- Report: Health status
-- Params: :tenant_id, :from, :to
-- Current status from latest event + spend within the window + next due date.
WITH latest AS (
  SELECT DISTINCT ON (animal_id) animal_id, event_type, occurred_at
  FROM health_records
  WHERE tenant_id = :tenant_id
  ORDER BY animal_id, occurred_at DESC
)
SELECT a.tag_number,
       a.name,
       a.status              AS animal_status,
       a.group_name,
       l.event_type          AS last_health_event,
       l.occurred_at::date   AS last_event_date,
       COALESCE(sum(h.cost), 0)                         AS health_spend,
       date_part('day', now() - l.occurred_at)::int     AS days_since_last_event,
       (SELECT min(hr.next_due_date)
          FROM health_records hr
         WHERE hr.tenant_id = :tenant_id
           AND hr.animal_id = a.animal_id
           AND hr.record_status = 'scheduled')          AS next_due_date
FROM dim_animal a
LEFT JOIN latest l        ON l.animal_id = a.animal_id
LEFT JOIN health_records h
       ON h.animal_id = a.animal_id
      AND h.occurred_at::date BETWEEN :from AND :to
WHERE a.tenant_id = :tenant_id
GROUP BY a.animal_id, a.tag_number, a.name, a.status, a.group_name,
         l.event_type, l.occurred_at
ORDER BY days_since_last_event DESC NULLS LAST;
