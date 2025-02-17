{{
    config(
        alias="cpf",
    )
}}

with
    fonte as (
        select *
        from {{ source("brutos_bcadastro_staging", "chcpf_bcadastros") }}

        {% if target.name == "dev" %}
            where
                timestamp(_airbyte_extracted_at)
                >= timestamp_sub(current_timestamp(), interval 3 day)
        {% endif %}
    ),

    municipio_bd as (
        select id_municipio_rf, nome as municipio_nome
        from {{ source("br_bd_diretorios_brasil", "municipio") }}
    ),

    ocupacoes as (
        select cast(id_ocupacao as string) as id_ocupacao, descricao
        from {{ ref("ocupacoes_receita_federal") }}
    ),

    fonte_parseada as (
        select
            id,
            key,
            json_value(value, '$.rev') as rev,

            json_value(doc, '$._id') as _id,
            json_value(doc, '$._rev') as _rev,

            cast(json_value(doc, '$.anoExerc') as int64) as ano_exercicio,
            json_value(doc, '$.bairro') as endereco_bairro,
            json_value(doc, '$.cep') as endereco_cep,
            json_value(doc, '$.codMunDomic') as id_municipio_domicilio,
            json_value(doc, '$.codMunNat') as id_municipio_nascimento,
            json_value(doc, '$.codNatOcup') as id_natureza_ocupacao,
            json_value(doc, '$.codOcup') as id_ocupacao,
            json_value(doc, '$.codSexo') as id_sexo,
            json_value(doc, '$.codSitCad') as id_situacao_cadastral,
            json_value(doc, '$.codUA') as id_ua,
            json_value(doc, '$.complemento') as endereco_complemento,
            json_value(doc, '$.cpfId') as cpf,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dtInscricao')
            ) as inscricao_data,
            safe.parse_date('%Y%m%d', json_value(doc, '$.dtNasc')) as nascimento_data,
            safe.parse_date(
                '%Y%m%d', json_value(doc, '$.dtUltAtualiz')
            ) as atualizacao_data,
            json_value(doc, '$.indEstrangeiro') as estrangeiro_indicador,
            json_value(doc, '$.indResExt') as residente_exterior_indicador,
            json_value(doc, '$.logradouro') as endereco_logradouro,
            json_value(doc, '$.nomeContribuinte') as nome,
            json_value(doc, '$.nomeMae') as mae_nome,
            json_value(doc, '$.nroLogradouro') as endereco_numero,
            json_value(doc, '$.telefone') as telefone,
            json_value(doc, '$.tipoLogradouro') as endereco_tipo_logradouro,
            json_value(doc, '$.ufMunDomic') as endereco_uf,
            json_value(doc, '$.ufMunNat') as nascimento_uf,
            json_value(replace(to_json_string(doc), '~', ''), '$.version') as version,

            json_value(doc, '$.email') as email,
            json_value(doc, '$.anoObito') as obito_ano,
            json_value(doc, '$.codPaisNac') as id_pais_nascimento,
            json_value(doc, '$.nomePaisNac') as nascimento_pais,
            json_value(doc, '$.codPaisRes') as id_pais_residencia,
            json_value(doc, '$.nomePaisRes') as residencia_pais,
            json_value(doc, '$.nomeSocial') as nome_social,
            json_value(doc, '$.tipo') as tipo,
            json_value(doc, '$.timestamp') as timestamp,
            json_value(doc, '$.id') as id_doc,

            seq,
            last_seq,

            _airbyte_raw_id as airbyte_raw_id,
            _airbyte_extracted_at as airbyte_extracted_at,
            struct(
                json_value(_airbyte_meta, '$.changes') as changes,
                json_value(_airbyte_meta, '$.sync_id') as sync_id
            ) as airbyte_meta,
            _airbyte_generation_id as airbyte_generation_id,
        from fonte
    ),

    fonte_intermediaria as (
        select
            id,
            _id,
            key,
            rev,
            _rev,
            ano_exercicio,
            endereco_bairro,
            endereco_cep,
            id_municipio_domicilio,
            md.municipio_nome as endereco_municipio,
            id_municipio_nascimento,
            mn.municipio_nome as nascimento_municipio,
            id_natureza_ocupacao,
            t.id_ocupacao,
            o.descricao as ocupacao_nome,
            case
                id_sexo
                when '1'
                then 'masculino'
                when '2'
                then 'feminino'
                when '9'
                then 'nao_informado'
                else id_sexo
            end as sexo,
            case
                id_situacao_cadastral
                when '0'
                then 'regular'
                when '2'
                then 'suspensa'
                when '3'
                then 'titular_falecido'
                when '4'
                then 'pendente_regularizacao'
                when '5'
                then 'cancelada_multiplicidade'
                when '8'
                then 'nula'
                when '9'
                then 'cancelada_oficio'
                else id_situacao_cadastral
            end as situacao_cadastral_tipo,
            id_ua,
            endereco_complemento,
            cpf,
            inscricao_data,
            nascimento_data,
            atualizacao_data,
            case
                estrangeiro_indicador when 'N' then false when 'S' then true else null
            end as estrangeiro_indicador,
            case
                residente_exterior_indicador
                when 'S'
                then true
                when 'N'
                then false
                else null
            end as residente_exterior_indicador,
            endereco_logradouro,
            nome,
            mae_nome,
            endereco_numero,
            telefone,
            endereco_tipo_logradouro,
            endereco_uf,
            nascimento_uf,
            version,

            email,
            obito_ano,
            id_pais_nascimento,
            nascimento_pais,
            id_pais_residencia,
            residencia_pais,
            nome_social,
            tipo,
            timestamp,
            id_doc,

            seq,
            last_seq,

            airbyte_raw_id,
            airbyte_extracted_at,
            airbyte_meta,
            airbyte_generation_id,

            cast(cpf as int64) as cpf_particao
        from fonte_parseada t
        left join
            municipio_bd as md
            on cast(t.id_municipio_domicilio as int64)
            = cast(md.id_municipio_rf as int64)
        left join
            municipio_bd as mn
            on cast(t.id_municipio_nascimento as int64)
            = cast(mn.id_municipio_rf as int64)
        left join ocupacoes as o on t.id_ocupacao = o.id_ocupacao
    ),

    fonte_padronizada as (
        select
            id,
            _id,
            key,
            rev,
            _rev,
            ano_exercicio,
            inscricao_data,
            cpf,
            situacao_cadastral_tipo,
            {{ proper_br("nome") }} as nome,
            nascimento_data,
            sexo,
            {{ proper_br("mae_nome") }} as mae_nome,

            telefone as telefone_original,
            case
                when regexp_contains(telefone, r'\+')
                then regexp_extract(telefone, r'\+([^\s]+)')
                else null
            end as telefone_ddi,
            case
                when regexp_contains(telefone, r'\(')
                then regexp_extract(telefone, r'\(([^\)]+)\)')
                else null
            end as telefone_ddd,
            case
                when telefone is not null
                then
                    if(
                        strpos(reverse(regexp_replace(telefone, r'-', '')), ' ') > 0,
                        substr(
                            regexp_replace(telefone, r'-', ''),
                            length(telefone) - strpos(reverse(telefone), ' ') + 1
                        ),
                        regexp_replace(telefone, r'-', '')
                    )
                else null
            end as telefone_numero,

            id_natureza_ocupacao,
            id_ocupacao,
            {{ proper_br("ocupacao_nome") }} as ocupacao_nome,
            id_ua,

            id_municipio_domicilio,
            {{ proper_br("endereco_municipio") }} as endereco_municipio,
            lower(endereco_uf) as endereco_uf,
            id_municipio_nascimento,
            {{ proper_br("nascimento_municipio") }} as nascimento_municipio,
            lower(nascimento_uf) as nascimento_uf,

            endereco_cep,
            {{ proper_br("endereco_bairro") }} as endereco_bairro,
            {{ proper_br("endereco_tipo_logradouro") }} as endereco_tipo_logradouro,
            {{ proper_br("endereco_logradouro") }} as endereco_logradouro,
            {{ proper_br("endereco_complemento") }} as endereco_complemento,
            endereco_numero,
            estrangeiro_indicador,
            residente_exterior_indicador,
            atualizacao_data,
            version,

            email,
            obito_ano,
            id_pais_nascimento,
            nascimento_pais,
            id_pais_residencia,
            residencia_pais,
            {{ proper_br("nome_social") }} as nome_social,
            tipo,
            timestamp,
            id_doc,

            row_number() over (partition by cpf order by atualizacao_data desc) as rank,

            seq,
            last_seq,

            airbyte_raw_id,
            airbyte_extracted_at,
            airbyte_meta,
            airbyte_generation_id,

            cpf_particao
        from fonte_intermediaria
    ),

    final as (

        select
            -- Primary key
            cpf,

            -- Foreign keys
            id_municipio_domicilio,
            id_municipio_nascimento,
            id_pais_nascimento,
            id_pais_residencia,
            id_natureza_ocupacao,
            id_ocupacao,
            id_ua,

            -- Person data
            nome,
            nome_social,
            mae_nome,

            -- Dates
            nascimento_data,
            inscricao_data,
            atualizacao_data,

            -- Status and demographics
            situacao_cadastral_tipo,
            sexo,
            obito_ano,
            estrangeiro_indicador,
            residente_exterior_indicador,

            -- Contact
            telefone_ddi,
            telefone_ddd,
            telefone_numero,
            email,

            -- Address
            endereco_cep,
            endereco_uf,
            endereco_municipio,
            endereco_bairro,
            endereco_tipo_logradouro,
            endereco_logradouro,
            endereco_numero,
            endereco_complemento,

            -- Birth and residence
            nascimento_uf,
            nascimento_municipio,
            nascimento_pais,
            residencia_pais,

            -- Occupation
            ocupacao_nome,

            -- Metadata
            ano_exercicio,
            version,
            tipo,
            timestamp,

            -- Technical fields
            seq,
            last_seq,
            airbyte_raw_id,
            airbyte_extracted_at,
            airbyte_meta,
            airbyte_generation_id,

            -- Partition
            cpf_particao
        from fonte_padronizada
    )

select *
from final
