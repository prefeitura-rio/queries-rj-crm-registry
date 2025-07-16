{{
  config(
    alias="fluxo_atendimento",
    schema="crm_whatsapp",
    materialized="incremental",
    tags=["daily"],
    unique_key=["id_disparo", "id_contato", "data_particao"],
    partition_by={
        "field": "data_particao",
        "data_type": "date"
    },
    cluster_by=["ano_particao", "mes_particao"] 
  )
}}
-- TODO: converter datas pta UTC?
WITH
    source AS (
        SELECT *
        FROM {{ source("brutos_wetalkie_staging", "fluxo_atendimento_*" ) }}
        {% if is_incremental() %}
          WHERE createDate >= (
            SELECT MAX(criacao_envio_datahora) 
            FROM {{ this }}
          )
          OR createDate >= TIMESTAMP_SUB(
            CURRENT_TIMESTAMP(),
            INTERVAL 2 DAY
          ) -- Safety net para garantir captura
        {% else %}
          -- Carga inicial completa
          WHERE createDate >= '2025-04-18 12:00:00'
        {% endif %}
    ),

    fluxo_atendimento AS (
        SELECT
            DISTINCT
            account AS id_conta,
            templateId AS id_hsm,
            triggerId AS id_disparo,
            targetExternalId AS id_externo,
            replyId AS id_sessao,
            targetId AS id_contato,
            flatTarget AS contato_telefone,
            createDate AS criacao_envio_datahora,
            sendDate AS envio_datahora,
            deliveryDate AS entrega_datahora,
            readDate AS leitura_datahora,
            failedDate AS falha_datahora,
            replyDate AS resposta_datahora,
            faultDescription AS descricao_falha,
            LOWER(status) AS status_disparo,
            CASE
                WHEN status = "PROCESSING" THEN 1
                WHEN status = "SENT" THEN 2
                WHEN status = "DELIVERED" THEN 3
                WHEN status = "READ" THEN 4
                WHEN status = "FAILED" THEN 5
            END AS id_status_disparo,
            datarelay_timestamp AS datarelay_datahora,
            CAST(EXTRACT(YEAR FROM DATETIME(sendDate, 'America/Sao_Paulo')) AS STRING) AS ano_particao,
            CAST(EXTRACT(MONTH FROM DATETIME(sendDate, 'America/Sao_Paulo')) AS STRING) AS mes_particao,
            DATE(DATETIME(sendDate, 'America/Sao_Paulo')) AS data_particao
        FROM source
    )

SELECT * FROM fluxo_atendimento