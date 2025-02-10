DECLARE cpf_filter1 INT64 DEFAULT ;
DECLARE cpf_filter2 INT64 DEFAULT ;
DECLARE cpf_filter3 INT64 DEFAULT ;


with
    cadastros as (
        select cpf, origens, dados, endereco, contato, saude, assistencia_social
        from `rj-crm-registry.crm_identidade_unica.cadastros`
        where
            cpf_particao is not null
            and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
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
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.ocupacao,
            dados.data_ultima_atualizacao,
            dados.situacao_cadastral,
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
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.ocupacao,
            dados.data_ultima_atualizacao,
            dados.situacao_cadastral,
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
            dados.genero,
            dados.raca,
            dados.nome_mae,
            dados.nome_pai,
            dados.ocupacao,
            dados.data_ultima_atualizacao,
            dados.situacao_cadastral,
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

            -- genero
            lower(coalesce(bcadastro.genero, saude.genero, cadunico.genero)) as genero,

            -- raca
            coalesce(saude.raca, cadunico.raca) as raca,

            -- nome_mae
            coalesce(bcadastro.nome_mae, saude.nome_mae, cadunico.nome_mae) as nome_mae,

            -- nome_pai
            coalesce(saude.nome_pai, cadunico.nome_pai) as nome_pai,

            -- ocupacao
            bcadastro.ocupacao as ocupacao,

            -- situacao_cadastral
            bcadastro.situacao_cadastral as situacao_cadastral

        from all_cpf as cpfs
        left join dados_bcadastro as bcadastro on cpfs.cpf = bcadastro.cpf
        left join dados_saude as saude on cpfs.cpf = saude.cpf
        left join dados_cadunico as cadunico on cpfs.cpf = cadunico.cpf
    ),

    -- endereco
    endereco_bcadastro as (
        select
            cpf,
            endereco.source,
            endereco.rank,
            endereco.cep,
            endereco.tipo_logradouro,
            endereco.logradouro,
            endereco.numero,
            endereco.complemento,
            endereco.bairro,
            endereco.cidade,
            endereco.estado,
            endereco.residente_exterior,
            endereco.sistema
        from cadastros
        left join unnest(endereco) as endereco
        where endereco.source = 'bcadastro' and endereco.rank = 1
    ),

    endereco_saude as (
        select
            cpf,
            endereco.source,
            endereco.rank,
            endereco.cep,
            endereco.tipo_logradouro,
            endereco.logradouro,
            endereco.numero,
            endereco.complemento,
            endereco.bairro,
            endereco.cidade,
            endereco.estado,
            endereco.residente_exterior,
            endereco.sistema
        from cadastros
        left join unnest(endereco) as endereco
        where endereco.source = 'saude' and endereco.rank = 1
    ),

    endereco as (
        -- give preference to saude
        select
            cpfs.cpf,
            struct(
                -- cep
                coalesce(saude.cep, bcadastro.cep) as cep,

                -- tipo_logradouro
                coalesce(
                    saude.tipo_logradouro, bcadastro.tipo_logradouro
                ) as tipo_logradouro,

                -- logradouro
                coalesce(saude.logradouro, bcadastro.logradouro) as logradouro,

                -- numero
                coalesce(saude.numero, bcadastro.numero) as numero,

                -- complemento
                coalesce(saude.complemento, bcadastro.complemento) as complemento,

                -- bairro
                coalesce(saude.bairro, bcadastro.bairro) as bairro,

                -- cidade
                coalesce(saude.cidade, bcadastro.cidade) as cidade,

                -- estado
                coalesce(saude.estado, bcadastro.estado) as estado,

                -- residente_exterior
                coalesce(
                    saude.residente_exterior, bcadastro.residente_exterior
                ) as residente_exterior
            ) as endereco

        from all_cpf as cpfs
        left join endereco_bcadastro as bcadastro on cpfs.cpf = bcadastro.cpf
        left join endereco_saude as saude on cpfs.cpf = saude.cpf
    ),

    -- contato
    telefone_saude as (
        select
            cpf,
            telefone.ddi,
            telefone.ddd,
            telefone.valor,
            telefone.sistema,
            telefone.rank,
            'saude' as source
        from cadastros
        left join unnest(contato.telefone) as telefone
        where telefone.source = 'saude' and telefone.rank = 1
    ),

    telefone_bcadastro as (
        select
            cpf,
            telefone.ddi,
            telefone.ddd,
            telefone.valor,
            telefone.sistema,
            telefone.rank,
            'bcadastro' as source
        from cadastros
        left join unnest(contato.telefone) as telefone
        where telefone.source = 'bcadastro' and telefone.rank = 1
    ),

    telefone as (
        select
            cpfs.cpf,
            struct(
                -- ddi
                case
                    when saude.valor is null then bcadastro.ddi else saude.ddi
                end as ddi,

                -- ddd
                coalesce(saude.ddd, bcadastro.ddd) as ddd,

                -- valor
                coalesce(saude.valor, bcadastro.valor) as valor
            ) as telefone

        from all_cpf as cpfs
        left join telefone_saude as saude on cpfs.cpf = saude.cpf
        left join telefone_bcadastro as bcadastro on cpfs.cpf = bcadastro.cpf

    ),

    email as (
        select cpfs.cpf, email.valor as email
        from all_cpf as cpfs
        left join cadastros as c on cpfs.cpf = c.cpf
        left join unnest(c.contato.email) as email
        where email.source = 'saude' and email.rank = 1
    )

select
    a.cpf,
    c.origens,
    d.nome,
    d.has_nome_social,
    d.data_nascimento,
    d.genero,
    d.raca,
    d.nome_mae,
    d.nome_pai,
    d.ocupacao,
    d.situacao_cadastral,
    e.endereco,
    t.telefone,
    em.email,
    c.saude,
    c.assistencia_social
from all_cpf a
left join dados d on a.cpf = d.cpf
left join endereco e on a.cpf = e.cpf
left join telefone t on a.cpf = t.cpf
left join email em on a.cpf = em.cpf
left join cadastros c on a.cpf = c.cpf
