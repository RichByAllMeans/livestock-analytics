-- Feature: Audit trail (owner/manager only)
-- Params: :tenant_id, :from, :to, :entity_type, :actor_user_id
-- :entity_type and :actor_user_id accept NULL to show all.
SELECT al.occurred_at,
       u.full_name AS actor,
       al.action,
       al.entity_type,
       al.entity_id,
       al.old_values,
       al.new_values,
       al.ip_address,
       al.user_agent,
       al.id AS audit_id
FROM audit_log al
LEFT JOIN users u ON u.id = al.actor_user_id
WHERE al.tenant_id = :tenant_id
  AND al.occurred_at::date BETWEEN :from AND :to
  AND (:entity_type IS NULL OR al.entity_type = :entity_type)
  AND (:actor_user_id IS NULL OR al.actor_user_id = :actor_user_id)
ORDER BY al.occurred_at DESC;
