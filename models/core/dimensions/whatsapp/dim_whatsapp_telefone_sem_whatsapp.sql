{{
    config(
        alias="telefone_sem_whatsapp",
        schema="crm_whatsapp",
        materialized="table",
        tags=["daily"],
    )
}}

with
    celulares_sem_whatsapp as (
        select
            cast(flattarget as string) as telefone,
            max(date(date_trunc(senddate, day))) as data_atualizacao
        from {{ source("rj-crm-registry", "fluxo_atendimento_*") }}
        where faileddate is not null and faultdescription like "%131026%"
        group by telefone
    )

select *
from celulares_sem_whatsapp
