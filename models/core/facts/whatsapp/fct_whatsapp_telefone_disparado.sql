{{ config(
    alias="telefone_disparado",
    schema="crm_whatsapp",
    materialized="incremental",
    tags=["hourly"],
    unique_key=["id_hsm", "contato_telefone", "data_particao"],
    partition_by={
        "field": "data_particao",
        "data_type": "date"
    },
    enabled=false
) }}

{# Disabled due to missing WhatsApp dataset #}

SELECT
  DISTINCT
  id_hsm,
  contato_telefone,
  DATE(criacao_envio_datahora) AS data_disparo,
  data_particao
FROM {{ ref("int_whatsapp_fluxo_atendimento") }}
WHERE descricao_falha NOT LIKE "%131048%"

{% if is_incremental() %}
  AND DATE(data_particao) >= DATE_SUB(CURRENT_DATE('America/Sao_Paulo'), INTERVAL 4 DAY)
{% endif %}
