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

WITH mensagem_metricas AS (
  SELECT
    f.id_sessao,
    f.protocolo,
    f.canal,
    DATE(f.inicio_datahora) AS data_sessao,

    m.data AS timestamp_mensagem,
    m.id AS id_mensagem,
    m.fonte AS origem_mensagem,
    m.tipo AS tipo_mensagem,

    CASE
      WHEN m.fonte = 'URA'
      THEN EXISTS(
        SELECT 1 
        FROM UNNEST(f.mensagens) as next_m 
        WHERE next_m.fonte = 'CUSTOMER' 
          AND next_m.data > m.data
      )
      ELSE FALSE
    END AS recebeu_resposta,

    CASE
      WHEN m.fonte = 'URA'
      THEN (
        SELECT MIN(TIMESTAMP_DIFF(next_m.data, m.data, SECOND))
        FROM UNNEST(f.mensagens) as next_m 
        WHERE next_m.fonte = 'CUSTOMER' 
          AND next_m.data > m.data
      )
      ELSE NULL
    END AS tempo_ate_resposta_segundos

  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }} f,
  UNNEST(f.mensagens) AS m
  WHERE m.fonte = 'URA' 
)

SELECT
  data_sessao,
  canal,

  -- Contagens
  COUNT(id_mensagem) AS total_mensagens_enviadas,
  COUNTIF(recebeu_resposta) AS total_mensagens_respondidas,
  
  -- Taxas de resp.
  ROUND(COUNTIF(recebeu_resposta) / NULLIF(COUNT(id_mensagem), 0) * 100, 2) AS taxa_resposta_porcentagem,
  
  -- Tempo
  AVG(tempo_ate_resposta_segundos) AS tempo_medio_resposta_segundos,
  APPROX_QUANTILES(tempo_ate_resposta_segundos, 100)[OFFSET(50)] AS mediana_tempo_resposta_segundos,
  APPROX_QUANTILES(tempo_ate_resposta_segundos, 100)[OFFSET(90)] AS p90_tempo_resposta_segundos,
  
  -- Tipo de Mensagem
  COUNTIF(tipo_mensagem = 'TEXT') AS total_mensagens_texto,
  COUNTIF(tipo_mensagem = 'AUDIO') AS total_mensagens_audio,
  
  COUNTIF(tipo_mensagem = 'TEXT' AND recebeu_resposta) AS mensagens_texto_respondidas,
  COUNTIF(tipo_mensagem = 'AUDIO' AND recebeu_resposta) AS mensagens_audio_respondidas,

  -- Resposta por Tipo
  ROUND(COUNTIF(tipo_mensagem = 'TEXT' AND recebeu_resposta) / 
        NULLIF(COUNTIF(tipo_mensagem = 'TEXT'), 0) * 100, 2) AS taxa_resposta_texto_porcentagem
  
FROM mensagem_metricas
GROUP BY data_sessao, canal
ORDER BY data_sessao DESC, canal