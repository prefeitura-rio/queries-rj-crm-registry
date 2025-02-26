with
    tb as (
        select
            _airbyte_raw_id,
            _airbyte_extracted_at,
            _airbyte_meta,
            _airbyte_generation_id,
            id,
            doc,
            key,
            seq,
            value,
            last_seq
        from `rj-crm-registry.brutos_bcadastro_staging.chcnpj_bcadastros`
        where timestamp_trunc(_airbyte_extracted_at, day) = timestamp("2025-02-24")
    ),

    municipio_bd as (
        select id_municipio_rf, nome as nome_municipio
        from `basedosdados.br_bd_diretorios_brasil.municipio`
    ),

    sigla_uf_bd as (select sigla from `basedosdados.br_bd_diretorios_brasil.uf`),

    dominio as (
        select id, descricao, column
        from `rj-crm-registry.dados_mestres.dominio_bcadastro`
        where source = 'cnpj'
    ),

    tb_parsed as (
        select
            id,
            key,
            nullif(json_value(value, '$.rev'), "") as rev,

            nullif(json_value(doc, '$._id'), "") as _id,
            nullif(json_value(doc, '$._rev'), "") as _rev,

            nullif(json_value(doc, '$.cnpj'), "") as cnpj,
            nullif(json_value(doc, '$.tipoLogradouro'), "") as tipo_logradouro,
            nullif(json_value(doc, '$.cep'), "") as cep,
            nullif(
                json_value(doc, '$.tipoOrgaoRegistro'), ""
            ) as id_tipo_orgao_registro,
            cast(
                cast(nullif(json_value(doc, '$.motivoSituacao'), "") as int64) as string
            ) as id_motivo_situacao,
            nullif(json_value(doc, '$.bairro'), "") as bairro,
            nullif(json_value(doc, '$.situacaoEspecial'), "") as situacao_especial,
            cast(
                cast(
                    nullif(json_value(doc, '$.situacaoCadastral'), "") as int64
                ) as string
            ) as id_situacao_cadastral,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dataSituacaoCadastral'), "")
            ) as data_situacao_cadastral,
            nullif(json_value(doc, '$.codigoPais'), "") as id_pais,
            nullif(json_value(doc, '$.tipoCrcContadorPF'), "") as tipo_crc_contador_pf,
            nullif(json_value(doc, '$.numero'), "") as numero,
            nullif(json_value(doc, '$.contadorPJ'), "") as contador_pj,
            nullif(
                json_value(doc, '$.classificacaoCrcContadorPF'), ""
            ) as classificacao_crc_contador_pf,
            nullif(json_value(doc, '$.complemento'), "") as complemento,
            nullif(json_value(doc, '$.logradouro'), "") as logradouro,
            nullif(
                json_value(doc, '$.sequencialCrcContadorPF'), ""
            ) as sequencial_crc_contador_pf,
            nullif(json_value(doc, '$.contadorPF'), "") as contador_pf,
            nullif(json_value(doc, '$.cnaeSecundarias'), "") as cnae_secundarias,
            nullif(json_value(doc, '$.email'), "") as email,
            cast(
                cast(
                    nullif(json_value(doc, '$.indicadorMatriz'), "") as int64
                ) as string
            ) as id_indicador_matriz,
            nullif(json_value(doc, '$.tiposUnidade'), "") as tipos_unidade,
            nullif(json_value(doc, '$.nomeCidadeExterior'), "") as nome_cidade_exterior,
            nullif(json_value(doc, '$.uf'), "") as uf,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dataSituacaoEspecial'), "")
            ) as data_situacao_especial,
            nullif(json_value(doc, '$.formasAtuacao'), "") as formas_atuacao,
            nullif(json_value(doc, '$.nomeFantasia'), "") as nome_fantasia,
            nullif(json_value(doc, '$.tipoCrcContadorPJ'), "") as tipo_crc_contador_pj,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dataInicioAtividade'), "")
            ) as data_inicio_atividade,
            nullif(json_value(doc, '$.dddTelefone1'), "") as ddd_telefone_1,
            nullif(
                json_value(doc, '$.classificacaoCrcContadorPJ'), ""
            ) as classificacao_crc_contador_pj,
            nullif(json_value(doc, '$.ufCrcContadorPJ'), "") as uf_crc_contador_pj,
            nullif(json_value(doc, '$.codigoMunicipio'), "") as id_municipio,
            nullif(json_value(doc, '$.ufCrcContadorPF'), "") as uf_crc_contador_pf,
            nullif(json_value(doc, '$.telefone1'), "") as telefone_1,
            nullif(json_value(doc, '$.telefone2'), "") as telefone_2,
            nullif(
                json_value(doc, '$.sequencialCrcContadorPJ'), ""
            ) as sequencial_crc_contador_pj,
            nullif(json_value(doc, '$.cpfResponsavel'), "") as cpf_responsavel,

            cast(
                cast(
                    nullif(json_value(doc, '$.qualificacaoResponsavel'), "") as int64
                ) as string
            ) as id_qualificacao_responsavel,

            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dataInclusaoResponsavel'), "")
            ) as data_inclusao_responsavel,
            nullif(json_value(doc, '$.capitalSocial'), "") as capital_social,
            case
                when regexp_contains(json_value(doc, '$.enteFederativo'), r'^[0-9]+$')
                then
                    cast(
                        cast(
                            nullif(json_value(doc, '$.enteFederativo'), '') as int64
                        ) as string
                    )
                else upper(nullif(json_value(doc, '$.enteFederativo'), ''))
            end as id_ente_federativo,
            nullif(json_value(doc, '$.socios'), "") as socios,
            nullif(json_value(doc, '$.dddTelefone2'), "") as ddd_telefone_2,
            nullif(json_value(doc, '$.cnaeFiscal'), "") as cnae_fiscal,
            cast(
                cast(
                    nullif(json_value(doc, '$.naturezaJuridica'), "") as int64
                ) as string
            ) as id_natureza_juridica,
            cast(
                cast(nullif(json_value(doc, '$.porteEmpresa'), "") as int64) as string
            ) as id_porte_empresa,
            nullif(json_value(doc, '$.nomeEmpresarial'), "") as nome_empresarial,
            nullif(json_value(doc, '$.nire'), "") as nire,
            nullif(json_value(doc, '$.id'), "") as id_doc,
            nullif(json_value(doc, '$.sucessoes'), "") as sucessoes,
            nullif(json_value(doc, '$.cnpjSucedida'), "") as cnpj_sucedida,
            nullif(json_value(doc, '$.tipo'), "") as tipo,
            nullif(json_value(doc, '$.timestamp'), "") as timestamp,
            nullif(json_value(doc, '$.language'), "") as language,
            nullif(
                json_value(replace(to_json_string(doc), '~', ''), '$.version'), ""
            ) as version,
            seq,
            last_seq,
            _airbyte_raw_id as airbyte_raw_id,
            _airbyte_extracted_at as airbyte_extracted_at,
            struct(
                nullif(json_value(_airbyte_meta, '$.changes'), "") as changes,
                nullif(json_value(_airbyte_meta, '$.sync_id'), "") as sync_id
            ) as airbyte_meta,
            _airbyte_generation_id as airbyte_generation_id,
        from tb
    ),

    tb_intermediate as (
        select
            t.id,
            t.key,
            t.rev,
            t._id,
            t._rev,
            t.cnpj,
            t.tipo_logradouro,
            t.cep,
            t.id_tipo_orgao_registro,
            org.descricao as tipo_orgao_registro,
            t.bairro,
            t.id_motivo_situacao,
            ms.descricao as motivo_situacao,
            t.id_situacao_cadastral,
            sc.descricao as situacao_cadastral,
            t.situacao_especial,
            t.data_situacao_cadastral,
            t.id_pais,
            t.tipo_crc_contador_pf,
            t.numero,
            t.contador_pj,
            t.classificacao_crc_contador_pf,
            t.complemento,
            t.logradouro,
            t.sequencial_crc_contador_pf,
            t.contador_pf,
            t.cnae_secundarias,
            t.email,
            t.id_indicador_matriz,
            im.descricao as indicador_matriz,
            t.tipos_unidade,
            t.nome_cidade_exterior,
            t.uf,
            t.data_situacao_especial,
            t.formas_atuacao,
            t.nome_fantasia,
            t.tipo_crc_contador_pj,
            t.data_inicio_atividade,
            t.ddd_telefone_1,
            t.classificacao_crc_contador_pj,
            t.uf_crc_contador_pj,
            t.id_municipio,
            md.nome_municipio as municipio,
            t.uf_crc_contador_pf,
            t.telefone_1,
            t.telefone_2,
            t.sequencial_crc_contador_pj,
            t.cpf_responsavel,
            t.id_qualificacao_responsavel,
            qr.descricao as qualificacao_responsavel,
            t.data_inclusao_responsavel,
            t.capital_social,
            t.id_ente_federativo,
            case
                when id_ente_federativo = 'BR'
                then 'União'
                when regexp_contains(id_ente_federativo, r'^[0-9]+$')
                then 'Município'
                when
                    upper(id_ente_federativo)
                    in (select upper(id_ente_federativo) from sigla_uf_bd)
                then 'Estado'
                else null
            end as ente_federativo,
            t.socios,
            t.ddd_telefone_2,
            t.cnae_fiscal,
            t.id_natureza_juridica,
            nj.descricao as natureza_juridica,
            t.id_porte_empresa,
            pe.descricao as porte_empresa,
            t.nome_empresarial,
            t.nire,
            t.id_doc,
            t.sucessoes,
            t.cnpj_sucedida,
            t.tipo,
            t.timestamp,
            t.language,
            t.version,
            t.seq,
            t.last_seq,
            t.airbyte_raw_id,
            t.airbyte_extracted_at,
            t.airbyte_meta,
            t.airbyte_generation_id,
            cast(t.cnpj as int64) as cnpj_particao
        from tb_parsed t
        left join
            municipio_bd as md
            on cast(t.id_municipio as int64) = cast(md.id_municipio_rf as int64)
        left join
            (
                select id as id_situacao_cadastral, descricao
                from dominio
                where column = 'situacao_cadastral'
            ) sc
            on t.id_situacao_cadastral = sc.id_situacao_cadastral
        left join
            (
                select id as id_motivo_situacao, descricao
                from dominio
                where column = 'motivo_situacao_cadastral'
            )
            ms on t.id_motivo_situacao = ms.id_motivo_situacao
        left join
            (
                select id as id_tipo_orgao_registro, descricao
                from dominio
                where column = 'tipo_orgao_registro'
            )
            org on t.id_tipo_orgao_registro = org.id_tipo_orgao_registro
        left join
            (
                select id as id_natureza_juridica, descricao
                from dominio
                where column = 'natureza_juridica'
            )
            nj on t.id_natureza_juridica = nj.id_natureza_juridica
        left join
            (
                select id as id_porte_empresa, descricao
                from dominio
                where column = 'porte_empresa'
            )
            pe on t.id_porte_empresa = pe.id_porte_empresa
        left join
            (
                select id as id_indicador_matriz, descricao
                from dominio
                where column = 'indicador_matriz'
            )
            im on t.id_indicador_matriz = im.id_indicador_matriz
        left join
            (
                select id as id_qualificacao_responsavel, descricao
                from dominio
                where column = 'qualificacao_responsavel'
            )
            qr on t.id_qualificacao_responsavel = qr.id_qualificacao_responsavel
    ),

    tb_padronize as (
        select
            t.id,
            t.key,
            t.rev,
            t._id,
            t._rev,
            t.cnpj,

            -- Localidade
            t.id_pais,
            t.id_municipio,
            {{ proper_br("municipio") }} as municipio,
            t.cep,
            {{ proper_br("tipo_logradouro") }} as tipo_logradouro,
            {{ proper_br("bairro") }} as bairro,
            {{ proper_br("logradouro") }} as logradouro,
            t.numero,
            {{ proper_br("complemento") }} as complemento,
            t.uf,
            t.nome_cidade_exterior,

            -- Informações Cadastrais
            t.id_tipo_orgao_registro,
            {{ proper_br("tipo_orgao_registro") }} as tipo_orgao_registro,
            t.id_motivo_situacao,
            {{ proper_br("motivo_situacao") }} as motivo_situacao,
            t.id_situacao_cadastral,
            {{ proper_br("situacao_cadastral") }} as situacao_cadastral,
            t.data_situacao_cadastral,
            {{ proper_br("situacao_especial") }} as situacao_especial,
            t.data_situacao_especial,
            t.data_inicio_atividade,

            -- Contato
            t.ddd_telefone_1,
            t.telefone_1,
            t.ddd_telefone_2,
            t.telefone_2,
            t.email,

            -- Informações do Contador
            t.tipo_crc_contador_pf,
            t.contador_pj,
            t.classificacao_crc_contador_pf,
            t.sequencial_crc_contador_pf,
            t.contador_pf,
            t.tipo_crc_contador_pj,
            t.classificacao_crc_contador_pj,
            t.uf_crc_contador_pj,
            t.uf_crc_contador_pf,
            t.sequencial_crc_contador_pj,

            -- Informações do Responsável
            t.cpf_responsavel,
            t.id_qualificacao_responsavel,
            {{ proper_br("qualificacao_responsavel") }} as qualificacao_responsavel,
            t.data_inclusao_responsavel,

            -- Informações da Empresa
            t.id_indicador_matriz,
            {{ proper_br("indicador_matriz") }} as indicador_matriz,
            t.tipos_unidade,
            t.formas_atuacao,
            {{ proper_br("nome_fantasia") }} as nome_fantasia,
            t.capital_social,
            t.id_ente_federativo,
            {{ proper_br("ente_federativo") }} as ente_federativo,
            t.socios,
            t.cnae_fiscal,
            t.cnae_secundarias,
            t.id_natureza_juridica,
            {{ proper_br("natureza_juridica") }} as natureza_juridica,
            t.id_porte_empresa,
            {{ proper_br("porte_empresa") }} as porte_empresa,
            {{ proper_br("nome_empresarial") }} as nome_empresarial,
            t.nire,
            t.cnpj_sucedida,
            t.sucessoes,

            t.id_doc,
            t.tipo,
            t.timestamp,
            t.language,
            t.version,

            -- Metadados
            t.seq,
            t.last_seq,
            t.airbyte_raw_id,
            t.airbyte_extracted_at,
            t.airbyte_meta,
            t.airbyte_generation_id,
            row_number() over (
                partition by t.cnpj order by t.data_situacao_cadastral desc
            ) as rank,

            t.cnpj_particao
        from tb_intermediate t
    )

