{{ config(
    alias="telefone_disparado",
    schema="crm_whatsapp",
    materialized="incremental",
    tags=["hourly"],
    unique_key=["id_hsm", "contato_telefone", "id_disparo"],
    partition_by={
        "field": "data_particao",
        "data_type": "date"
    }
) }}

WITH seleciona_dados AS (
  -- para eliminar as linhas que posteriormente tiveram erro e na descricao_falha aparece null
  SELECT
    id_hsm,
    id_disparo,
    contato_telefone,
    criacao_envio_datahora,
    data_particao,
    descricao_falha,
    ROW_NUMBER() OVER (PARTITION BY id_hsm, contato_telefone, id_disparo, criacao_envio_datahora ORDER BY datarelay_datahora DESC, descricao_falha DESC) AS last_webhook
  FROM {{ ref("int_chatbot_base_disparo") }}
  -- WHERE (descricao_falha NOT LIKE "%131048%" OR descricao_falha IS NULL) -- remove erro de disparo fora do limite

  {% if is_incremental() %}
    AND DATE(data_particao) >= DATE_SUB(CURRENT_DATE('America/Sao_Paulo'), INTERVAL 4 DAY)
  {% endif %}

)

SELECT
  DISTINCT
    id_hsm,
    id_disparo,
    contato_telefone,
    DATE(criacao_envio_datahora) AS data_disparo,
    data_particao,
    descricao_falha
FROM seleciona_dados
WHERE last_webhook = 1