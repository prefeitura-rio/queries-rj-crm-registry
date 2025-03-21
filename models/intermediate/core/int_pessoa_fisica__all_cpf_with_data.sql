-- - Consolidates CPF records from multiple Rio de Janeiro city systems (health,
-- social assistance, citizen services, transportation, and BCadastro) into a unified
-- view with source tracking and counting.
-- This models add data from all sources to the cpf table.


{{
    config(
        partition_by={
            "field": "cpf_particao",
            "data_type": "int64",
            "range": {"start": 0, "end": 100000000000, "interval": 34722222},
        },
    )
}}


with

    -- SOURCES
    all_cpfs as (
        select cpf, cpf_particao, struct(origens_count, origens) as origens
        from {{ ref("int_pessoa_fisica__all_cpf") }}
    ),

    bcadastro_source as (
        select *
        from {{ ref("raw_bcadastro__cpf") }}
        left join all_cpfs using (cpf_particao)
    ),

    sms_source as (
        select *
        from {{ source("rj-sms", "paciente") }}
        left join all_cpfs using (cpf_particao)
    ),

    smas_source as (
        select *
        from {{ source("rj-smas", "cadastros") }}
        left join all_cpfs using (cpf_particao)
    ),

    -- DATA
    bcadastro as (
        select
            b.cpf,
            struct(
                ano_exercicio,
                data_inscricao,
                b.cpf,
                situacao_cadastral,
                nome,
                data_nascimento,
                genero,
                nome_mae,
                telefone_original,
                ddi,
                ddd,
                telefone,
                id_natureza_ocupacao,
                id_ocupacao,
                ocupacao,
                id_ua,
                id_municipio_domicilio,
                municipio_domicilio,
                uf_domicilio,
                id_municipio_nascimento,
                municipio_nascimento,
                uf_nascimento,
                cep,
                bairro,
                tipo_logradouro,
                logradouro,
                complemento,
                numero_logradouro,
                estrangeiro,
                residente_exterior,
                data_ultima_atualizacao,
                email,
                ano_obito,
                id_pais_nascimento,
                nome_pais_nascimento,
                id_pais_residencia,
                nome_pais_residencia,
                nome_social,
                tipo,

                rank
            ) as dados
        from all_cpfs a
        left join bcadastro_source b on a.cpf_particao = b.cpf_particao
        where rank = 1
    ),

    sms as (
        select
            b.cpf, dados, endereco, contato, struct(cns, equipe_saude_familia) as saude
        from all_cpfs a
        left join sms_source b on a.cpf_particao = b.cpf_particao
    ),

    smas as (
        select
            b.cpf,
            dados,
            endereco,
            struct(
                array(
                    select as struct
                        id_membro_familia,
                        id_familia,
                        data_particao,
                        dados.estado_cadastral,
                        dados.condicao_cadastral_familia,
                        dados.estado_cadastral_familia,

                        dados.data_cadastro,
                        dados.data_ultima_atualizacao,
                        dados.data_limite_cadastro_atual_familia,

                        dados.condicao_rua,
                        dados.trabalho_infantil,
                        dados.numero_membros_familia,
                        dados.parentesco_responsavel_familia
                ) as cadastral,
                deficiencia,
                escolaridade,
                renda,
                domicilio,
                membros
            ) as assistencia_social
        from all_cpfs a
        left join smas_source b on a.cpf_particao = b.cpf_particao
        left join unnest(dados) as dados

    ),

    bcadastro_dados as (
        select
            cpf,
            struct(
                dados.situacao_cadastral,
                dados.municipio_nascimento,
                dados.uf_nascimento,
                dados.id_natureza_ocupacao,
                dados.ocupacao,
                dados.id_ua,
                dados.data_ultima_atualizacao
            ) as fazenda
        from bcadastro
    ),

    cadastro_geral as (
        select
            cpf,
            dados.nome as nome,
            dados.nome_social as nome_social,
            dados.data_nascimento as data_nascimento,
            dados.obito_indicador,
            dados.genero as genero,
            dados.raca as raca,
            dados.mae_nome as nome_mae,
            dados.pai_nome as nome_pai,
            null as data_ultima_atualizacao,
            cast(null as bool) as estrangeiro,
            1 as rank,
            'saude' as source
        from sms
        union all
        select
            cpf,
            dados.nome as nome,
            null as nome_social,
            dados.data_nascimento as data_nascimento,
            null as obito_indicador,
            lower(dados.sexo) as genero,
            lower(dados.raca_cor) as raca,
            dados.nome_mae as nome_mae,
            dados.nome_pai as nome_pai,
            dados.data_ultima_atualizacao as data_ultima_atualizacao,
            cast(null as bool) as estrangeiro,
            1 as rank,
            'cadunico' as source
        from smas
        union all
        select
            cpf,
            dados.nome as nome,
            dados.nome_social as nome_social,
            dados.data_nascimento as data_nascimento,
            case
                when
                    (dados.situacao_cadastral = 'Titular Falecido')
                    or (dados.ano_obito is not null)
                then true
                else false
            end as obito_indicador,
            dados.genero as genero,
            null as raca,
            dados.nome_mae as nome_mae,
            null as nome_pai,
            dados.data_ultima_atualizacao as data_ultima_atualizacao,
            dados.estrangeiro as estrangeiro,

            dados.rank,
            'bcadastro' as source
        from bcadastro
    ),

    cadastro as (
        select
            cpf,
            array_agg(
                struct(
                    source,
                    rank,
                    nome,
                    nome_social,
                    data_nascimento,
                    obito_indicador,
                    genero,
                    raca,
                    nome_mae,
                    nome_pai,
                    data_ultima_atualizacao,
                    estrangeiro
                )
            ) as dados
        from cadastro_geral
        group by cpf
    ),

    -- ENDERECO
    endereco_geral as (
        select
            cpf,
            endereco.estado as estado,
            endereco.cidade as municipio,

            endereco.cep as cep,
            endereco.tipo_logradouro as tipo_logradouro,
            endereco.logradouro as logradouro,
            endereco.numero as numero,
            endereco.complemento as complemento,
            endereco.bairro as bairro,

            cast(null as bool) as residente_exterior,
            endereco.sistema as sistema,
            endereco.rank as rank,
            'saude' as source
        from sms, unnest(endereco) endereco
        union all
        select
            cpf,
            endereco.sigla_uf as estado,
            endereco.nome_municipio as municipio,

            endereco.cep as cep,
            endereco.tipo_logradouro as tipo_logradouro,
            endereco.logradouro as logradouro,
            cast(endereco.numero_logradouro as string) as numero,
            endereco.complemento as complemento,
            endereco.localidade as bairro,
            cast(null as bool) as residente_exterior,
            null as sistema,
            1 as rank,
            'cadunico' as source
        from smas, unnest(endereco) endereco
        union all
        select
            cpf as cpf,
            dados.uf_domicilio as estado,
            dados.municipio_domicilio as municipio,

            dados.cep as cep,
            dados.tipo_logradouro as tipo_logradouro,
            dados.logradouro as logradouro,
            dados.numero_logradouro as numero,
            dados.complemento as complemento,
            dados.bairro as bairro,

            dados.residente_exterior as residente_exterior,
            null as sistema,
            dados.rank,
            'bcadastro' as source
        from bcadastro

    ),

    endereco as (
        select
            cpf,
            array_agg(
                struct(
                    source,
                    rank,
                    estado,
                    municipio,
                    cep,
                    lower(tipo_logradouro) as tipo_logradouro,
                    logradouro,
                    numero,
                    complemento,
                    bairro,

                    residente_exterior,
                    sistema
                )
            ) as endereco
        from endereco_geral
        group by cpf
    ),

    -- CONTATO - TELEFONE
    contato_geral_telefone as (
        select
            cpf,
            null as ddi,
            telefone.ddd as ddd,
            telefone.valor as valor,
            telefone.sistema,
            telefone.rank,
            'saude' as source
        from sms, unnest(contato.telefone) as telefone
        union all
        select
            cpf,
            dados.ddi as ddi,
            dados.ddd as ddd,
            dados.telefone as valor,
            null as sistema,
            dados.rank,
            'bcadastro' as source
        from bcadastro
    ),
    contato_telefone as (
        select
            cpf, array_agg(struct(source, rank, ddi, ddd, valor, sistema)) as telefone
        from contato_geral_telefone
        group by cpf
    ),

    contato_geral_email as (
        select cpf, email.valor as valor, email.sistema, email.rank, 'saude' as source
        from sms, unnest(contato.email) as email
        union all
        select
            cpf,
            dados.email as valor,
            null as sistema,
            dados.rank,
            'bcadastro' as source
        from bcadastro
    ),

    -- CONTATO - EMAIL
    contato_email as (
        select cpf, array_agg(struct(source, rank, valor, sistema)) as email
        from contato_geral_email
        group by cpf
    ),

    -- CONTATO - CONSOLIDADO
    contato as (
        select a.cpf, struct(t.telefone, e.email) contato
        from all_cpfs a
        left join contato_telefone t on a.cpf = t.cpf
        left join contato_email e on a.cpf = e.cpf
    )

select
    a.cpf,
    a.origens,
    ca.dados,
    e.endereco,
    co.contato,
    s.saude,
    c.assistencia_social,
    bd.fazenda,
    cast(a.cpf as int64) as cpf_particao
from all_cpfs a
left join cadastro ca on a.cpf = ca.cpf
left join endereco e on a.cpf = e.cpf
left join contato co on a.cpf = co.cpf
left join sms s on a.cpf = s.cpf
left join smas c on a.cpf = c.cpf
left join bcadastro_dados bd on a.cpf = bd.cpf
