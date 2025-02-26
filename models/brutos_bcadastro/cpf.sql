CREATE OR REPLACE TABLE `rj-crm-registry.brutos_bcadastro.cpf` 
PARTITION BY
  RANGE_BUCKET(cpf_particao, GENERATE_ARRAY(0, 100000000000, 34722222))
  CLUSTER BY municipio_domicilio
  AS

(
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
        from `rj-crm-registry.brutos_bcadastro_staging.chcpf_bcadastros`
{# where timestamp_trunc(_airbyte_extracted_at, day) = timestamp("2025-02-24") #}
    ),

    municipio_bd as (
        select id_municipio_rf, nome as nome_municipio,
        from `basedosdados.br_bd_diretorios_brasil.municipio`
    ),

    dominio as (
        select id, descricao, column
        from `rj-crm-registry.dados_mestres.dominio_bcadastro`
        where source = 'cpf'
    ),

    tb_parsed as (

        select
            id,
            key,
            nullif(json_value(value, '$.rev'), "") as rev,

            nullif(json_value(doc, '$._id'), "") as _id,
            nullif(json_value(doc, '$._rev'), "") as _rev,

            cast(nullif(json_value(doc, '$.anoExerc'), "") as int64) as exercicio_ano,
            nullif(json_value(doc, '$.bairro'), "") as bairro,
            nullif(json_value(doc, '$.cep'), "") as cep,
            nullif(json_value(doc, '$.codMunDomic'), "") as id_municipio_domicilio,
            nullif(json_value(doc, '$.codMunNat'), "") as id_municipio_nascimento,
            nullif(json_value(doc, '$.codNatOcup'), "") as id_natureza_ocupacao,
            nullif(json_value(doc, '$.codOcup'), "") as id_ocupacao,
            nullif(json_value(doc, '$.codSexo'), "") as id_sexo,
            nullif(json_value(doc, '$.codSitCad'), "") as id_situacao_cadastral,
            nullif(json_value(doc, '$.codUA'), "") as id_ua,
            nullif(json_value(doc, '$.complemento'), "") as complemento,
            nullif(json_value(doc, '$.cpfId'), "") as cpf_id,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dtInscricao'), "")
            ) as data_inscricao,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dtNasc'), "")
            ) as data_nascimento,
            safe.parse_date(
                '%Y%m%d', nullif(json_value(doc, '$.dtUltAtualiz'), "")
            ) as data_ultima_atualizacao,
            nullif(json_value(doc, '$.indEstrangeiro'), "") as indicativo_estrangeiro,
            nullif(json_value(doc, '$.indResExt'), "") as indicativo_residente_exterior,
            nullif(json_value(doc, '$.logradouro'), "") as logradouro,
            nullif(json_value(doc, '$.nomeContribuinte'), "") as nome,
            nullif(json_value(doc, '$.nomeMae'), "") as nome_mae,
            nullif(json_value(doc, '$.nroLogradouro'), "") as numero_logradouro,
            nullif(json_value(doc, '$.telefone'), "") as telefone,
            nullif(json_value(doc, '$.tipoLogradouro'), "") as tipo_logradouro,
            nullif(json_value(doc, '$.ufMunDomic'), "") as uf_domicilio,
            nullif(json_value(doc, '$.ufMunNat'), "") as uf_nascimento,
            nullif(
                json_value(replace(to_json_string(doc), '~', ''), '$.version'), ""
            ) as version,

-- Novos campos adicionados
            nullif(json_value(doc, '$.email'), "") as email,
            nullif(json_value(doc, '$.anoObito'), "") as ano_obito,
            nullif(json_value(doc, '$.codPaisNac'), "") as id_pais_nascimento,
            nullif(json_value(doc, '$.nomePaisNac'), "") as nome_pais_nascimento,
            nullif(json_value(doc, '$.codPaisRes'), "") as id_pais_residencia,
            nullif(json_value(doc, '$.nomePaisRes'), "") as nome_pais_residencia,
            nullif(json_value(doc, '$.nomeSocial'), "") as nome_social,
            nullif(json_value(doc, '$.tipo'), "") as tipo,
            nullif(json_value(doc, '$.timestamp'), "") as timestamp,
            nullif(json_value(doc, '$.id'), "") as id_doc,

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
            id,
            _id,
            key,
            rev,
            _rev,
            exercicio_ano,
            bairro,
            cep,
            id_municipio_domicilio,
            md.nome_municipio as municipio_domicilio,
            id_municipio_nascimento,
            mn.nome_municipio as municipio_nascimento,
            id_natureza_ocupacao,
            t.id_ocupacao,
            o.descricao as ocupacao,
            s.descricao as genero,
            sc.descricao as situacao_cadastral,
            id_ua,
            complemento,
            cpf_id as cpf,
            data_inscricao,
            data_nascimento,
            data_ultima_atualizacao,
            ie.descricao as estrangeiro,
            re.descricao as residente_exterior,
            logradouro,
            nome,
            nome_mae,
            numero_logradouro,
            telefone,
            tipo_logradouro,
            uf_domicilio,
            uf_nascimento,
            version,

