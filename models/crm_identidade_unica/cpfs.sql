CREATE OR REPLACE TABLE `rj-crm-registry.crm_identidade_unica.cpf` 
PARTITION BY
  RANGE_BUCKET(cpf_particao, GENERATE_ARRAY(0, 100000000000, 34722222))
  

  AS

(
  with
    saude as (
        select distinct cpf, 'saude' as origem
        from `rj-sms.saude_historico_clinico.paciente`
        where cpf_particao is not null
    ),

    saude_episodio as (
        select distinct cpf, 'saude_episodio' as origem
        from `rj-sms.app_historico_clinico.episodio_assistencial`
        where cpf_particao is not null
    ),

    cadunico as (
        select distinct cpf, 'cadunico' as origem
        from `rj-smas.app_identidade_unica.cadastros`
        where cpf_particao is not null
    ),

    chamados as (
        select distinct cpf, '1746' as origem
        from `rj-segovi.app_identidade_unica.1746_chamado_cpf`
        where cpf_particao is not null
    ),

    transporte as (
        select distinct cpf_cliente as cpf, 'transporte' as origem
        from `rj-smtr-dev.projeto_cadastro_unico.transacao_cpf`
        where cpf_particao is not null
    ),

    bcadastro as (
        select distinct cpf, 'bcadastro' as origem
        from `rj-crm-registry.brutos_bcadastro.cpf`
        where cpf_particao is not null
         and  municipio_domicilio = 'Rio de Janeiro'
    ),

    all_cpfs as (
        select *
        from saude
        union all
        select *
        from saude_episodio
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
        select cpf, array_agg(origem order by origem) as origens, count(*) as origens_count, cast(cpf as int64) as cpf_particao from all_cpfs
        group by cpf
    )

select 
    cpf,
    origens,
    origens_count,
    cpf_particao
from final_tb
)
