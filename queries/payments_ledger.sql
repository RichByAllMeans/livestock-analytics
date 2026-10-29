-- Feature: Payments received ledger
-- Params: :tenant_id, :from, :to
SELECT p.payment_date,
       i.invoice_number,
       i.customer_name,
       p.amount,
       i.currency,
       p.payment_method,
       p.reference_number,
       u.full_name AS recorded_by,
       p.notes,
       p.id AS payment_id
FROM payments p
JOIN invoices i ON i.id = p.invoice_id
LEFT JOIN users u ON u.id = p.recorded_by
WHERE p.tenant_id = :tenant_id
  AND p.payment_date BETWEEN :from AND :to
ORDER BY p.payment_date DESC, p.created_at DESC;
