{{
    config(
        alias="pessoa_juridica",
        schema="crm_identidade_unica",
        materialized="table",
        partition_by={
            "field": "cnpj_particao",
            "data_type": "int64",
            "range": {"start": 0, "end": 100000000000, "interval": 34722222},
        },
    )
}}


with cnpj_source as (select * from {{ source("bcadastro", "cnpj") }})

select
    -- Primary key
    cnpj,

    -- Business data
    nome_empresarial,
    nome_fantasia,
    capital_social,
    cnae_fiscal,
    cnae_secundarias,
    nire,
    tipo_orgao_registro,
    porte_empresa,
    indicador_matriz,

    -- Dates
    data_inicio_atividade,
    data_situacao_cadastral,
    data_situacao_especial,
    data_inclusao_responsavel,

    -- Status and demographics
    situacao_cadastral,
    natureza_juridica,
    situacao_especial,
    motivo_situacao,
    id_ente_federativo,
    ente_federativo,

    -- Contact
    telefone,
    email,

    -- Address
    endereco_uf,
    endereco_cep,
    endereco_municipio,
    endereco_bairro,
    endereco_tipo_logradouro,
    endereco_logradouro,
    endereco_numero,
    endereco_complemento,
    endereco_nome_cidade_exterior,

    -- Accountant Information
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

    -- Responsible Person
    cpf_responsavel,
    qualificacao_responsavel,

    -- Business arrays
    tipos_unidade,
    formas_atuacao,
    numero_socios,
    socios,
    sucessoes,

    -- Partition
    cnpj_particao

from cnpj_source
