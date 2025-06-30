{{ config(alias="performance_etapa_ura", schema="crm_whatsapp", materialized="view") }}

-- Calcula o desempenho das etapas da URA no WhatsApp, considerando as quantidades e tempos de resposta dos clientes
-- Remover mensagens duplicadas dentro do struct mensagem antes de usar row_number
WITH source as (
        select *
        from {{ ref("raw_wetalkie_fluxos_ura") }}
        where inicio_datahora >= '2025-04-18 12:00:00'
    ),
    
mensagens AS (
  SELECT
    DISTINCT
    id_sessao,
    DATE(msg.data) AS data_sessao,
    msg.data AS timestamp_mensagem,
    msg.fonte AS origem_mensagem,
    ura.id AS id_ura,
    ura.nome AS ura_nome,
    msg.passo_ura.id AS id_passo_ura,
    msg.passo_ura.nome AS nome_passo_ura,
    msg.texto AS mensagem_texto,
  FROM source,
  UNNEST(mensagens) AS msg
),

mensagens_com_seq AS (
    SELECT *,
    -- Adiciona um número de sequência para ordenar mensagens dentro de cada sessão
    ROW_NUMBER() OVER (PARTITION BY id_sessao ORDER BY timestamp_mensagem) AS seq_mensagem
    FROM mensagens
),

lead_mensagens_ura AS (
    SELECT
        id_sessao,
        data_sessao,
        timestamp_mensagem,
        id_ura,
        ura_nome,
        id_passo_ura,
        nome_passo_ura,
        origem_mensagem,
        seq_mensagem,
        mensagem_texto,
        -- Encontra o timestamp da próxima mensagem na sessão
        LEAD(timestamp_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS timestamp_proxima_msg,
        -- Encontra a origem da próxima mensagem na sessão
        LEAD(origem_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS origem_proxima_msg
    FROM mensagens_com_seq
),

mensagens_ura_seguidas_por_cliente AS (
    SELECT
        id_sessao,
        data_sessao,
        timestamp_mensagem,
        id_ura,
        ura_nome,
        id_passo_ura,
        seq_mensagem,
        nome_passo_ura,
        mensagem_texto,
        -- Encontra o timestamp da próxima mensagem na sessão
        LEAD(timestamp_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS timestamp_proxima_msg,
        -- Encontra a origem da próxima mensagem na sessão
        LEAD(origem_mensagem) OVER (PARTITION BY id_sessao ORDER BY seq_mensagem) AS origem_proxima_msg,
        ROW_NUMBER() OVER (PARTITION BY id_sessao ORDER BY timestamp_mensagem) AS seq_ura
    FROM lead_mensagens_ura
    WHERE origem_mensagem = 'URA' -- Seleciona apenas mensagens da URA
    AND origem_proxima_msg = 'CUSTOMER' -- Considera apenas os casos em que a próxima mensagem é do cliente
)

-- Agrega os resultados para calcular as métricas por etapa
SELECT
    data_sessao,
    id_ura,
    ura_nome,
    id_passo_ura,
    seq_ura,
    nome_passo_ura,
    mensagem_texto,
    COUNT(id_sessao) AS total_respostas,
    ROUND(AVG(TIMESTAMP_DIFF(timestamp_proxima_msg, timestamp_mensagem, SECOND)), 2) AS tempo_medio_resposta_seg -- Tempo entre URA enviada e Cliente Responde
FROM mensagens_ura_seguidas_por_cliente
GROUP BY data_sessao, id_ura, ura_nome, id_passo_ura, nome_passo_ura, seq_ura, mensagem_texto
ORDER BY data_sessao DESC, id_ura, seq_ura