-- Report: Reorder recommendations
-- Params: :tenant_id
SELECT ii.name,
       ii.unit,
       ii.current_stock,
       ii.reorder_level,
       GREATEST(COALESCE(ii.reorder_quantity, ii.reorder_level - ii.current_stock), 0)
         AS suggested_quantity,
       ii.unit_cost,
       GREATEST(COALESCE(ii.reorder_quantity, ii.reorder_level - ii.current_stock), 0)
         * COALESCE(ii.unit_cost, 0) AS estimated_cost,
       s.name AS preferred_supplier
FROM inventory_items ii
LEFT JOIN suppliers s ON s.id = ii.preferred_supplier_id
WHERE ii.tenant_id = :tenant_id
  AND ii.current_stock <= ii.reorder_level
ORDER BY estimated_cost DESC;
