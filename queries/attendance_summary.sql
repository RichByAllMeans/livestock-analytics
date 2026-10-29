-- Feature: Attendance summary per worker
-- Params: :tenant_id, :from, :to
SELECT w.id AS worker_id,
       w.full_name,
       w.role,
       count(a.id)                                                   AS days_recorded,
       count(a.id) FILTER (WHERE a.status = 'present')               AS present,
       count(a.id) FILTER (WHERE a.status = 'absent')                AS absent,
       count(a.id) FILTER (WHERE a.status = 'late')                  AS late,
       count(a.id) FILTER (WHERE a.status = 'excused')               AS excused,
       count(a.id) FILTER (WHERE a.acknowledged_at IS NOT NULL)      AS acknowledged,
       count(a.id) FILTER (WHERE a.acknowledged_at IS NULL)          AS unacknowledged,
       CASE WHEN count(a.id) > 0
            THEN round(100.0 * count(a.id) FILTER (WHERE a.status IN ('present', 'late'))
                       / count(a.id), 1)
       END                                                           AS attendance_rate_pct,
       round(COALESCE(sum(
         CASE WHEN a.check_in IS NOT NULL AND a.check_out IS NOT NULL
              THEN extract(epoch FROM (a.check_out - a.check_in)) / 3600.0
         END), 0), 1)                                                AS hours_worked
FROM workers w
LEFT JOIN attendance a
       ON a.tenant_id = w.tenant_id
      AND a.worker_id = w.id
      AND a.work_date BETWEEN :from AND :to
WHERE w.tenant_id = :tenant_id
  AND w.is_active
GROUP BY w.id, w.full_name, w.role
ORDER BY w.full_name;
