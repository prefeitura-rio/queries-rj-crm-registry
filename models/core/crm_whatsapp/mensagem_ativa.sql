{{ config(alias="mensagem_ativa", schema="crm_whatsapp", materialized="table") }}

SELECT * FROM {{ ref('base_mensagem_ativa') }}
ORDER BY CAST(id_hsm AS INT64)