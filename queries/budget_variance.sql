-- Feature: Budget vs actual variance
-- Params: :tenant_id
SELECT budget_id,
       name,
       category_code,
       period_start,
       period_end,
       planned_amount,
       actual_expense,
       variance,
       CASE WHEN planned_amount > 0
            THEN round(100.0 * variance / planned_amount, 1)
       END AS variance_pct,
       CASE
         WHEN actual_expense > planned_amount THEN 'over'
         WHEN actual_expense < planned_amount THEN 'under'
         ELSE 'on_budget'
       END AS budget_state
FROM v_budget_variance
WHERE tenant_id = :tenant_id
ORDER BY period_start DESC, name;
