# livestock-analytics

Analytical/warehouse layer that powers the downloadable PDF reports, herd/health
summaries, historical trends and cost forecasting. Reads from the operational
schema (read-only) — never writes back to it.

## Approach

- **Star schema**: `models/` holds dimensions and facts as views/materialised
  views. Start as views; promote to materialised views once volume grows.
- **Reports**: `reports/` holds the exact SQL each report/PDF runs. The backend
  calls these and renders to PDF — the numbers live here, not in application code.
- Optional next step: wrap `models/` in **dbt** for lineage/tests (a
  `dbt_project.yml` stub is included).

## Layout

```
models/     dim_*.sql, fct_*.sql      (star schema)
reports/    herd_summary.sql, financial_summary.sql, health_status.sql,
            low_stock.sql, cost_trends.sql, mortality_summary.sql,
            reorder_recommendations.sql, vaccination_due.sql,
            breeding_due.sql   (report queries)
```

## Notes

- Every report is **tenant-scoped**; pass a `:tenant_id` (and `:from`/`:to` for
  timeframes) as query parameters.
- Ivy prefers direct numeric readouts over charts — these queries return plain
  row/column results suitable for PDF tables.
