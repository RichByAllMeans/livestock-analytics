-- Report: Financial summary (PDF export)
-- Params: :tenant_id, :from, :to
SELECT t.category_code,
       COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'income'), 0)  AS income,
       COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'expense'), 0) AS expense,
       COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'income'), 0)
       - COALESCE(sum(t.amount) FILTER (WHERE t.txn_type = 'expense'), 0) AS net
FROM fct_transaction t
WHERE t.tenant_id = :tenant_id
  AND t.occurred_on BETWEEN :from AND :to
GROUP BY t.category_code
ORDER BY net DESC;
