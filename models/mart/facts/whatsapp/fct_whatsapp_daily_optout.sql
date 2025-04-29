{{
    config(
        materialized='table',
        schema='metricas',
        partition_by={
            "field": "data_sessao",
            "data_type": "date",
            "range": {"start": "2023-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

WITH RankedMessages AS (
  SELECT
    id_sessao,
    msg.data as timestamp_mensagem,
    msg.fonte as origem_mensagem,
    msg.texto as texto_mensagem,
    ROW_NUMBER() OVER (PARTITION BY id_sessao ORDER BY msg.data DESC) as rn -- Classifica as mensagens por sessão, mais recente primeiro
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }}, -- Usa a macro source do dbt
  UNNEST(mensagens) as msg
),
LastCustomerMessage AS (
  SELECT
    id_sessao,
    texto_mensagem as last_customer_text
  FROM RankedMessages
  WHERE origem_mensagem = 'CUSTOMER'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id_sessao ORDER BY timestamp_mensagem DESC) = 1 -- Seleciona apenas a última mensagem do cliente por sessão
),
SessionOptOutStatus AS (
  SELECT
    DATE(f.inicio_datahora) as data_sessao,
    f.id_sessao,
    JSON_VALUE(f.tabulacao, '$.id') as tabulation_id,
    lcm.last_customer_text
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }} f -- Usa a macro source do dbt
  LEFT JOIN LastCustomerMessage lcm ON f.id_sessao = lcm.id_sessao -- Junta com a última mensagem do cliente
),
DailyOptOut AS (
  SELECT
    data_sessao,
    COUNT(DISTINCT id_sessao) as total_sessoes,
    COUNT(DISTINCT CASE WHEN tabulation_id = '35' AND LOWER(last_customer_text) = 'sair' THEN id_sessao END) as opt_out_sessoes_sair_last_message
  FROM SessionOptOutStatus
  GROUP BY data_sessao
)
SELECT
  data_sessao,
  total_sessoes,
  opt_out_sessoes_sair_last_message,
  SAFE_DIVIDE(opt_out_sessoes_sair_last_message, total_sessoes) * 100 as taxa_opt_out_sair_last_message_percentual
FROM DailyOptOut
ORDER BY data_sessao DESC;