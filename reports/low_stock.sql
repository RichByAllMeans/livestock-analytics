-- Report: Low stock + reorder (general inventory)
-- Params: :tenant_id
SELECT ii.name,
       ii.sku,
       ii.unit,
       ii.current_stock,
       ii.reorder_level,
       (ii.reorder_level - ii.current_stock) AS shortfall,
       GREATEST(COALESCE(ii.reorder_quantity, ii.reorder_level - ii.current_stock), 0)
         AS suggested_reorder,
       ii.unit_cost,
       GREATEST(COALESCE(ii.reorder_quantity, ii.reorder_level - ii.current_stock), 0)
         * COALESCE(ii.unit_cost, 0) AS estimated_cost
FROM inventory_items ii
WHERE ii.tenant_id = :tenant_id
  AND ii.current_stock <= ii.reorder_level
ORDER BY shortfall DESC;
