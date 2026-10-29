-- Feature: Accounts receivable aging
-- Params: :tenant_id, :as_of
SELECT i.id AS invoice_id,
       i.invoice_number,
       i.customer_name,
       i.customer_contact,
       i.issue_date,
       i.due_date,
       i.status,
       i.total_amount,
       vb.amount_paid,
       vb.balance,
       (CAST(:as_of AS date) - i.due_date) AS days_past_due,
       CASE
         WHEN CAST(:as_of AS date) <= i.due_date THEN 'current'
         WHEN CAST(:as_of AS date) - i.due_date <= 30 THEN '1-30'
         WHEN CAST(:as_of AS date) - i.due_date <= 60 THEN '31-60'
         WHEN CAST(:as_of AS date) - i.due_date <= 90 THEN '61-90'
         ELSE '90+'
       END AS aging_bucket
FROM invoices i
JOIN v_invoice_balance vb ON vb.invoice_id = i.id
WHERE i.tenant_id = :tenant_id
  AND i.status <> 'cancelled'
  AND vb.balance > 0
ORDER BY days_past_due DESC, i.due_date;
