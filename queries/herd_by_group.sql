-- Feature: Herd composition by group (pen/paddock/herd)
-- Params: :tenant_id
SELECT g.id AS group_id,
       g.name AS group_name,
       g.type AS group_type,
       pg.name AS parent_group,
       g.location,
       g.capacity,
       count(a.id)                                            AS total_animals,
       count(a.id) FILTER (WHERE a.status = 'active')         AS active_animals,
       count(a.id) FILTER (WHERE a.status = 'active' AND a.sex = 'female') AS active_females,
       count(a.id) FILTER (WHERE a.status = 'active' AND a.sex = 'male')   AS active_males,
       count(a.id) FILTER (WHERE a.status = 'quarantined')    AS quarantined_animals,
       CASE WHEN g.capacity > 0
            THEN round(100.0 * count(a.id) FILTER (WHERE a.status = 'active') / g.capacity, 1)
       END                                                    AS capacity_used_pct
FROM groups g
LEFT JOIN groups pg ON pg.id = g.parent_group_id
LEFT JOIN animals a ON a.tenant_id = g.tenant_id AND a.current_group_id = g.id
WHERE g.tenant_id = :tenant_id
GROUP BY g.id, g.name, g.type, pg.name, g.location, g.capacity
ORDER BY g.name;
