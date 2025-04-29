{{
    config(
        alias="atendimento",
        schema="disparos",
        materialized='table',
        partition_by={
            "field": "data",
            "data_type": "date",
            "range": {"start": "2019-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

WITH message_data AS (
  SELECT
    id_sessao,
    protocolo,
    canal,
    inicio_datahora,
    fim_datahora,
    mensagens
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }}
),

flattened_messages AS (
  SELECT
    id_sessao,
    protocolo,
    canal,
    inicio_datahora,
    fim_datahora,
    msg.data as timestamp_mensagem,
    msg.id as id_mensagem,
    msg.fonte as origem_mensagem,
    msg.tipo as tipo_mensagem,
    msg.texto as texto_mensagem,
    msg.passo_ura.id as id_passo,
    msg.passo_ura.nome as nome_passo
  FROM message_data,
  UNNEST(mensagens) as msg
),

session_timestamps AS (
  SELECT
    id_sessao,
    MIN(timestamp_mensagem) as primeira_mensagem,
    MAX(CASE WHEN origem_mensagem = 'CUSTOMER' THEN timestamp_mensagem ELSE NULL END) as ultima_mensagem_cliente
  FROM flattened_messages
  GROUP BY id_sessao
),

message_response_times AS (
  SELECT
    id_sessao,
    id_mensagem,
    origem_mensagem,
    timestamp_mensagem,
    CASE 
      WHEN origem_mensagem = 'CUSTOMER' AND 
           LEAD(origem_mensagem) OVER (PARTITION BY id_sessao ORDER BY timestamp_mensagem) = 'URA'
      THEN TIMESTAMP_DIFF(
           LEAD(timestamp_mensagem) OVER (PARTITION BY id_sessao ORDER BY timestamp_mensagem), 
           timestamp_mensagem, 
           SECOND)
      ELSE NULL
    END as tempo_resposta_segundos
  FROM flattened_messages
),

session_metrics AS (
  SELECT
    fm.id_sessao,
    fm.protocolo,
    fm.canal,
    DATE(fm.inicio_datahora) as data_sessao,
    fm.inicio_datahora as inicio_sessao,
    fm.fim_datahora as fim_sessao,
    
    -- Tempo efetivo de sessão (do início até a última mensagem do cliente)
    TIMESTAMP_DIFF(TIMESTAMP(st.ultima_mensagem_cliente), TIMESTAMP(fm.inicio_datahora), SECOND) as duracao_efetiva_segundos,
    
    COUNTIF(fm.origem_mensagem = 'SYSTEM') as mensagens_sistema,
    COUNTIF(fm.origem_mensagem = 'CUSTOMER') as mensagens_cliente,
    COUNTIF(fm.origem_mensagem = 'URA') as mensagens_ura,
    COUNT(DISTINCT fm.id_mensagem) as total_mensagens,
    
    COUNTIF(fm.tipo_mensagem = 'TEXT') as mensagens_texto,
    COUNTIF(fm.tipo_mensagem = 'AUDIO') as mensagens_audio,

    AVG(mrt.tempo_resposta_segundos) as tempo_medio_resposta_segundos,
    
    COUNT(DISTINCT fm.id_passo) as quantidade_passos_unicos
  FROM flattened_messages fm
  LEFT JOIN session_timestamps st ON fm.id_sessao = st.id_sessao
  LEFT JOIN message_response_times mrt ON 
    fm.id_sessao = mrt.id_sessao AND 
    fm.id_mensagem = mrt.id_mensagem
  GROUP BY 
    fm.id_sessao, fm.protocolo, fm.canal, fm.inicio_datahora, fm.fim_datahora, 
    st.ultima_mensagem_cliente
),

daily_metrics AS (
  SELECT
    data_sessao,
    COUNT(id_sessao) as total_sessoes,
    SUM(mensagens_cliente) as total_mensagens_cliente,
    SUM(mensagens_ura) as total_mensagens_ura,
    SUM(mensagens_texto) as total_mensagens_texto,
    SUM(mensagens_audio) as total_mensagens_audio,
    
    -- Métricas de tempo ajustadas
    AVG(duracao_efetiva_segundos) as tempo_medio_efetivo,
    APPROX_QUANTILES(duracao_efetiva_segundos, 100)[OFFSET(50)] as mediana_duracao_efetiva,
    
    AVG(tempo_medio_resposta_segundos) as tempo_medio_resposta,
    
    AVG(mensagens_cliente) as media_mensagens_cliente_por_sessao,
    SAFE_DIVIDE(SUM(mensagens_audio), SUM(mensagens_cliente)) * 100 as percentual_uso_audio,
    
    AVG(quantidade_passos_unicos) as media_passos_por_sessao
  FROM session_metrics
  GROUP BY data_sessao
)

SELECT
  data_sessao as data,
  total_sessoes,
  total_mensagens_cliente,
  total_mensagens_ura,
  total_mensagens_texto,
  total_mensagens_audio,

  ROUND(tempo_medio_efetivo, 2) as tempo_medio_efetivo_segundos,
  ROUND(mediana_duracao_efetiva, 2) as mediana_duracao_segundos,
  ROUND(tempo_medio_resposta, 2) as tempo_medio_resposta_segundos,
  
  ROUND(media_mensagens_cliente_por_sessao, 2) as media_mensagens_cliente,
  ROUND(percentual_uso_audio, 2) as percentual_uso_audio,
  
  ROUND(media_passos_por_sessao, 2) as media_passos_por_sessao
FROM daily_metrics
ORDER BY data_sessao DESC