CREATE OR REPLACE TABLE `rj-crm-registry.brutos_bcadastro.cpf` 
PARTITION BY
  RANGE_BUCKET(cpf_particao, GENERATE_ARRAY(0, 100000000000, 34722222))

  AS

(
    with
    tb as (
        select *
        from
            `rj-crm-registry.airbyte_internal.brutos_bcadastro_staging_raw__stream_chcpf_bcadastros`
    ),

    municipio_bd as (
        SELECT
            id_municipio_rf,
            nome AS nome_municipio,
        FROM `basedosdados.br_bd_diretorios_brasil.municipio`
    ),

    tb_parsed as (

        select
            json_value(_airbyte_data, '$.id') as id,
            json_value(_airbyte_data, '$.key') as key,
            json_value(_airbyte_data, '$.value.rev') as revision,
            cast(json_value(_airbyte_data, '$.doc.anoExerc') as int64) as exercicio_ano,
            json_value(_airbyte_data, '$.doc.bairro') as bairro,
            json_value(_airbyte_data, '$.doc.cep') as cep,
            json_value(_airbyte_data, '$.doc.codMunDomic') as id_municipio_domicilio,
            json_value(_airbyte_data, '$.doc.codMunNat') as id_municipio_nascimento,
            json_value(_airbyte_data, '$.doc.codNatOcup') as id_natureza_ocupacao,
            json_value(_airbyte_data, '$.doc.codOcup') as id_ocupacao,
            json_value(_airbyte_data, '$.doc.codSexo') as id_sexo,
            json_value(_airbyte_data, '$.doc.codSitCad') as id_situacao_cadastral,
            json_value(_airbyte_data, '$.doc.codUA') as id_ua,
            json_value(_airbyte_data, '$.doc.complemento') as complemento,
            json_value(_airbyte_data, '$.doc.cpfId') as cpf_id,
            safe.parse_date(
                '%Y%m%d', json_value(_airbyte_data, '$.doc.dtInscricao')
            ) as data_inscricao,
            safe.parse_date(
                '%Y%m%d', json_value(_airbyte_data, '$.doc.dtNasc')
            ) as data_nascimento,
            safe.parse_date(
                '%Y%m%d', json_value(_airbyte_data, '$.doc.dtUltAtualiz')
            ) as data_ultima_atualizacao,
            json_value(_airbyte_data, '$.doc.indEstrangeiro') as indicativo_estrangeiro,
            json_value(
                _airbyte_data, '$.doc.indResExt'
            ) as indicativo_residente_exterior,
            json_value(_airbyte_data, '$.doc.logradouro') as logradouro,
            json_value(_airbyte_data, '$.doc.nomeContribuinte') as nome,
            json_value(_airbyte_data, '$.doc.nomeMae') as nome_mae,
            json_value(_airbyte_data, '$.doc.nroLogradouro') as numero_logradouro,
            json_value(_airbyte_data, '$.doc.telefone') as telefone,
            json_value(_airbyte_data, '$.doc.tipoLogradouro') as tipo_logradouro,
            json_value(_airbyte_data, '$.doc.ufMunDomic') as uf_municipio_domicilio,
            json_value(_airbyte_data, '$.doc.ufMunNat') as uf_municipio_nascimento,
            json_value(REPLACE(_airbyte_data, '~',''), '$.doc.version') as version,
            json_value(_airbyte_data, '$.seq') as seq,
            json_value(_airbyte_data, '$.last_seq') as last_seq,
            _airbyte_meta,
            _airbyte_generation_id
        from tb
    )

select
    id,
    key,
    revision,
    exercicio_ano,
    bairro,
    cep,
    id_municipio_domicilio,
    md.nome_municipio as nome_municipio_domicilio,
    id_municipio_nascimento,
    mn.nome_municipio as nome_municipio_nascimento,
    id_natureza_ocupacao,
    t.id_ocupacao,
    o.descricao as descricao_ocupacao,
    case
        id_sexo
        when '1'
        then 'Masculino'
        when '2'
        then 'Feminino'
        when '9'
        then 'Não informado'
        else id_sexo
    end as sexo,
    case
        id_situacao_cadastral
        when '0'
        then 'Regular'
        when '2'
        then 'Suspensa'
        when '3'
        then 'Titular Falecido'
        when '4'
        then 'Pendente de Regularização'
        when '5'
        then 'Cancelada por Multiplicidade'
        when '8'
        then 'Nula'
        when '9'
        then 'Cancelada de Ofício'
        else id_situacao_cadastral
    end as situacao_cadastral,
    id_ua,
    complemento,
    cpf_id,
    data_inscricao,
    data_nascimento,
    data_ultima_atualizacao,
    case
        indicativo_estrangeiro when 'N' then false when 'S' then true else null
    end as estrangeiro,
    case
        indicativo_residente_exterior when 'S' then true when 'N' then false else null
    end as residente_exterior,
    logradouro,
    nome,
    nome_mae,
    numero_logradouro,
    telefone,
    tipo_logradouro,
    uf_municipio_domicilio,
    uf_municipio_nascimento,
    version,
    seq,
    last_seq,
    _airbyte_meta,
    _airbyte_generation_id,
    cast( cpf_id as int64) as cpf_particao
from tb_parsed t
left join municipio_bd as md
    on t.id_municipio_domicilio = md.id_municipio_rf
left join municipio_bd as mn
    on t.id_municipio_nascimento = mn.id_municipio_rf
left join `rj-crm-registry.brutos_bcadastro.ocupacao_receita_federal` o
  on t.id_ocupacao = o.id_ocupacao


)