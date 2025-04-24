{{
  config(
    materialized='table'
  )
}}

WITH filtered_data AS (
    SELECT *
    FROM {{ ref('fluxos_ura')}}  -- Usando o model que já contém os dados transformados
    WHERE ura.id = '71'  -- Filtrando apenas os registros da URA de interesse
),

messages_exploded AS (
    SELECT
        id_sessao,
        protocolo,
        canal,
        inicio_data,
        inicio_datahora,
        fim_datahora,
        ura.id as id_ura,
        ura.nome as ura_name,
        m.passo_ura.id as step_id,
        m.texto,
        m.fonte,
        m.data
    FROM filtered_data,
    UNNEST(mensagens) as m
    WHERE 
        m.passo_ura.id IS NOT NULL
        AND m.texto IS NOT NULL
),

feedback_pairs AS (
    SELECT
        id_ura,
        id_sessao,
        ura_name,
        protocolo,
        canal,
        inicio_datahora as begin_date,
        fim_datahora as end_date,
        FIRST_VALUE(texto) OVER (
            PARTITION BY id_ura, step_id
            ORDER BY data
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as pergunta,
        LAST_VALUE(texto) OVER (
            PARTITION BY id_ura, step_id
            ORDER BY data
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) as resposta,
        fonte as source,
        step_id
    FROM messages_exploded
)

SELECT DISTINCT
    id_ura,
    id_sessao as id_reply,
    ura_name,
    protocolo as protocol,
    canal as channel,
    begin_date,
    end_date,
    pergunta as feedback_pergunta,
    resposta as feedback_resposta
FROM feedback_pairs
WHERE 
    source = 'CUSTOMER'
    AND pergunta IS NOT NULL 
    AND resposta IS NOT NULL
    AND pergunta != resposta