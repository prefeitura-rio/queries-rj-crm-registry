{{ config(alias="telefone_sem_whatsapp", schema="crm_whatsapp", materialized="table", tags=["daily"]) }}

WITH 
  celulares_sem_whatsapp AS (
    SELECT
        CAST(flatTarget AS STRING) as telefone,
        MAX(DATE(DATE_TRUNC(sendDate, DAy))) as data_atualizacao
    FROM {{ source("rj-crm-registry", "fluxo_atendimento_*") }}
    WHERE failedDate IS NOT NULL AND faultDescription LIKE "%131026%"
    GROUP BY telefone
  )

SELECT * FROM celulares_sem_whatsapp

