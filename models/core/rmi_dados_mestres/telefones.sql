-- Dimensão principal de telefones RMI - Registro Mestre de Informações
-- Consolidação final de todos os telefones com qualidade e metadados
{{
    config(
        alias="telefones",
        schema="rmi_dados_mestres", 
        materialized="table",
        partition_by={"field": "rmi_data_criacao", "data_type": "datetime"},
        cluster_by=["telefone_qualidade", "telefone_tipo"],
        unique_key="telefone_numero_completo"
    )
}}

with telefones_all_sources as (
  -- Usar fonte padronizada completa com todas as tabelas
  select 
    telefone_numero_completo, 
    cast(origem_id as string) as origem_id,  -- Explicitly cast to STRING
    cast(origem_tipo as string) as origem_tipo,
    cast(sistema_nome as string) as sistema_nome, 
    data_atualizacao
  from {{ ref('int_telefones_raw_consolidated') }}
),

telefones_frequency as (
  -- Análise de frequência para qualidade
  select 
    telefone_numero_completo,
    count(distinct origem_id) as telefone_proprietarios_quantidade,
    count(distinct sistema_nome) as telefone_sistemas_quantidade,
    count(*) as telefone_aparicoes_quantidade
  from telefones_all_sources
  where origem_id is not null  -- Excluir telefones de comunicação sem proprietário
    and regexp_contains(telefone_numero_completo, r'^[0-9]+$')  -- Only numeric phones
  group by telefone_numero_completo
),

telefones_aparicoes as (
  -- Estruturação das aparições
  select
    telefone_numero_completo,
    array_agg(
      struct(
        cast(sistema_nome as string) as sistema_nome,
        cast(origem_id as string) as proprietario_id,  -- Explicitly cast to STRING
        cast(origem_tipo as string) as proprietario_tipo,
        data_atualizacao as registro_data_atualizacao
      )
    ) as telefone_aparicoes
  from telefones_all_sources
  where origem_id is not null
    and regexp_contains(telefone_numero_completo, r'^[0-9]+$')  -- Only numeric phones
  group by telefone_numero_completo
),

telefones_rmi_schema as (
  select 
    freq.telefone_numero_completo,
    
    -- Decomposição do número
    {{ extract_ddi('freq.telefone_numero_completo') }} as telefone_ddi,
    {{ extract_ddd('freq.telefone_numero_completo') }} as telefone_ddd,
    {{ extract_numero('freq.telefone_numero_completo') }} as telefone_numero,
    
    -- Classificação
    {{ classify_phone_type(
        extract_ddi('freq.telefone_numero_completo'), 
        extract_ddd('freq.telefone_numero_completo'), 
        extract_numero('freq.telefone_numero_completo')
    ) }} as telefone_tipo,
    
    {{ get_nationality(extract_ddi('freq.telefone_numero_completo')) }} as telefone_nacionalidade,
    
    {{ validate_phone_quality(
        'freq.telefone_numero_completo', 
        'freq.telefone_proprietarios_quantidade'
    ) }} as telefone_qualidade,
    
    -- Metadados de aparição
    aparicoes.telefone_aparicoes,
    freq.telefone_aparicoes_quantidade,
    freq.telefone_proprietarios_quantidade,
    freq.telefone_sistemas_quantidade,
    
    -- Auditoria RMI
    current_datetime() as rmi_data_criacao,
    current_datetime() as rmi_data_atualizacao,
    '{{ var("phone_validation").rmi_version }}' as rmi_versao,
    {{ generate_hash('freq.telefone_numero_completo', 'aparicoes.telefone_aparicoes') }} as rmi_hash_validacao

  from telefones_frequency freq
  left join telefones_aparicoes aparicoes using (telefone_numero_completo)
)

select *
from telefones_rmi_schema
where telefone_numero_completo is not null