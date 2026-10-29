-- Report: Mortality summary
-- Params: :tenant_id, :from, :to
SELECT date_trunc('month', m.date_of_death)::date AS month,
       count(*)                                   AS deaths,
       count(*) FILTER (WHERE m.necropsy_performed) AS necropsies,
       count(*) FILTER (WHERE m.cause_of_death IS NOT NULL) AS diagnosed
FROM fct_mortality m
WHERE m.tenant_id = :tenant_id
  AND m.date_of_death BETWEEN :from AND :to
GROUP BY 1
ORDER BY 1;
