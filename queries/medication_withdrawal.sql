-- Feature: Food-safety withdrawal compliance (animals still in withdrawal)
-- Params: :tenant_id
SELECT a.tag_number,
       a.name AS animal_name,
       a.species,
       h.event_type,
       h.occurred_at::date AS treated_on,
       COALESCE(m.name, h.medication) AS medication,
       h.withdrawal_end_date,
       (h.withdrawal_end_date - CURRENT_DATE) AS days_remaining,
       m.withdrawal_period_meat_days,
       m.withdrawal_period_milk_days,
       h.id AS health_record_id
FROM health_records h
JOIN animals a ON a.id = h.animal_id
LEFT JOIN medications m ON m.id = h.medication_id
WHERE h.tenant_id = :tenant_id
  AND h.withdrawal_end_date IS NOT NULL
  AND h.withdrawal_end_date >= CURRENT_DATE
  AND a.status NOT IN ('dead', 'deceased', 'sold', 'transferred', 'archived')
ORDER BY h.withdrawal_end_date, a.tag_number;
