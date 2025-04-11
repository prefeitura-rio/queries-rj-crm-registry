{{
    config(
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        schema=''
    )
}}

WITH tempo_base AS (
    SELECT
        templateId,
        flow_step as etapa_fluxo,
        sendDate,
        deliveryDate,
        readDate,
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
    ROUND(AVG(EXTRACT(EPOCH FROM (deliveryDate - sendDate))), 2) as tempo_medio_entrega,
    ROUND(AVG(EXTRACT(EPOCH FROM (readDate - deliveryDate))), 2) as tempo_medio_leitura,
    ROUND(AVG(EXTRACT(EPOCH FROM (replyDate - readDate))), 2) as tempo_medio_resposta,
    COUNT(replyDate) as respostas_por_etapa,
    (ROUND(AVG(EXTRACT(EPOCH FROM (replyDate - readDate))), 2) > 3600) as tempo_resistencia
FROM tempo_base
GROUP BY data_envio, templateId, etapa_fluxo 