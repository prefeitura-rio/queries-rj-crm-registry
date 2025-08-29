{{ config(alias="mensagem_ativa", schema="crm_whatsapp", materialized="table") }}

SELECT * FROM {{ ref('raw_wetalkie_mensagem_ativa') }}
ORDER BY CAST(id_hsm AS INT64)