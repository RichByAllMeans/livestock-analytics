-- Feature: Inventory movement ledger (signed quantities)
-- Params: :tenant_id, :inventory_item_id, :from, :to
-- :inventory_item_id accepts NULL to show all items.
SELECT st.transaction_date::date AS occurred_on,
       st.transaction_date,
       ii.name AS item,
       ii.unit,
       ii.category_id,
       st.transaction_type,
       CASE st.transaction_type
         WHEN 'purchase' THEN abs(st.quantity)
         WHEN 'consumption' THEN -abs(st.quantity)
         WHEN 'waste' THEN -abs(st.quantity)
         WHEN 'adjustment' THEN st.quantity
         WHEN 'transfer' THEN st.quantity
       END AS signed_quantity,
       st.quantity,
       ii.current_stock,
       ii.reorder_level,
       u.full_name AS performed_by,
       st.notes,
       st.id AS stock_transaction_id
FROM stock_transactions st
JOIN inventory_items ii ON ii.id = st.inventory_item_id
LEFT JOIN users u ON u.id = st.performed_by
WHERE st.tenant_id = :tenant_id
  AND (:inventory_item_id IS NULL OR st.inventory_item_id = :inventory_item_id)
  AND st.transaction_date::date BETWEEN :from AND :to
ORDER BY st.transaction_date DESC, st.created_at DESC;
