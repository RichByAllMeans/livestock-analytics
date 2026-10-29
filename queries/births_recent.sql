-- Feature: Recent births and offspring outcomes
-- Params: :tenant_id, :from, :to
SELECT br.birth_date,
       d.tag_number AS dam_tag_number,
       d.name AS dam_name,
       b.breeding_method,
       br.total_offspring,
       br.live_births,
       br.stillbirths,
       count(o.id)                                                AS offspring_records,
       count(o.id) FILTER (WHERE o.outcome = 'live')              AS live,
       count(o.id) FILTER (WHERE o.outcome = 'stillborn')         AS stillborn,
       count(o.id) FILTER (WHERE o.outcome = 'died_before_weaning') AS died_before_weaning,
       count(o.id) FILTER (WHERE o.outcome = 'weaned')            AS weaned,
       br.notes,
       br.id AS birth_record_id
FROM birth_records br
JOIN animals d ON d.id = br.dam_id
JOIN breeding_events b ON b.id = br.breeding_event_id
LEFT JOIN offspring o ON o.birth_record_id = br.id
WHERE br.tenant_id = :tenant_id
  AND br.birth_date BETWEEN :from AND :to
GROUP BY br.id, br.birth_date, d.tag_number, d.name, b.breeding_method,
         br.total_offspring, br.live_births, br.stillbirths, br.notes
ORDER BY br.birth_date DESC;