select
    -- Identificadores Únicos
    id,
    key,
    rev,
    _id,
    _rev,
    cnpj,
    id_doc,

    -- Localidade
    id_pais,
    id_municipio,
    municipio,
    cep,
    tipo_logradouro,
    bairro,
    logradouro,
    numero,
    complemento,
    uf,
    nome_cidade_exterior,

    -- Informações Cadastrais
    id_tipo_orgao_registro,
    tipo_orgao_registro,
    id_motivo_situacao,
    motivo_situacao,
    id_situacao_cadastral,
    situacao_cadastral,
    data_situacao_cadastral,
    situacao_especial,
    data_situacao_especial,
    data_inicio_atividade,

    -- Contato | TODO padronizar separando em ddi, ddd e telefone
    ddd_telefone_1,
    telefone_1,
    ddd_telefone_2,
    telefone_2,
    email,

    -- Informações do Contador
    tipo_crc_contador_pf,
    contador_pj,
    classificacao_crc_contador_pf,
    sequencial_crc_contador_pf,
    contador_pf,
    tipo_crc_contador_pj,
    classificacao_crc_contador_pj,
    uf_crc_contador_pj,
    uf_crc_contador_pf,
    sequencial_crc_contador_pj,

    -- Informações do Responsável
    cpf_responsavel,
    id_qualificacao_responsavel,
    qualificacao_responsavel,
    data_inclusao_responsavel,

    -- Informações da Empresa
    id_indicador_matriz,
    indicador_matriz,
    tipos_unidade,
    formas_atuacao,
    nome_fantasia,
    capital_social,
    id_ente_federativo,
    ente_federativo,
    socios,
    cnae_fiscal,
    cnae_secundarias,
    id_natureza_juridica,
    natureza_juridica,
    id_porte_empresa,
    porte_empresa,
    nome_empresarial,
    nire,
    cnpj_sucedida,
    sucessoes,

    -- Metadados
    tipo,
    timestamp,
    language,
    version,
    seq,
    last_seq,
    airbyte_raw_id,
    airbyte_extracted_at,
    airbyte_meta,
    airbyte_generation_id,
    rank,
    cnpj_particao
from tb_padronize
