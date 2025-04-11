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
        replyId,
        account,
        DATE(sendDate AT TIME ZONE 'UTC') AS data_envio
    FROM {{ source('disparos', 'fluxo_atendimento') }}
)
SELECT
    data_envio,
    templateId,
    COUNT(*) as total_mensagens,
    ROUND(AVG(TIMESTAMP_DIFF(deliveryDate, sendDate, SECOND)), 2) as tempo_medio_entrega,
    ROUND(AVG(TIMESTAMP_DIFF(readDate, deliveryDate, SECOND)), 2) as tempo_medio_leitura,
    ROUND(AVG(TIMESTAMP_DIFF(replyDate, readDate, SECOND)), 2) as tempo_medio_resposta,
    (ROUND(AVG(TIMESTAMP_DIFF(replyDate, readDate, SECOND)), 2) > 3600) as tempo_resistencia,
    id_ura,
    ura_name
FROM tempo_base tb
LEFT JOIN {{ source('disparos', 'fluxos_ura') }} fu
    ON replyId = af.id
GROUP BY data_envio, templateId, id_ura