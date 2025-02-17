CREATE OR REPLACE TABLE `rj-crm-registry.crm_identidade_unica.pessoa_fisica` 
PARTITION BY
  RANGE_BUCKET(cpf_particao, GENERATE_ARRAY(0, 100000000000, 34722222))

  AS
  (
with
    cadastros as (
        select
            cpf, origens, dados, endereco, contato, saude, assistencia_social, fazenda
        from `rj-crm-registry.crm_identidade_unica_staging.pessoa_fisica`
        where
            cpf_particao is not null
{# and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
    ),

    all_cpf as (select distinct cpf from cadastros),

    dados_bcadastro as (
        select
            cpf,
            dados.source,
            dados.rank,
            dados.nome,
            dados.nome_social,
            dados.data_nascimento,
            dados.obito_indicador,
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.data_ultima_atualizacao,
            dados.estrangeiro
        from cadastros
        left join unnest(dados) as dados
        where dados.source = 'bcadastro' and dados.rank = 1
    ),

    dados_saude as (
        select
            cpf,
            dados.source,
            dados.rank,
            dados.nome,
            dados.nome_social,
            dados.data_nascimento,
            dados.obito_indicador,
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.data_ultima_atualizacao,
            dados.estrangeiro
        from cadastros
        left join unnest(dados) as dados
        where dados.source = 'saude' and dados.rank = 1
    ),

    dados_cadunico as (
        select
            cpf,
            dados.source,
            dados.rank,
            dados.nome,
            dados.nome_social,
            dados.data_nascimento,
            dados.obito_indicador,
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.data_ultima_atualizacao,
            dados.estrangeiro
        from cadastros
        left join unnest(dados) as dados
        where dados.source = 'cadunico' and dados.rank = 1
    ),

    dados as (
        select
            cpfs.cpf,

-- nome
            coalesce(bcadastro.nome, saude.nome, cadunico.nome) as nome,

-- has_nome_social
            saude.nome_social is not null as has_nome_social,

-- data_nascimento
            coalesce(
                bcadastro.data_nascimento,
                saude.data_nascimento,
                cadunico.data_nascimento
            ) as data_nascimento,

-- obito_indicador
            coalesce(
                saude.obito_indicador, bcadastro.obito_indicador
            ) as obito_indicador,

-- genero
            lower(coalesce(bcadastro.genero, saude.genero, cadunico.genero)) as genero,

-- raca
            coalesce(saude.raca, cadunico.raca) as raca,

-- nome_mae
            coalesce(bcadastro.nome_mae, saude.nome_mae, cadunico.nome_mae) as nome_mae,

-- nome_pai
            coalesce(saude.nome_pai, cadunico.nome_pai) as nome_pai,

-- estrangeiro
            coalesce(bcadastro.estrangeiro, saude.estrangeiro, cadunico.estrangeiro) as estrangeiro

        from all_cpf as cpfs
        left join dados_bcadastro as bcadastro on cpfs.cpf = bcadastro.cpf
        left join dados_saude as saude on cpfs.cpf = saude.cpf
        left join dados_cadunico as cadunico on cpfs.cpf = cadunico.cpf
    )

select
    a.cpf,
    c.origens,
    d.nome,
    d.has_nome_social,
    d.data_nascimento,
    d.obito_indicador,
    d.genero,
    d.raca,
    d.nome_mae,
    d.nome_pai,
    d.estrangeiro,
    c.endereco,
    c.contato,
    c.fazenda,
    c.saude,
    c.assistencia_social,
    cast(a.cpf as int64) as cpf_particao
from all_cpf a
left join dados d on a.cpf = d.cpf
left join
    cadastros c on a.cpf = c.cpf
    )
