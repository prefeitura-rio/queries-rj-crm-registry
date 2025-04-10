{{
    config(
        alias="atendimento",
        schema="", # TODO: Add schema
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        partition_by={
            "field": "data_envio",
            "data_type": "date",
            "range": {"start": "2019-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

WITH 
dados_base AS (
    SELECT 
        templateId,
        DATE(sendDate AT TIME ZONE 'UTC') AS data_envio,
        DATE(deliveryDate AT TIME ZONE 'UTC') AS data_entrega,
        DATE(readDate AT TIME ZONE 'UTC') AS data_leitura,
        
        CASE WHEN sendDate IS NOT NULL THEN 1 ELSE 0 END AS foi_enviado,
        CASE WHEN deliveryDate IS NOT NULL THEN 1 ELSE 0 END AS foi_entregue,
        CASE WHEN readDate IS NOT NULL THEN 1 ELSE 0 END AS foi_lido,
        
        CASE WHEN (sendDate IS NOT NULL AND deliveryDate IS NOT NULL) 
             THEN EXTRACT(EPOCH FROM (deliveryDate - sendDate)) 
             ELSE NULL 
        END AS tempo_entrega,
        
        CASE WHEN (deliveryDate IS NOT NULL AND readDate IS NOT NULL) 
             THEN EXTRACT(EPOCH FROM (readDate - deliveryDate)) 
             ELSE NULL 
        END AS tempo_leitura
    FROM {{ source('disparos', 'fluxo_atendimento') }}
    WHERE sendDate IS NOT NULL
),

metricas_por_dia AS (
    SELECT 
        data_envio,
        templateId,
        SUM(foi_enviado) AS total_enviados,
        SUM(foi_entregue) AS total_entregues,
        SUM(foi_lido) AS total_lidos,

        CASE 
            WHEN SUM(foi_enviado) = 0 THEN 0
            ELSE ROUND((SUM(foi_entregue)::NUMERIC / SUM(foi_enviado)::NUMERIC) * 100, 2)
        END AS taxa_entrega_percentual,

        CASE 
            WHEN SUM(foi_entregue) = 0 THEN 0
            ELSE ROUND((SUM(foi_lido)::NUMERIC / SUM(foi_entregue)::NUMERIC) * 100, 2)
        END AS taxa_leitura_percentual,

        ROUND(AVG(tempo_entrega), 2) AS tempo_medio_entrega_segundos,
        ROUND(AVG(tempo_leitura), 2) AS tempo_medio_leitura_segundos
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
    taxa_entrega_percentual,
    COALESCE(tempo_medio_entrega_segundos, 0) AS tempo_medio_entrega_segundos,
    COALESCE(tempo_medio_leitura_segundos, 0) AS tempo_medio_leitura_segundos,
    taxa_leitura_percentual
FROM metricas_por_dia
ORDER BY data_envio DESC, templateId