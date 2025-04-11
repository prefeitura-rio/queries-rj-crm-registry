{{
    config(
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        schema='metricas'
    )
}}

WITH fluxo_base AS (
    SELECT
        fa.templateId,
        fa.sendDate,
        fa.replyDate,
        fa.account,
        DATE(fa.sendDate, 'UTC') AS data_envio,
        fu.id_ura,
        SAFE_CAST(JSON_VALUE(fu.json_data, '$.tabulation.id') AS INT64) as tabulation_id,
        JSON_VALUE(fu.json_data, '$.tabulation.name') as tabulation_name
    FROM {{ source('disparos', 'fluxo_atendimento') }} fa
    LEFT JOIN {{ source('disparos_staging', 'fluxos_ura') }} fu
        ON fa.replyId = fu.id_reply
)

SELECT
    data_envio,
    templateId,
    id_ura,
    tabulation_name,
    COUNT(*) as total_mensagens,
    COUNT(CASE WHEN tabulation_id = 35 THEN 1 END) as finalizado_cliente,
    COUNT(CASE WHEN tabulation_id = 37 THEN 1 END) as finalizado_janela,
    COUNT(CASE WHEN tabulation_id IN (35, 37) THEN 1 END) as total_finalizados,
    AVG(TIMESTAMP_DIFF(replyDate, sendDate, SECOND)) as tempo_medio_resposta_segundos
FROM fluxo_base
GROUP BY data_envio, templateId, id_ura, tabulation_name 