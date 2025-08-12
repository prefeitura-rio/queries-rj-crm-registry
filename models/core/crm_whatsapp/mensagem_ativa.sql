{{ config(alias="mensagem_ativa", schema="crm_whatsapp", materialized="table") }}

SELECT * FROM {{ ref('base_mensagem_ativa') }}