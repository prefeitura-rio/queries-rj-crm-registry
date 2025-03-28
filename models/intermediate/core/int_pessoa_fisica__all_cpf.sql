-- - Consolidates CPF records from multiple Rio de Janeiro city systems (health,
-- social assistance, citizen services, transportation, and BCadastro) into a unified
-- view with source tracking and counting.
{{
    config(
        alias="all_cpfs",
        schema="intermediario_dados_mestres",
        materialized=('table' if target.name == 'dev' else 'ephemeral'),
        partition_by={
            "field": "cpf_particao",
            "data_type": "int64",
            "range": {"start": 0, "end": 100000000000, "interval": 34722222},
        },
    )
}}

with
    saude as (
        select distinct cpf, 'saude' as origem from {{ source("rj-sms", "paciente") }}
    ),

    cadunico as (
        select distinct cpf, 'cadunico' as origem
        from {{ source("rj-smas", "cadastros") }}
    ),

    chamados as (
        select distinct cpf, '1746' as origem
        from {{ source("rj-segovi", "1746_chamado_cpf") }}
    ),

    transporte as (
        select distinct cpf_cliente as cpf, 'transporte' as origem
        from {{ source("rj-smtr", "transacao_cpf") }}
        where cpf_particao is not null
    ),

    bcadastro as (
        select distinct b.cpf, 'bcadastro' as origem
        from {{ source("bcadastro", "cpf") }} as b
        where b.endereco_municipio = 'Rio de Janeiro'
    ),

    all_cpfs as (
        select *
        from saude
        union all
        select *
        from cadunico
        union all
        select *
        from chamados
        union all
        select *
        from transporte
        union all
        select *
        from bcadastro
    ),

    final_tb as (
        select
            cpf,
            array_agg(origem order by origem) as origens,
            count(*) as origens_count,
            cast(cpf as int64) as cpf_particao
        from all_cpfs
        group by cpf
    )

select cpf, origens, origens_count, cpf_particao
from final_tb
