{{
    config(
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        schema='disparos'
    )
}}

WITH fluxo_base AS (
    SELECT
        templateId,
        flow_step as etapa_fluxo,
        tabulation_id,
        sendDate,
        replyDate,
        account,
        DATE(sendDate AT TIME ZONE 'UTC') AS data_envio
    FROM {{ source('disparos', 'fluxo_atendimento') }}
)

SELECT
    data_envio,
    templateId,
    etapa_fluxo,
    COUNT(*) as total_mensagens,
    COUNT(CASE WHEN tabulation_id = 35 THEN 1 END) as finalizado_cliente,
    COUNT(CASE WHEN tabulation_id = 37 THEN 1 END) as finalizado_janela,
    COUNT(CASE WHEN tabulation_id IN (35, 37) THEN 1 END) as total_finalizados,
    AVG(EXTRACT(EPOCH FROM (replyDate - sendDate))) as tempo_medio_resposta_segundos
FROM fluxo_base
GROUP BY data_envio, templateId, etapa_fluxo 