-- Novos campos adicionados
            email,
            ano_obito,
            id_pais_nascimento,
            nome_pais_nascimento,
            id_pais_residencia,
            nome_pais_residencia,
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

            cast(cpf_id as int64) as cpf_particao
        from tb_parsed t
        left join
            municipio_bd as md
            on cast(t.id_municipio_domicilio as int64)
            = cast(md.id_municipio_rf as int64)
        left join
            municipio_bd as mn
            on cast(t.id_municipio_domicilio as int64)
            = cast(mn.id_municipio_rf as int64)
        left join
            (
                select id as id_ocupacao, descricao
                from dominio
                where column = 'ocupacao'
            ) o
            on t.id_ocupacao = o.id_ocupacao
        left join
            (select id as id_sexo, descricao from dominio where column = 'sexo') s
            on t.id_sexo = s.id_sexo
        left join
            (
                select id as id_situacao_cadastral, descricao
                from dominio
                where column = 'situacao_cadastral'
            ) sc
            on t.id_situacao_cadastral = sc.id_situacao_cadastral
        left join
            (
                select
                    id as indicativo_estrangeiro,
                    case
                        upper(id) when 'N' then false when 'S' then true else null
                    end as descricao
                from dominio
                where column = 'indicativo_estrangeiro'
            ) ie
            on upper(t.indicativo_estrangeiro) = upper(ie.indicativo_estrangeiro)
        left join
            (
                select
                    id as indicativo_residente_exterior,
                    case
                        upper(id) when 'N' then false when 'S' then true else null
                    end as descricao
                from dominio
                where column = 'indicativo_residente_exterior'
            ) re
            on upper(t.indicativo_residente_exterior)
            = upper(re.indicativo_residente_exterior)
    ),

    tb_padronize as (
        select
            id,
            _id,
            key,
            rev,
            _rev,
            exercicio_ano as ano_exercicio,
            data_inscricao,
            cpf,

{{ proper_br("situacao_cadastral") }} as situacao_cadastral,
{{ proper_br("nome") }} as nome,
            data_nascimento,
            lower(genero) as genero,
{{ proper_br("nome_mae") }} as nome_mae,

            telefone as telefone_original,
-- Encontra a posição do último espaço
-- Se não houver espaços, retorna a string inteira
            case
                when regexp_contains(telefone, r'\+')
                then regexp_extract(telefone, r'\+([^\s]+)')
                else null
            end as ddi,
            case
                when regexp_contains(telefone, r'\(')
                then regexp_extract(telefone, r'\(([^\)]+)\)')
                else null
            end as ddd,
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
            end as telefone,

            id_natureza_ocupacao,
            id_ocupacao,
{{ proper_br("ocupacao") }} as ocupacao,
            id_ua,

            id_municipio_domicilio,
{{ proper_br("municipio_domicilio") }} as municipio_domicilio,
            lower(uf_domicilio) as uf_domicilio,
            id_municipio_nascimento,
{{ proper_br("municipio_nascimento") }} as municipio_nascimento,
            lower(uf_nascimento) as uf_nascimento,

            cep,
{{ proper_br("bairro") }} as bairro,
{{ proper_br("tipo_logradouro") }} as tipo_logradouro,
{{ proper_br("logradouro") }} as logradouro,
{{ proper_br("complemento") }} as complemento,
            numero_logradouro,
            estrangeiro,
            residente_exterior,
            data_ultima_atualizacao,
            version,

-- Novos campos adicionados
            email,
            ano_obito,
            id_pais_nascimento,
            nome_pais_nascimento,
            id_pais_residencia,
            nome_pais_residencia,
            nome_social,
            tipo,
            timestamp,
            id_doc,

            row_number() over (
                partition by cpf order by data_ultima_atualizacao desc
            ) as rank,

            seq,
            last_seq,

            airbyte_raw_id,
            airbyte_extracted_at,
            airbyte_meta,
            airbyte_generation_id,

            cpf_particao
        from tb_intermediate
    )

select
    id,
    _id,
    key,
    rev,
    _rev,
    ano_exercicio,
    data_inscricao,
    cpf,
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
    version,
    email,
    ano_obito,
    id_pais_nascimento,
    nome_pais_nascimento,
    id_pais_residencia,
    nome_pais_residencia,
    nome_social,
    tipo,
    timestamp,
    id_doc,
    rank,
    seq,
    last_seq,
    airbyte_raw_id,
    airbyte_extracted_at,
    airbyte_meta,
    airbyte_generation_id,
    cpf_particao
from
    tb_padronize
)
