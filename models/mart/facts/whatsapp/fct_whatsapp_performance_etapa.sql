{{
    config(
        materialized='table',
        schema='disparos',
        partition_by={
            "field": "data_sessao",
            "data_type": "date",
            "range": {"start": "2023-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

WITH mensagens_com_seq AS (
  SELECT
    id_sessao,
    DATE(msg.data) AS data_sessao,
    msg.data AS timestamp_mensagem,
    msg.fonte AS origem_mensagem,
    msg.passo_ura.id AS id_passo_ura,
    msg.passo_ura.nome AS nome_passo_ura,
    -- Adiciona um número de sequência para ordenar mensagens dentro de cada sessão
    ROW_NUMBER() OVER (PARTITION BY id_sessao ORDER BY msg.data) AS seq_mensagem
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }},
  UNNEST(mensagens) AS msg
),

mensagens_ura_seguidas_por_cliente AS (
    SELECT
        id_sessao,
        data_sessao,
        timestamp_mensagem AS timestamp_ura,
        id_passo_ura,
        nome_passo_ura,
        -- Encontra o timestamp da próxima mensagem na sessão
        LEAD(timestamp_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS timestamp_proxima_msg,
        -- Encontra a origem da próxima mensagem na sessão
        LEAD(origem_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS origem_proxima_msg
    FROM mensagens_com_seq
    WHERE origem_mensagem = 'URA' -- Seleciona apenas mensagens da URA
)

-- Agrega os resultados para calcular as métricas por etapa
SELECT
    data_sessao,
    id_passo_ura,
    nome_passo_ura,
    COUNT(id_sessao) AS hsm_respondidos_por_etapa, -- Métrica 9: Conta mensagens da URA seguidas por cliente
    ROUND(AVG(TIMESTAMP_DIFF(timestamp_proxima_msg, timestamp_ura, SECOND)), 2) AS tempo_medio_ura_para_resposta_segundos -- Tempo entre URA enviada e Cliente Responde
FROM mensagens_ura_seguidas_por_cliente
WHERE origem_proxima_msg = 'CUSTOMER' -- Considera apenas os casos em que a próxima mensagem é do cliente
GROUP BY data_sessao, id_passo_ura, nome_passo_ura
ORDER BY data_sessao DESC, id_passo_ura, nome_passo_ura