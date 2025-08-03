{{ config(
    alias="telefone_disparado",
    schema="crm_whatsapp",
    materialized="incremental",
    tags=["hourly"],
    unique_key=["id_hsm", "contato_telefone", "data_particao"],
    partition_by={
        "field": "data_particao",
        "data_type": "date"
    }
) }}

WITH seleciona_dados AS (
  -- para eliminar as linhas que posteriormente tiveram erro e na descricao_falha aparece null
  SELECT
    id_hsm,
    contato_telefone,
    criacao_envio_datahora,
    data_particao,
    MAX(descricao_falha) AS descricao_falha
  FROM {{ ref("int_whatsapp_fluxo_atendimento") }}
  WHERE (descricao_falha NOT LIKE "%131048%" OR descricao_falha IS NULL) -- remove erro de disparo fora do limite

  {% if is_incremental() %}
    AND DATE(data_particao) >= DATE_SUB(CURRENT_DATE('America/Sao_Paulo'), INTERVAL 4 DAY)
  {% endif %}
    GROUP BY 1, 2, 3, 4
)

SELECT
  DISTINCT
    id_hsm,
    contato_telefone,
    DATE(criacao_envio_datahora) AS data_disparo,
    data_particao,
    descricao_falha
FROM seleciona_dados