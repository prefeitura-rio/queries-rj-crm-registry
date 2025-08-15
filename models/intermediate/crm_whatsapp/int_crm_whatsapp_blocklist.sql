{{ config(
    materialized = 'table',
    alias="blocklist",
    schema="brutos_wetalkie",
    tags=["hourly"],
    partition_by={
        "field": "data_particao",
        "data_type": "date"
    }
) }}

-- {#
--   pre_hook = """
--     CREATE OR REPLACE EXTERNAL TABLE `{{ target.project }}.brutos_wetalkie_staging.blocklist`
--     OPTIONS (
--       format = 'GOOGLE_SHEETS',
--       uris = ['https://docs.google.com/spreadsheets/d/1ggpBt5AWKrg-AvAsTf07T1PPjIaquupHDxggobKOYU8/edit?usp=sharing'],
--       sheet_range = 'blocklist!A:Z',
--       skip_leading_rows = 1
--     )
--   """
-- #}

-- create or replace table `rj-crm-registry-dev.brutos_wetalkie.blocklist` as 
SELECT
  CAST(phone AS STRING) as contato_telefone,
  profile_name as contato_nome,
  date_time as data_bloqueio,
  reason as razao_bloqueio,
  DATE(date_time) as data_particao
FROM `rj-crm-registry.brutos_wetalkie_staging.blocklist`
-- FROM `{{ target.project }}.brutos_wetalkie_staging.blocklist`