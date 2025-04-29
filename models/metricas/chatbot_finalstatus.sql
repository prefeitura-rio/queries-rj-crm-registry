{{
    config(
        alias="atendimento_status_finalizacao",
        schema="disparos",
        materialized='table'
         partition_by={
             "field": "data_inicio",
             "data_type": "date",
         },
    )
}}

WITH ura_atendimentos AS (
    SELECT
        id_sessao AS atendimento_id,
        protocolo AS protocol,
        canal AS channel,
        inicio_datahora AS data_inicio,
        fim_datahora AS data_fim,
        SAFE_CAST(JSON_EXTRACT_SCALAR(tabulacao, '$.tabulacao.id') AS INT64) AS tabulation_id,
        JSON_EXTRACT_SCALAR(tabulacao, '$.tabulacao.nome') AS tabulation_name,
        JSON_EXTRACT_SCALAR(contato, '$.contato.id') AS contact_id,
        JSON_EXTRACT_SCALAR(contato, '$.contato.nome') AS contact_name
    FROM `rj-crm-registry.brutos_wetalkie.fluxos_ura`
)

SELECT
    atendimento_id,
    contact_id AS account,
    protocol,
    channel,
    DATE(data_inicio) AS data_inicio,
    tabulation_id AS tabulation,
    CASE
        WHEN tabulation_id IS NULL THEN 'Em Andamento'
        WHEN tabulation_id = 37 THEN 'Timeout'
        WHEN tabulation_id = 35 THEN 'Opt-out'
        WHEN tabulation_id = 4 THEN 'Finalizado na URA (automática)'
        ELSE 'Outro(' || CAST(tabulation_id AS STRING) || ' - ' || tabulation_name || ')'
    END AS status_finalizacao,
    TIMESTAMP_DIFF(TIMESTAMP(data_fim), TIMESTAMP(data_inicio), SECOND) AS duracao_sessao_segundos
FROM ura_atendimentos