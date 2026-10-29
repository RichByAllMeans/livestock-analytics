-- Feature: Health work queue (scheduled events due within :days)
-- Params: :tenant_id, :days (default 30 when NULL)
SELECT a.tag_number,
       a.name AS animal_name,
       g.name AS group_name,
       h.event_type,
       h.next_due_date,
       (h.next_due_date - CURRENT_DATE) AS days_until_due,
       m.name AS medication,
       w.full_name AS vet,
       h.id AS health_record_id
FROM health_records h
JOIN animals a ON a.id = h.animal_id
LEFT JOIN groups g ON g.id = a.current_group_id
LEFT JOIN medications m ON m.id = h.medication_id
LEFT JOIN workers w ON w.id = h.vet_id
WHERE h.tenant_id = :tenant_id
  AND h.record_status = 'scheduled'
  AND h.next_due_date IS NOT NULL
  AND h.next_due_date <= CURRENT_DATE + COALESCE(:days, 30)
  AND a.status NOT IN ('dead', 'deceased', 'sold', 'transferred', 'archived')
ORDER BY h.next_due_date, a.tag_number;
