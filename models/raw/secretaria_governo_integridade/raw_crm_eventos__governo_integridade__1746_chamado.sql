{{
    config(
        alias="governo_integridade__1746_chamado",
        schema="crm_eventos",
        materialized="view"
    )
}}


with source as (
        select * from {{ source('rj-segovi', '1746_chamado_cpf') }}
  )

select * from source