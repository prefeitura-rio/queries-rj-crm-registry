{{
    config(
        materialized='test',
        schema='testes',
        alias='diferenca_schema',
        tags=['data_test']
    )
}}

WITH dev_schema AS (
  SELECT 
    table_name,
    STRING_AGG(CONCAT(column_name, '|', data_type), '|') AS schema_definition
  FROM `{{ target.project }}.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name LIKE '{{ var("dev_prefix") }}%'
  GROUP BY table_name
),

prod_schema AS (
  SELECT 
    REPLACE(table_name, '{{ var("dev_prefix") }}', '') AS table_name,
    STRING_AGG(CONCAT(column_name, '|', data_type), '|') AS schema_definition
  FROM `{{ var("prod_project") }}.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name NOT LIKE '%{{ var("dev_prefix") }}%'
  GROUP BY table_name
)

SELECT 
  d.table_name AS dev_table,
  p.table_name AS prod_table,
  d.schema_definition AS dev_schema,
  p.schema_definition AS prod_schema,
  CASE 
    WHEN d.schema_definition = p.schema_definition THEN '✅ VALID' 
    ELSE '❌ INVALID' 
  END AS validation_status
FROM dev_schema d
JOIN prod_schema p ON REPLACE(d.table_name, '{{ var("dev_prefix") }}', '') = p.table_name
WHERE d.schema_definition != p.schema_definition