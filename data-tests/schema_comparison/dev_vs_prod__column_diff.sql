{{
    config(
        materialized='test',
        tags=['data_test']
    )
}}

{% set datasets = var('datasets_to_check', ['crm_whatsapp']) %}

WITH dev_columns AS (
  {% for dataset in datasets %}
    SELECT
      '{{ dataset }}' AS dataset,
      table_name,
      column_name,
      data_type
    FROM `rj-crm-registry-dev.{{ var("DBT_USER") }}__{{ dataset }}.INFORMATION_SCHEMA.COLUMNS`
    -- WHERE table_name LIKE '{{ var("DBT_USER") }}__%'
    --   AND table_schema = '{{ var("DBT_USER") }}__{{ dataset }}'
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
),

prod_columns AS (
  {% for dataset in datasets %}
    SELECT
      '{{ dataset }}' AS dataset,
      table_name,
      column_name,
      data_type
    FROM `rj-crm-registry.{{ dataset }}.INFORMATION_SCHEMA.COLUMNS`
    -- WHERE table_schema = '{{ dataset }}'
    {% if not loop.last %}UNION ALL{% endif %}
  {% endfor %}
),

dev_clean AS (
  SELECT
    dataset,
    REPLACE(table_name, '{{ var("DBT_USER") }}__', '') AS base_table,
    column_name,
    data_type
  FROM dev_columns
),

prod_clean AS (
  SELECT
    dataset,
    table_name AS base_table,
    column_name,
    data_type
  FROM prod_columns
)

SELECT
  COALESCE(dev.dataset, prod.dataset) AS dataset,
  COALESCE(dev.base_table, prod.base_table) AS base_table,
  COALESCE(dev.column_name, prod.column_name) AS column_name,
  dev.data_type AS dev_data_type,
  prod.data_type AS prod_data_type
FROM dev_clean dev
FULL OUTER JOIN prod_clean prod
  ON dev.dataset = prod.dataset
  AND dev.base_table = prod.base_table
  AND dev.column_name = prod.column_name
WHERE dev.data_type IS DISTINCT FROM prod.data_type
order by dataset, base_table, column_name
