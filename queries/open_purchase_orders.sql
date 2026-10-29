-- Feature: Open purchase orders (supply pipeline)
-- Params: :tenant_id
SELECT po.id AS purchase_order_id,
       s.name AS supplier,
       s.phone AS supplier_phone,
       po.order_date,
       po.expected_delivery_date,
       po.status,
       count(poi.id) AS line_items,
       COALESCE(sum(poi.subtotal), po.total_cost, 0) AS order_value,
       (po.expected_delivery_date - CURRENT_DATE) AS days_until_delivery,
       (po.expected_delivery_date < CURRENT_DATE) AS is_overdue,
       po.notes
FROM purchase_orders po
JOIN suppliers s ON s.id = po.supplier_id
LEFT JOIN purchase_order_items poi ON poi.purchase_order_id = po.id
WHERE po.tenant_id = :tenant_id
  AND po.status NOT IN ('received', 'cancelled')
GROUP BY po.id, s.name, s.phone, po.order_date, po.expected_delivery_date,
         po.status, po.total_cost, po.notes
ORDER BY is_overdue DESC, po.expected_delivery_date NULLS LAST, po.order_date;
