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



-- WITH
-- fluxo_data AS (
--     SELECT
--         templateId,
--         sendDate,
--         deliveryDate,
--         readDate,
--         replyDate,
--         replyId, 
--         account
--     FROM `rj-crm-registry.disparos.fluxo_atendimento`
-- ),

-- attendance_data AS (
--     SELECT
--         id,
--         protocol,
--         account
--     FROM `rj-crm-registry.disparos.atendimento_iniciado`
-- ),

-- ura_data AS (
--     SELECT
--         protocol, 
--         end_date,
--         id_reply
--     FROM `rj-crm-registry.disparos_staging.fluxos_ura`
-- ),

-- dados_base AS (
--     SELECT
--         fd.templateId,
--         fd.sendDate,
--         fd.deliveryDate,
--         fd.readDate,
--         fd.replyDate,
--         fd.replyId,
--         fd.account,
--         DATE(fd.sendDate) AS data_envio,
--         DATE(fd.deliveryDate) AS data_entrega,
--         DATE(fd.readDate) AS data_leitura,
--         DATE(fd.replyDate) AS data_resposta,

--         CASE WHEN fd.sendDate IS NOT NULL THEN 1 ELSE 0 END AS foi_enviado,
--         CASE WHEN fd.deliveryDate IS NOT NULL THEN 1 ELSE 0 END AS foi_entregue,
--         CASE WHEN fd.readDate IS NOT NULL THEN 1 ELSE 0 END AS foi_lido,
--         CASE WHEN fd.replyDate IS NOT NULL THEN 1 ELSE 0 END AS foi_respondido,

--         TIMESTAMP_DIFF(fd.deliveryDate, fd.sendDate, SECOND) AS tempo_entrega,
--         TIMESTAMP_DIFF(fd.readDate, fd.deliveryDate, SECOND) AS tempo_leitura,
--         TIMESTAMP_DIFF(fd.replyDate, fd.deliveryDate, SECOND) AS tempo_resposta,

--         CASE
--             WHEN ud.end_date IS NOT NULL AND fd.sendDate IS NOT NULL AND TIMESTAMP(ud.end_date) > fd.sendDate
--             THEN TIMESTAMP_DIFF(TIMESTAMP(ud.end_date), fd.sendDate, SECOND)
--             ELSE NULL
--         END AS tempo_total_sessao_hsm_ura

--     FROM fluxo_data AS fd
--     LEFT JOIN attendance_data AS ad
--         ON fd.replyId = ad.id AND fd.account = ad.account
--     LEFT JOIN ura_data AS ud
--         ON fd.replyId = ud.id_reply
-- ),

-- metricas_por_dia AS (
--     SELECT
--         data_envio,
--         templateId,
--         SUM(foi_enviado) AS total_enviados,
--         SUM(foi_entregue) AS total_entregues,
--         SUM(foi_lido) AS total_lidos,
--         SUM(foi_respondido) AS total_respondidos,

--         CASE
--             WHEN SUM(foi_enviado) = 0 THEN 0
--             ELSE ROUND((SUM(CAST(foi_entregue AS NUMERIC)) / SUM(CAST(foi_enviado AS NUMERIC))) * 100, 2)
--         END AS taxa_entrega_percentual,

--         CASE
--             WHEN SUM(foi_entregue) = 0 THEN 0
--             ELSE ROUND((SUM(CAST(foi_lido AS NUMERIC)) / SUM(CAST(foi_entregue AS NUMERIC))) * 100, 2)
--         END AS taxa_leitura_percentual,

--         CASE
--             WHEN SUM(foi_entregue) = 0 THEN 0
--             ELSE ROUND((SUM(CAST(foi_respondido AS NUMERIC)) / SUM(CAST(foi_entregue AS NUMERIC))) * 100, 2)
--         END AS taxa_resposta_percentual,

--         ROUND(AVG(tempo_entrega), 2) AS tempo_medio_entrega_segundos,
--      0   ROUND(AVG(tempo_leitura), 2) AS tempo_medio_leitura_segundos,
--         ROUND(AVG(tempo_resposta), 2) AS tempo_medio_resposta_segundos,
--         ROUND(AVG(tempo_total_sessao_hsm_ura), 2) AS tempo_medio_total_sessao_hsm_ura_segundos

--     FROM dados_base
--     WHERE data_envio IS NOT NULL
--     GROUP BY data_envio, templateId
-- )

-- SELECT
--     data_envio AS data,
--     templateId,
--     total_enviados,
--     total_entregues,
--     total_lidos,
--     total_respondidos,
--     taxa_entrega_percentual,
--     taxa_leitura_percentual,
--     taxa_resposta_percentual,
--     COALESCE(tempo_medio_entrega_segundos, 0) AS tempo_medio_entrega_segundos,
--     COALESCE(tempo_medio_leitura_segundos, 0) AS tempo_medio_leitura_segundos,
--     COALESCE(tempo_medio_resposta_segundos, 0) AS tempo_medio_resposta_segundos,
--     COALESCE(tempo_medio_total_sessao_hsm_ura_segundos, 0) AS tempo_medio_segundos

-- FROM metricas_por_dia
-- ORDER BY data_envio DESC, templateId




