{{
    config(
        alias="enderecos",
        schema="crm_dados_mestres",
        materialized="table",
        tags=["daily"],
    )
}}

with
    source as (
        select *
        from {{ source("brutos_dados_enriquecidos", "enderecos_geolocalizados") }}
    )

select distinct *
from source
