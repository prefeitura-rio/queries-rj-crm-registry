-- - Consolidates CPF records from multiple Rio de Janeiro city systems (health,
-- social assistance, citizen services, transportation, and BCadastro) into a unified
-- view with source tracking and counting.
-- This models add data from all sources to the cpf table.
{{
    config(
        alias="cpf_data",
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

    -- SOURCES
    all_cpfs as (
        select cpf, cpf_particao, struct(origens_count, origens) as origens
        from {{ ref("int_pessoa_fisica__all_cpf") }}
    {# where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
    ),

    bcadastro_source as (
        select b.*
        from all_cpfs a
        left join {{ source("bcadastro", "cpf") }} b using (cpf_particao)
    ),

    sms_source as (
        select b.*
        from all_cpfs a
        left join {{ source("rj-sms", "paciente") }} b using (cpf_particao)
    ),

    smas_source as (
        select b.*
        from all_cpfs a
        left join {{ source("rj-smas", "cadastros") }} b using (cpf_particao)

    ),

    -- DATA
    dados_cnpj as (
        select cpf, array_agg(cnpj) as cnpjs
        from
            (
                select
                    a.cnpj,
                    case
                        when s.cpf_socio is null
                        then s.cpf_representante_legal
                        else s.cpf_socio
                    end as cpf
                from {{ ref("dim_pessoa_juridica") }} a, unnest(socios) s
            )
        group by cpf
    ),

    bcadastro as (
        select
            cpf,
            struct(
                ano_exercicio,
                inscricao_data,
                cpf,
                situacao_cadastral_tipo,
                nome,
                nascimento_data,
                sexo,
                mae_nome,
                telefone_ddi,
                telefone_ddd,
                telefone_numero,
                id_natureza_ocupacao,
                id_ocupacao,
                ocupacao_nome,
                id_ua,
                id_municipio_domicilio,
                endereco_municipio,
                endereco_uf,
                id_nascimento_municipio,
                nascimento_municipio,
                nascimento_uf,
                endereco_cep,
                endereco_bairro,
                endereco_tipo_logradouro,
                endereco_logradouro,
                endereco_complemento,
                endereco_numero,
                estrangeiro_indicador,
                residente_exterior_indicador,
                atualizacao_data,
                email,
                obito_ano,
                id_pais_nascimento,
                nascimento_pais,
                id_pais_residencia,
                residencia_pais,
                nome_social,
                tipo
            -- Unused columns after first select:
            -- telefone_original,  -- removed (split into components)
            -- rank (used internally but not in final output)
            -- telefone_original (replaced by components)
            -- nome_pai (not in new schema)
            -- raca (not in new schema)
            -- obito_indicador (replaced by obito_ano)
            -- sistema (internal)
            -- version (internal)
            -- timestamp (internal)
            -- airbyte (internal)
            ) as dados
        from bcadastro_source
    ),

    sms as (
        select cpf, dados, endereco, contato, cns, struct(equipe_saude_familia) as saude
        from sms_source
    ),

    smas as (
        select
            cpf,
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
        from smas_source
        left join unnest(dados) as dados

    ),

    bcadastro_dados as (
        select
            cpf,
            struct(
                dados.situacao_cadastral_tipo,
                dados.nascimento_municipio,
                dados.nascimento_uf,
                dados.id_natureza_ocupacao,
                dados.ocupacao_nome,
                dados.id_ua,
                dados.atualizacao_data
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
            dados.nascimento_data as data_nascimento,
            case
                when
                    (dados.situacao_cadastral_tipo = 'Titular Falecido')
                    or (dados.obito_ano is not null)
                then true
                else false
            end as obito_indicador,
            dados.sexo as genero,
            null as raca,
            dados.mae_nome as nome_mae,
            null as nome_pai,
            dados.atualizacao_data as data_ultima_atualizacao,
            dados.estrangeiro_indicador as estrangeiro,

            1 as rank,
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
            dados.endereco_uf as estado,
            dados.endereco_municipio as municipio,

            dados.endereco_cep as cep,
            dados.endereco_tipo_logradouro as tipo_logradouro,
            dados.endereco_logradouro as logradouro,
            dados.endereco_numero as numero,
            dados.endereco_complemento as complemento,
            dados.endereco_bairro as bairro,

            dados.residente_exterior_indicador as residente_exterior,
            null as sistema,
            1 as rank,
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
            dados.telefone_ddi as ddi,
            dados.telefone_ddd as ddd,
            dados.telefone_numero as valor,
            null as sistema,
            1 as rank,
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
            cpf, dados.email as valor, null as sistema, 1 as rank, 'bcadastro' as source
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
    ),

    documentos as (
        select cpf, array_agg(struct(cns)) as documentos from sms group by cpf
    )
select
    a.cpf,
    a.origens,
    ca.dados,
    doc.documentos,
    e.endereco,
    co.contato,
    dc.cnpjs,
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
left join documentos doc on a.cpf = doc.cpf
left join dados_cnpj dc on a.cpf = dc.cpf
