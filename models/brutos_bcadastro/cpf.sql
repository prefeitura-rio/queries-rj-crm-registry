WITH tb AS (
  SELECT * 
  FROM `rj-crm-registry.airbyte_internal.sandbox_staging_raw__stream_chcpf_bcadastros_documents_incremental`
  LIMIT 10
),

tb_parsed AS (

SELECT
  JSON_VALUE(_airbyte_data, '$.id') AS id,
  JSON_VALUE(_airbyte_data, '$.key') AS key,
  JSON_VALUE(_airbyte_data, '$.value.rev') AS revision,
  CAST(JSON_VALUE(_airbyte_data, '$.doc.anoExerc') AS INT64) AS exercicio_ano,
  JSON_VALUE(_airbyte_data, '$.doc.bairro') AS bairro,
  JSON_VALUE(_airbyte_data, '$.doc.cep') AS cep,
  JSON_VALUE(_airbyte_data, '$.doc.codMunDomic') AS codigo_municipio_domicilio,
  JSON_VALUE(_airbyte_data, '$.doc.codMunNat') AS codigo_municipio_nascimento,
  JSON_VALUE(_airbyte_data, '$.doc.codNatOcup') AS codigo_natureza_ocupacao,
  JSON_VALUE(_airbyte_data, '$.doc.codOcup') AS codigo_ocupacao,
  JSON_VALUE(_airbyte_data, '$.doc.codSexo') AS codigo_sexo,
  JSON_VALUE(_airbyte_data, '$.doc.codSitCad') AS codigo_situacao_cadastral,
  JSON_VALUE(_airbyte_data, '$.doc.codUA') AS codigo_ua,
  JSON_VALUE(_airbyte_data, '$.doc.complemento') AS complemento,
  JSON_VALUE(_airbyte_data, '$.doc.cpfId') AS cpf_id,
  PARSE_DATE('%Y%m%d', JSON_VALUE(_airbyte_data, '$.doc.dtInscricao')) AS data_inscricao,
  PARSE_DATE('%Y%m%d', JSON_VALUE(_airbyte_data, '$.doc.dtNasc')) AS data_nascimento,
  PARSE_DATE('%Y%m%d', JSON_VALUE(_airbyte_data, '$.doc.dtUltAtualiz')) AS data_ultima_atualizacao,
  JSON_VALUE(_airbyte_data, '$.doc.indEstrangeiro') AS indicativo_estrangeiro,
  JSON_VALUE(_airbyte_data, '$.doc.indResExt') AS indicativo_residente_exterior,
  JSON_VALUE(_airbyte_data, '$.doc.logradouro') AS logradouro,
  JSON_VALUE(_airbyte_data, '$.doc.nomeContribuinte') AS nome_contribuinte,
  JSON_VALUE(_airbyte_data, '$.doc.nomeMae') AS nome_mae,
  JSON_VALUE(_airbyte_data, '$.doc.nroLogradouro') AS numero_logradouro,
  JSON_VALUE(_airbyte_data, '$.doc.telefone') AS telefone,
  JSON_VALUE(_airbyte_data, '$.doc.tipoLogradouro') AS tipo_logradouro,
  JSON_VALUE(_airbyte_data, '$.doc.ufMunDomic') AS uf_municipio_domicilio,
  JSON_VALUE(_airbyte_data, '$.doc.ufMunNat') AS uf_municipio_nascimento,
  JSON_VALUE(_airbyte_data, '$.doc.version') AS version,
  JSON_VALUE(_airbyte_data, '$.seq') AS seq,
  JSON_VALUE(_airbyte_data, '$.last_seq') AS last_seq,
  _airbyte_meta,
  _airbyte_generation_id
FROM tb
)

SELECT
  id,
  key,
  revision,
  exercicio_ano,
  bairro,
  cep,
  codigo_municipio_domicilio,
  codigo_municipio_nascimento,
  codigo_natureza_ocupacao,
  codigo_ocupacao,
  CASE codigo_sexo
    WHEN '1' THEN 'Masculino'
    WHEN '2' THEN 'Feminino'
    WHEN '9' THEN 'Não informado'
    ELSE codigo_sexo
  END AS sexo,
  CASE codigo_situacao_cadastral
    WHEN '0' THEN 'Regular'
    WHEN '2' THEN 'Suspensa'
    WHEN '3' THEN 'Titular Falecido'
    WHEN '4' THEN 'Pendente de Regularização'
    WHEN '5' THEN 'Cancelada por Multiplicidade'
    WHEN '8' THEN 'Nula'
    WHEN '9' THEN 'Cancelada de Ofício'
    ELSE codigo_situacao_cadastral
  END AS situacao_cadastral,
  codigo_ua,
  complemento,
  cpf_id,
  data_inscricao,
  data_nascimento,
  data_ultima_atualizacao,
  CASE indicativo_estrangeiro
    WHEN 'N' THEN FALSE
    WHEN 'S' THEN TRUE
    ELSE NULL 
  END AS estrangeiro,
  CASE indicativo_residente_exterior
    WHEN 'S' THEN TRUE
    WHEN 'N' THEN FALSE
    ELSE NULL
  END AS residente_no_exterior,
  logradouro,
  nome_contribuinte,
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
  _airbyte_generation_id
FROM tb_parsed