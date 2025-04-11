{{
    config(
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        schema='disparos'
    )
}}

-- Esse modelo calcula a taxa de opt-out por templateId e data de envio
-- Problemático e precisa de revisão
-- Paty disse que o 35 indica que a conversa foi encerrada pelo cliente, nao que houve opt-out.



WITH opt_out_base AS (
    SELECT
        fa.templateId,
        fa.sendDate,
        fa.replyId,
        fa.account,
        DATE(fa.sendDate AT TIME ZONE 'UTC') AS data_envio
    FROM {{ source('disparos', 'fluxo_atendimento') }} fa
)

SELECT
    ob.data_envio,
    ob.templateId,
    COUNT(*) as total_mensagens,

    COUNT(CASE WHEN SAFE_CAST(JSON_VALUE(fu.json_data, '$.tabulation.id') AS INT64) = 35 THEN 1 END) as total_opt_outs,
    ROUND(COUNT(CASE WHEN SAFE_CAST(JSON_VALUE(fu.json_data, '$.tabulation.id') AS INT64) = 35 THEN 1 END) * 100.0 / COUNT(*), 2) as taxa_opt_out
FROM opt_out_base ob
LEFT JOIN {{ source('disparos_staging', 'fluxos_ura') }} fu 
    ON ob.replyId = fu.id_reply
GROUP BY ob.data_envio, ob.templateId 