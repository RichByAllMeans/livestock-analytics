-- Report: Upcoming births
-- Params: :tenant_id
SELECT d.tag_number AS dam_tag_number,
       d.name AS dam_name,
       b.breeding_method,
       b.breeding_status,
       b.occurred_at::date AS breeding_date,
       b.expected_due_date,
       (b.expected_due_date - CURRENT_DATE) AS days_until_due
FROM breeding_events b
JOIN animals d ON d.id = b.dam_id
WHERE b.tenant_id = :tenant_id
  AND b.expected_due_date IS NOT NULL
  AND b.breeding_status IN ('planned', 'confirmed_pregnant')
ORDER BY b.expected_due_date;
