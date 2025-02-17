with
    saude as (
        select distinct cpf, 'saude' as origem
        from {{ source('rj-sms', 'paciente') }}
    ),


    cadunico as (
        select distinct cpf, 'cadunico' as origem
        from {{ source('rj-smas', 'cadastros') }}
    ),

    chamados as (
        select distinct cpf, '1746' as origem
        from {{ source('rj-segovi', '1746_chamado_cpf') }}
    ),

    transporte as (
        select distinct cpf_cliente as cpf, 'transporte' as origem
        from {{ source('rj-smtr', 'transacao_cpf') }}
        where cpf_particao is not null
    ),

    bcadastro as (
        select distinct cpf, 'bcadastro' as origem
        from {{ ref('raw_bcadastro__cpf') }}
        where cpf_particao is not null and endereco_municipio = 'Rio de Janeiro'
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
