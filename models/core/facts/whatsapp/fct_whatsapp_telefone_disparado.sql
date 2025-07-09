{{ config(alias="telefone_disparado", schema="crm_whatsapp", materialized="view") }}

SELECT
  DISTINCT
  templateId as id_hsm,
  flatTarget as telefone,
  DATE(createDate) as data_disparo
FROM {{ source("rj-crm-registry", "fluxo_atendimento_*") }}
WHERE faultDescription NOT LIKE "%131048%"