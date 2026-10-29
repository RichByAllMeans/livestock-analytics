# Feature queries

Read-only SQL for each product feature. The backend executes these and returns
plain rows for pages, forms and PDF endpoints. Every query is tenant-scoped and
uses the same `:param` convention as `reports/`.

Set the tenant on the connection as well:

```sql
SET app.tenant_id = '<tenant-uuid>';
```

## Query catalogue

| File | Feature | Params |
|------|---------|--------|
| `dashboard_overview.sql` | One-row dashboard readout (herd, health, breeding, stock, finance, tasks, notifications) | `:tenant_id` |
| `animal_registry.sql` | Searchable animal list | `:tenant_id`, `:search`, `:status`, `:species`, `:group_id`, `:limit`, `:offset` |
| `animal_profile.sql` | Single animal with lineage, group, weight, health and money totals | `:tenant_id`, `:animal_id` |
| `animal_timeline.sql` | Unified per-animal event history | `:tenant_id`, `:animal_id` |
| `herd_by_group.sql` | Herd composition and capacity per group | `:tenant_id` |
| `health_due.sql` | Health work queue within `:days` | `:tenant_id`, `:days` |
| `medication_withdrawal.sql` | Animals still in meat/milk withdrawal | `:tenant_id` |
| `births_recent.sql` | Births and offspring outcomes in a period | `:tenant_id`, `:from`, `:to` |
| `inventory_movements.sql` | Signed stock ledger | `:tenant_id`, `:inventory_item_id`, `:from`, `:to` |
| `open_purchase_orders.sql` | Supply pipeline and overdue deliveries | `:tenant_id` |
| `invoice_aging.sql` | Receivables aging buckets as of a date | `:tenant_id`, `:as_of` |
| `payments_ledger.sql` | Payments received in a period | `:tenant_id`, `:from`, `:to` |
| `budget_variance.sql` | Planned vs actual expense by budget | `:tenant_id` |
| `attendance_summary.sql` | Per-worker attendance and hours | `:tenant_id`, `:from`, `:to` |
| `attendance_daily.sql` | Daily attendance sheet and acknowledgement state | `:tenant_id`, `:work_date` |
| `task_board.sql` | Task assignments, overdue and priority order | `:tenant_id`, `:worker_id`, `:status` |
| `notifications_inbox.sql` | Notification inbox / delivery queue | `:tenant_id`, `:user_id`, `:status` |
| `audit_trail.sql` | Audit log for owner/manager views | `:tenant_id`, `:from`, `:to`, `:entity_type`, `:actor_user_id` |

## Optional params

Optional UUID/text filters accept `NULL`. When calling from `psql`, pass `NULL`
for them, or bind a null parameter from the driver. Do not omit the parameter
name.

## Relationship to reports

- `reports/` holds fixed operational/PDF reports.
- `queries/` holds the read models each product feature needs.

Both read from the operational schema plus the star-schema views; neither writes
back. `animal_timeline.sql` and `animal_profile.sql` reference the append-only
history tables directly because the timeline is per-animal, not analytical.
