CREATE OR REPLACE TABLE `rj-crm-registry.app_identidade_unica.cpf` AS (
  with
    saude as (
        select distinct cpf, 'saude' as origem
        from `rj-sms.app_historico_clinico.paciente`
    ),

    cadunico as (
        select distinct cpf, 'cadunico' as origem
        from `rj-smas.app_identidade_unica.cadastros`
    ),

    chamados as (
        select distinct cpf, '1746' as origem
        from `rj-segovi.app_identidade_unica.1746_chamado_cpf`
    ),

    transporte as (
        select distinct cpf_cliente as cpf, 'transporte' as origem
        from `rj-smtr-dev.projeto_cadastro_unico.transacao_cpf`
    ),

    bcadastro as (
        select distinct cpf_id as cpf, 'bcadastro' as origem
        from `rj-crm-registry.brutos_bcadastro.cpf`
        where nome_municipio_domicilio = 'Rio de Janeiro'
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
        select cpf, array_agg(origem order by origem) as origens, count(*) as count
        from all_cpfs
        group by cpf
    )

select *
from final_tb
order by count desc
)