INSERT INTO `rj-crm-registry.disparos.fluxo_atendimento_fake` (event, account, templateId, triggerId, targetId, targetExternalId, flatTarget, status, createDate, sendDate, deliveryDate, readDate, failedDate, faultDescription, replyDate, replyId) VALUES
('EVT002', 'ACC002', 'TMP002', 'TRG002', 'TGT002', 'EXT002', 'FLAT002', 'DELIVERED', '2023-01-02 10:00:00', '2023-01-02 10:05:00', '2023-01-02 10:10:00', '2023-01-02 10:15:00', NULL, NULL, '2023-01-02 10:20:00', 'REP002'),
('EVT002', 'ACC002', 'TMP002', 'TRG002', 'TGT002', 'EXT002', 'FLAT002', 'READ', '2023-01-02 11:00:00', '2023-01-02 11:05:00', '2023-01-02 11:10:00', '2023-01-02 11:15:00', NULL, NULL, '2023-01-02 11:25:00', 'REP002'),
('EVT006', 'ACC006', 'TMP006', 'TRG006', 'TGT006', 'EXT006', 'FLAT006', 'FAILED', '2023-01-06 12:00:00', '2023-01-06 12:05:00', NULL, NULL, '2023-01-06 12:10:00', 'Timeout', NULL, NULL),
('EVT006', 'ACC006', 'TMP006', 'TRG006', 'TGT006', 'EXT006', 'FLAT006', 'DELIVERED', '2023-01-04 13:00:00', '2023-01-04 13:05:00', '2023-01-04 13:10:00', NULL, NULL, NULL, NULL, NULL),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT005', 'FLAT005', 'SENT', '2023-01-05 14:00:00', '2023-01-05 14:05:00', NULL, NULL, NULL, NULL, NULL, NULL),
('EVT006', 'ACC006', 'TMP006', 'TRG006', 'TGT006', 'EXT006', 'FLAT006', 'DELIVERED', '2023-01-06 15:00:00', '2023-01-06 15:05:00', '2023-01-06 15:10:00', '2023-01-06 15:15:00', NULL, NULL, '2023-01-06 15:20:00', 'REP006'),
('EVT007', 'ACC007', 'TMP007', 'TRG007', 'TGT007', 'EXT007', 'FLAT007', 'READ', '2023-01-07 16:00:00', '2023-01-07 16:05:00', '2023-01-07 16:10:00', '2023-01-07 16:15:00', NULL, NULL, '2023-01-07 16:25:00', 'REP007'),
('EVT008', 'ACC008', 'TMP008', 'TRG008', 'TGT008', 'EXT008', 'FLAT008', 'FAILED', '2023-01-08 17:00:00', '2023-01-08 17:05:00', NULL, NULL, '2023-01-08 17:10:00', 'Network Error', NULL, NULL),
('EVT009', 'ACC009', 'TMP009', 'TRG009', 'TGT009', 'EXT009', 'FLAT009', 'DELIVERED', '2023-01-09 18:00:00', '2023-01-09 18:05:00', '2023-01-09 18:10:00', NULL, NULL, NULL, NULL, NULL),
('EVT010', 'ACC010', 'TMP009', 'TRG009', 'TGT009', 'EXT009', 'FLAT009', 'SENT', '2023-01-09 19:00:00', '2023-01-09 19:05:00', NULL, NULL, NULL, NULL, NULL, NULL),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT011', 'FLAT011', 'DELIVERED', '2023-01-05 20:00:00', '2023-01-05 20:05:00', '2023-01-05 20:09:00', '2023-01-05 20:15:00', NULL, NULL, '2023-01-05 20:20:00', 'REP011'),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT005', 'FLAT005', 'READ', '2023-01-05 21:00:00', '2023-01-05 21:05:00', '2023-01-05 21:10:00', '2023-01-05 21:15:00', NULL, NULL, '2023-01-05 21:25:00', 'REP012'),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT005', 'FLAT005', 'FAILED', '2023-01-05 22:00:00', '2023-01-05 22:05:00', NULL, NULL, '2023-01-05 22:10:00', 'Server Down', NULL, NULL),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT005', 'FLAT005', 'DELIVERED', '2023-01-05 23:00:00', '2023-01-05 23:05:00', '2023-01-05 23:10:00', NULL, NULL, NULL, NULL, NULL),
('EVT005', 'ACC005', 'TMP005', 'TRG005', 'TGT005', 'EXT005', 'FLAT005', 'SENT', '2023-01-05 00:00:00', '2023-01-05 00:05:00', NULL, NULL, NULL, NULL, NULL, NULL),
('EVT006', 'ACC006', 'TMP006', 'TRG006', 'TGT006', 'EXT006', 'FLAT006', 'DELIVERED', '2023-01-06 01:00:00', '2023-01-06 01:05:00', '2023-01-06 01:10:00', '2023-01-06 01:15:00', NULL, NULL, '2023-01-06 01:20:00', 'REP016'),
('EVT007', 'ACC007', 'TMP007', 'TRG007', 'TGT007', 'EXT007', 'FLAT007', 'READ', '2023-01-11 02:00:00', '2023-01-11 02:05:00', '2023-01-11 02:10:00', '2023-01-11 02:15:00', NULL, NULL, '2023-01-11 02:25:00', 'REP007'),
('EVT008', 'ACC008', 'TMP008', 'TRG008', 'TGT008', 'EXT008', 'FLAT008', 'FAILED', '2023-01-10 06:00:00', '2023-01-10 06:05:00', NULL, NULL, '2023-01-10 06:10:00', 'Invalid Number', NULL, NULL),
('EVT09', 'ACC09', 'TMP009', 'TRG09', 'TGT09', 'EXT09', 'FLAT09', 'DELIVERED', '2023-01-10 04:00:00', '2023-01-10 04:05:00', '2023-01-10 04:10:00', NULL, NULL, NULL, NULL, NULL),
('EVT002', 'ACC002', 'TMP002', 'TRG002', 'TGT002', 'EXT002', 'FLAT002', 'SENT', '2023-01-10 05:00:00', '2023-01-10 05:05:00', NULL, NULL, NULL, NULL, NULL, NULL);