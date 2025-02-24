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
        select id_municipio_rf, nome as nome_municipio,
        from `basedosdados.br_bd_diretorios_brasil.municipio`
    ),

    tb_parsed as (
        select
            id,
            key,
            json_value(value, '$.rev') as rev,

            json_value(doc, '$._id') as _id,
            json_value(doc, '$._rev') as _rev,

            json_value(doc, '$.cnpj') as cnpj,
            json_value(doc, '$.tipoLogradouro') as tipo_logradouro,
            json_value(doc, '$.cep') as cep,
            json_value(doc, '$.tipoOrgaoRegistro') as tipo_orgao_registro,
            json_value(doc, '$.motivoSituacao') as motivo_situacao,
            json_value(doc, '$.bairro') as bairro,
            json_value(doc, '$.situacaoEspecial') as situacao_especial,
            json_value(doc, '$.situacaoCadastral') as situacao_cadastral,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dataSituacaoCadastral')
            ) as data_situacao_cadastral,
            json_value(doc, '$.codigoPais') as codigo_pais,
            json_value(doc, '$.tipoCrcContadorPF') as tipo_crc_contador_pf,
            json_value(doc, '$.numero') as numero,
            json_value(doc, '$.contadorPJ') as contador_pj,
            json_value(
                doc, '$.classificacaoCrcContadorPF'
            ) as classificacao_crc_contador_pf,
            json_value(doc, '$.complemento') as complemento,
            json_value(doc, '$.logradouro') as logradouro,
            json_value(doc, '$.sequencialCrcContadorPF') as sequencial_crc_contador_pf,
            json_value(doc, '$.contadorPF') as contador_pf,
            json_value(doc, '$.cnaeSecundarias') as cnae_secundarias,
            json_value(doc, '$.email') as email,
            json_value(doc, '$.indicadorMatriz') as indicador_matriz,
            json_value(doc, '$.tiposUnidade') as tipos_unidade,
            json_value(doc, '$.nomeCidadeExterior') as nome_cidade_exterior,
            json_value(doc, '$.uf') as uf,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dataSituacaoEspecial')
            ) as data_situacao_especial,
            json_value(doc, '$.formasAtuacao') as formas_atuacao,
            json_value(doc, '$.nomeFantasia') as nome_fantasia,
            json_value(doc, '$.tipoCrcContadorPJ') as tipo_crc_contador_pj,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dataInicioAtividade')
            ) as data_inicio_atividade,
            json_value(doc, '$.dddTelefone1') as ddd_telefone_1,
            json_value(
                doc, '$.classificacaoCrcContadorPJ'
            ) as classificacao_crc_contador_pj,
            json_value(doc, '$.ufCrcContadorPJ') as uf_crc_contador_pj,
            json_value(doc, '$.codigoMunicipio') as codigo_municipio,
            json_value(doc, '$.ufCrcContadorPF') as uf_crc_contador_pf,
            json_value(doc, '$.telefone1') as telefone_1,
            json_value(doc, '$.telefone2') as telefone_2,
            json_value(doc, '$.sequencialCrcContadorPJ') as sequencial_crc_contador_pj,
            json_value(doc, '$.cpfResponsavel') as cpf_responsavel,
            json_value(doc, '$.qualificacaoResponsavel') as qualificacao_responsavel,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dataInclusaoResponsavel')
            ) as data_inclusao_responsavel,
            json_value(doc, '$.capitalSocial') as capital_social,
            json_value(doc, '$.enteFederativo') as ente_federativo,
            json_value(doc, '$.socios') as socios,
            json_value(doc, '$.dddTelefone2') as ddd_telefone_2,
            json_value(doc, '$.cnaeFiscal') as cnae_fiscal,
            json_value(doc, '$.naturezaJuridica') as natureza_juridica,
            json_value(doc, '$.porteEmpresa') as porte_empresa,
            json_value(doc, '$.nomeEmpresarial') as nome_empresarial,
            json_value(doc, '$.nire') as nire,
            json_value(doc, '$.id') as id_doc,
            json_value(doc, '$.sucessoes') as sucessoes,
            json_value(doc, '$.cnpjSucedida') as cnpj_sucedida,
            json_value(doc, '$.tipo') as tipo,
            json_value(doc, '$.timestamp') as timestamp,
            json_value(doc, '$.language') as language,
            seq,
            last_seq,
            _airbyte_raw_id as airbyte_raw_id,
            _airbyte_extracted_at as airbyte_extracted_at,
            struct(
                json_value(_airbyte_meta, '$.changes') as changes,
                json_value(_airbyte_meta, '$.sync_id') as sync_id
            ) as airbyte_meta,
            _airbyte_generation_id as airbyte_generation_id,
        from tb
    )

select *
from tb_parsed
