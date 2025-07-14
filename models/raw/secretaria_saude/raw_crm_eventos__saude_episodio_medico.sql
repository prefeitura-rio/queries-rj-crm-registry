{{ config(alias="saude__episodio_medico", schema="crm_eventos", materialized="view") }}
with
    source as (
        select * from {{ source("rj-sms-historico-clinico", "episodio_assistencial") }}
    )

select *
from source
