{{
    config(
        alias="atendimento",
        schema="disparos",
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        partition_by={
            "field": "data_envio",
            "data_type": "date",
            "range": {"start": "2019-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

WITH
fluxo_data AS (
    SELECT
        templateId,
        sendDate,
        deliveryDate,
        readDate,
        replyDate,
        replyId, 
        account
    FROM {{ source('disparos', 'fluxo_atendimento') }}
),

attendance_data AS (
    SELECT
        id,
        protocol,
        account
    FROM {{ source('disparos', 'atendimento_iniciado') }}
),

ura_data AS (
    SELECT
        protocol, 
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S%z', end_date) as end_date,
    FROM {{ source('disparos', 'fluxos_ura') }}
),

dados_base AS (
    SELECT
        fd.templateId,
        fd.sendDate,
        fd.deliveryDate,
        fd.readDate,
        fd.replyDate,
        fd.replyId,
        fd.account,
        DATE(fd.sendDate, 'UTC') AS data_envio,
        DATE(fd.deliveryDate, 'UTC') AS data_entrega,
        DATE(fd.readDate, 'UTC') AS data_leitura,
        DATE(fd.replyDate, 'UTC') AS data_resposta,

        CASE WHEN fd.sendDate IS NOT NULL THEN 1 ELSE 0 END AS foi_enviado,
        CASE WHEN fd.deliveryDate IS NOT NULL THEN 1 ELSE 0 END AS foi_entregue,
        CASE WHEN fd.readDate IS NOT NULL THEN 1 ELSE 0 END AS foi_lido,
        CASE WHEN fd.replyDate IS NOT NULL THEN 1 ELSE 0 END AS foi_respondido,

        TIMESTAMP_DIFF(fd.deliveryDate, fd.sendDate, SECOND) AS tempo_entrega,
        TIMESTAMP_DIFF(fd.readDate, fd.deliveryDate, SECOND) AS tempo_leitura,
        TIMESTAMP_DIFF(fd.replyDate, fd.deliveryDate, SECOND) AS tempo_resposta,

        CASE
            WHEN ud.end_date IS NOT NULL AND fd.sendDate IS NOT NULL AND ud.end_date > fd.sendDate
            THEN TIMESTAMP_DIFF(ud.end_date, fd.sendDate, SECOND)
            ELSE NULL
        END AS tempo_total_sessao_hsm_ura

    FROM fluxo_data AS fd
    LEFT JOIN attendance_data AS ad
        ON fd.replyId = ad.id AND fd.account = ad.account
    LEFT JOIN ura_data AS ud
        ON ad.protocol = ud.protocol
),

metricas_por_dia AS (
    SELECT
        data_envio,
        templateId,
        SUM(foi_enviado) AS total_enviados,
        SUM(foi_entregue) AS total_entregues,
        SUM(foi_lido) AS total_lidos,
        SUM(foi_respondido) AS total_respondidos,

        CASE
            WHEN SUM(foi_enviado) = 0 THEN 0
            ELSE ROUND((CAST(SUM(foi_entregue) AS NUMERIC) / CAST(SUM(foi_enviado) AS NUMERIC)) * 100, 2)
        END AS taxa_entrega_percentual,

        CASE
            WHEN SUM(foi_entregue) = 0 THEN 0
            ELSE ROUND((CAST(SUM(foi_lido) AS NUMERIC) / CAST(SUM(foi_entregue) AS NUMERIC)) * 100, 2)
        END AS taxa_leitura_percentual,

        CASE
            WHEN SUM(foi_entregue) = 0 THEN 0
            ELSE ROUND((CAST(SUM(foi_respondido) AS NUMERIC) / CAST(SUM(foi_entregue) AS NUMERIC)) * 100, 2)
        END AS taxa_resposta_percentual,

        ROUND(AVG(tempo_entrega), 2) AS tempo_medio_entrega_segundos,
        ROUND(AVG(tempo_leitura), 2) AS tempo_medio_leitura_segundos,
        ROUND(AVG(tempo_resposta), 2) AS tempo_medio_resposta_segundos,
        ROUND(AVG(tempo_total_sessao_hsm_ura), 2) AS tempo_medio_total_sessao_hsm_ura_segundos

    FROM dados_base
    WHERE data_envio IS NOT NULL
    GROUP BY data_envio, templateId
)

SELECT
    data_envio AS data,
    templateId,
    total_enviados,
    total_entregues,
    total_lidos,
    total_respondidos,
    taxa_entrega_percentual,
    taxa_leitura_percentual,
    taxa_resposta_percentual,
    COALESCE(tempo_medio_entrega_segundos, 0) AS tempo_medio_entrega_segundos,
    COALESCE(tempo_medio_leitura_segundos, 0) AS tempo_medio_leitura_segundos,
    COALESCE(tempo_medio_resposta_segundos, 0) AS tempo_medio_resposta_segundos,
    COALESCE(tempo_medio_total_sessao_hsm_ura_segundos, 0) AS tempo_medio_segundos

FROM metricas_por_dia
ORDER BY data_envio DESC, templateId