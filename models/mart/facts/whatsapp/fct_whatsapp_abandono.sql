{{
    config(
        materialized='table',
        schema='disparos',
        partition_by={
            "field": "inicio_datahora",
            "data_type": "date",
            "range": {"start": "2023-01-01", "end": "9999-12-31", "interval": "1 day"},
        },
    )
}}

SELECT
  DATE(inicio_datahora) as inicio_datahora,
  COUNT(id_sessao) as total_sessoes_dia,
  COUNTIF(tabulacao.id = '37') as sessoes_abandono_chat,
  SAFE_DIVIDE(COUNTIF(tabulacao.id = '37'), COUNT(id_sessao)) * 100 as taxa_abandono_chat_percentual
FROM {{ source('brutos_wetalkie', 'fluxos_ura') }} -- Usa a macro source do dbt
GROUP BY 1
ORDER BY 1 DESC