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

WITH fluxo_status AS (
  SELECT
    id_sessao,
    protocolo,
    canal,
    inicio_datahora,
    fim_datahora,
    DATE(inicio_datahora) AS data_sessao,
    
    JSON_VALUE(tabulacao, '$.id') AS tabulation_id,
    JSON_VALUE(tabulacao, '$.nome') AS tabulation_name,

    (SELECT COUNT(1) > 0 
     FROM UNNEST(JSON_QUERY_ARRAY(erro_fluxo, '$.tipo_erro')) AS erro_tipo 
     WHERE erro_tipo = '"fluxo_travado"') AS fluxo_travado,

    TIMESTAMP_DIFF(fim_datahora, inicio_datahora, SECOND) AS duracao_sessao_segundos
    
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }}
)

SELECT
  data_sessao,
  canal,

  COUNT(id_sessao) AS total_sessoes,
  
  COUNTIF(tabulation_id = '35') AS sessoes_encerradas_cliente,
  COUNTIF(tabulation_id = '37') AS sessoes_encerradas_janela,
  COUNTIF(tabulation_id NOT IN ('35', '37') AND tabulation_id IS NOT NULL) AS sessoes_outro_tipo,
  COUNTIF(tabulation_id IS NULL) AS sessoes_sem_tabulacao,  
  COUNTIF(fluxo_travado) AS total_fluxos_travados,
  ROUND(COUNTIF(tabulation_id = '35') / NULLIF(COUNT(id_sessao), 0) * 100, 2) AS taxa_opt_out_porcentagem,
  AVG(duracao_sessao_segundos) AS duracao_media_segundos
  
FROM fluxo_status
GROUP BY data_sessao, canal
ORDER BY data_sessao DESC, canal