-- Feature: Daily attendance sheet (manager entry + worker acknowledgement)
-- Params: :tenant_id, :work_date
SELECT w.id AS worker_id,
       w.full_name,
       w.role,
       COALESCE(a.status::text, 'not_recorded') AS status,
       a.check_in,
       a.check_out,
       (a.acknowledged_at IS NOT NULL)         AS acknowledged,
       a.acknowledged_at,
       ru.full_name                            AS recorded_by,
       au.full_name                            AS acknowledged_by,
       a.notes,
       a.work_date
FROM workers w
LEFT JOIN attendance a
       ON a.tenant_id = w.tenant_id
      AND a.worker_id = w.id
      AND a.work_date = CAST(:work_date AS date)
LEFT JOIN users ru ON ru.id = a.recorded_by
LEFT JOIN users au ON au.id = a.acknowledged_by
WHERE w.tenant_id = :tenant_id
  AND w.is_active
ORDER BY w.full_name;
