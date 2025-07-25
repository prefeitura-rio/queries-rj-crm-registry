{{
    config(
        materialized='test',
        tags=['data_test']
    )
}}

{% set datasets = var('datasets_to_check', ['crm_whatsapp']) %}

WITH dev_tables AS (
  {% for dataset in datasets %}
    SELECT
      '{{ dataset }}' AS dataset,
      REPLACE(table_id, '{{ var("DBT_USER") }}__', '') AS base_table,
      row_count AS dev_rows
    FROM `rj-crm-registry-dev.{{ var("DBT_USER") }}__{{ dataset }}.__TABLES__`
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
),

prod_tables AS (
  {% for dataset in datasets %}
    SELECT
      '{{ dataset }}' AS dataset,
      table_id AS base_table,
      row_count AS prod_rows
    FROM `rj-crm-registry.{{ dataset }}.__TABLES__`
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
)

SELECT
  dev.dataset,
  dev.base_table AS table_id,
  dev.dev_rows,
  prod.prod_rows,
  dev.dev_rows - prod.prod_rows AS row_diff
FROM dev_tables dev
JOIN prod_tables prod 
  ON dev.dataset = prod.dataset
  AND dev.base_table = prod.base_table
WHERE dev.dev_rows != prod.prod_rows
ORDER BY dev.dataset, dev.base_table


-- {% set critical_tables = ['users', 'transactions', 'products'] %}

-- SELECT
--   REPLACE(dev.table_id, '{{ var("dev_prefix") }}', '') AS table_name,
--   dev.row_count AS dev_rows,
--   prod.row_count AS prod_rows,
--   dev.row_count - prod.row_count AS diff,
--   CASE
--     WHEN REPLACE(dev.table_id, '{{ var("dev_prefix") }}', '') IN ({{ "'" + critical_tables|join("','") + "'" }})
--       AND ABS(dev.row_count - prod.row_count) > 1000 
--     THEN '❌ CRITICAL_DIFF'
--     WHEN dev.row_count != prod.row_count THEN '⚠️ WARNING'
--     ELSE '✅ VALID'
--   END AS status
-- FROM `{{ target.project }}.__TABLES__` dev
-- JOIN `{{ var("prod_project") }}.__TABLES__` prod
--   ON REPLACE(dev.table_id, '{{ var("dev_prefix") }}', '') = prod.table_id
-- WHERE dev.row_count != prod.row_count