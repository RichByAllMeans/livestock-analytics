-- Feature: Notifications inbox / delivery queue
-- Params: :tenant_id, :user_id, :status
-- :user_id and :status accept NULL to show all.
SELECT n.id AS notification_id,
       n.created_at,
       n.type,
       n.priority,
       n.title,
       n.subject,
       n.body,
       n.channel,
       n.status,
       n.scheduled_at,
       n.sent_at,
       n.read_at,
       n.dismissed_at,
       n.related_entity_type,
       n.related_entity_id,
       n.attempts,
       n.error_message
FROM notifications n
WHERE n.tenant_id = :tenant_id
  AND (:user_id IS NULL OR n.recipient_user_id = :user_id)
  AND (:status IS NULL OR n.status = CAST(:status AS notification_status))
ORDER BY CASE n.priority
           WHEN 'critical' THEN 0
           WHEN 'high' THEN 1
           WHEN 'medium' THEN 2
           ELSE 3
         END,
         n.created_at DESC;
