{{
    config(
        alias="atendimento_status_finalizacao",
        schema="", # TODO: Add schema
        materialized='table'
         partition_by={
             "field": "data_inicio",
             "data_type": "date",
         },
    )
}}

WITH atendimento_finalizado_data AS (
    SELECT
        id,
        account,
        tabulation
      
    FROM {{ source('atendimento', 'atendimento_finalizado') }}
),

atendimento_iniciado_data AS (
    SELECT
        id,
        account,
        protocol,
        channel,
        beginDate AS data_inicio
    FROM {{ source('atendimento', 'atendimento_iniciado') }}
)

SELECT
    ai.id AS atendimento_id,
    ai.account,
    ai.protocol,
    ai.channel,
    ai.data_inicio,
    af.tabulation,
    CASE
        WHEN af.tabulation IS NULL THEN 'Em Andamento'
        WHEN af.tabulation = 37 THEN 'Timeout'
        WHEN af.tabulation = 35 THEN 'Opt-out'
        ELSE 'Outro(' || CAST(af.tabulation AS STRING) || ')'
    END AS status_finalizacao
FROM atendimento_iniciado_data AS ai
LEFT JOIN atendimento_finalizado_data AS af
    ON ai.id = af.id
    AND ai.account = af.account 