-- Feature: Task board (worker assignments)
-- Params: :tenant_id, :worker_id, :status
-- :worker_id and :status accept NULL to show all.
SELECT t.id AS task_id,
       t.task_title,
       t.description,
       w.id AS worker_id,
       w.full_name AS assigned_to,
       a.tag_number AS animal_tag_number,
       g.name AS group_name,
       t.due_date,
       (t.due_date - CURRENT_DATE) AS days_until_due,
       (t.due_date < CURRENT_DATE AND t.status IN ('pending', 'in_progress')) AS is_overdue,
       t.status,
       t.priority,
       t.completed_at,
       t.created_at
FROM task_assignments t
JOIN workers w ON w.id = t.worker_id
LEFT JOIN animals a ON a.id = t.related_animal_id
LEFT JOIN groups g ON g.id = t.related_group_id
WHERE t.tenant_id = :tenant_id
  AND (:worker_id IS NULL OR t.worker_id = :worker_id)
  AND (:status IS NULL OR t.status = CAST(:status AS task_status))
ORDER BY is_overdue DESC,
         CASE t.priority
           WHEN 'critical' THEN 0
           WHEN 'high' THEN 1
           WHEN 'medium' THEN 2
           ELSE 3
         END,
         t.due_date NULLS LAST;
