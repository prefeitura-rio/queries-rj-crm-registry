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
        templateId,
        tabulation_id,
        sendDate,
        account,
        DATE(sendDate AT TIME ZONE 'UTC') AS data_envio
    FROM {{ source('disparos', 'fluxo_atendimento') }}
)

SELECT
    data_envio,
    templateId,
    COUNT(*) as total_mensagens,
    COUNT(CASE WHEN tabulation_id = 35 THEN 1 END) as total_opt_outs,
    ROUND(COUNT(CASE WHEN tabulation_id = 35 THEN 1 END) * 100.0 / COUNT(*), 2) as taxa_opt_out
FROM opt_out_base
GROUP BY data_envio, templateId 