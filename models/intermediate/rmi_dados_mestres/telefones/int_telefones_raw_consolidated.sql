-- Consolida todos os telefones de todas as fontes do sistema
-- Padroniza formato e extrai informações básicas para análise RMI
{{
    config(
        alias="telefones_raw_consolidated",
        schema="intermediario_rmi_telefones",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

with 

-- PESSOA FÍSICA - BCadastro (Receita Federal)
-- TYPES: origem_id STRING, origem_tipo STRING, telefone_numero_completo STRING, 
-- sistema_nome STRING, campo_origem STRING, contexto STRING, data_atualizacao DATETIME
telefones_bcadastro_cpf as (
  select 
    t.cpf as origem_id,  -- Use table alias to be explicit
    'CPF' as origem_tipo,
    -- Use DDI from data, don't assume Brazilian numbers
    concat(
      coalesce(t.contato.telefone.ddi, '55'), 
      t.contato.telefone.ddd, 
      {{ padronize_telefone('t.contato.telefone.numero') }}
    ) as telefone_numero_completo,
    'bcadastro' as sistema_nome,
    'bcadastro_cpf.contato.telefone' as campo_origem,
    'PESSOAL' as contexto,
    null as data_atualizacao  -- Use real update date from source
  from {{ source('bcadastro', 'cpf') }} as t
  where t.contato.telefone.numero is not null
),

-- PESSOA JURÍDICA - BCadastro (Receita Federal)  
-- TYPES: origem_id STRING, origem_tipo STRING, telefone_numero_completo STRING, 
-- sistema_nome STRING, campo_origem STRING, contexto STRING, data_atualizacao DATETIME
telefones_bcadastro_cnpj as (
  select 
    c.cnpj as origem_id,  -- Use table alias to be explicit
    'CNPJ' as origem_tipo,
    -- BCadastro CNPJ has telefone array with {ddd, telefone} structure
    concat('55', tel.ddd, {{ padronize_telefone('tel.telefone') }}) as telefone_numero_completo,
    'bcadastro' as sistema_nome,
    'bcadastro_cnpj.contato.telefone[]' as campo_origem,
    'EMPRESARIAL' as contexto,
    null as data_atualizacao  -- Parse timestamp string
  from {{ source('bcadastro', 'cnpj') }} as c,
    unnest(c.contato.telefone) as tel
  where tel.telefone is not null
),

-- SAÚDE - Registros SMS
-- TYPES: origem_id STRING, origem_tipo STRING, telefone_numero_completo STRING, 
-- sistema_nome STRING, campo_origem STRING, contexto STRING, data_atualizacao DATETIME (cast from TIMESTAMP)
telefones_sms as (
  select 
    cns_item as origem_id,  -- Already string from unnest
    'CNS' as origem_tipo,
    -- SMS has telefone array with {ddd, valor, sistema, rank} structure
    concat('55', tel.ddd, {{ padronize_telefone('tel.valor') }}) as telefone_numero_completo,
    'sms' as sistema_nome,
    'sms_paciente.contato.telefone[]' as campo_origem,
    'SAUDE' as contexto,
    null as data_atualizacao  -- Use real processed timestamp
  from {{ source('rj-sms', 'paciente') }} as s,
    unnest(s.cns) as cns_item,
    unnest(s.contato.telefone) as tel  
  where tel.valor is not null and cns_item is not null
),
-- FUNCIONAL - ERGON (servidores públicos)
-- TODO: verificar fonte correta e ativar telefones_ergon


telefones_all_sources as (
  -- BCadastro CPF (Pessoas Físicas)
  select * from telefones_bcadastro_cpf
  
  union all
  
  -- BCadastro CNPJ (Pessoas Jurídicas)
  select * from telefones_bcadastro_cnpj
  
  union all
  
  -- SMS Saúde (Pacientes do sistema de saúde)
  select * from telefones_sms

  
  -- All sources now use explicit table aliases and consistent field types:
  -- origem_id STRING, origem_tipo STRING, telefone_numero_completo STRING, 
  -- sistema_nome STRING, campo_origem STRING, contexto STRING, data_atualizacao DATETIME
)

select 
  origem_id,
  origem_tipo,
  telefone_numero_completo,
  sistema_nome,
  campo_origem,
  contexto,
  data_atualizacao
from telefones_all_sources
where telefone_numero_completo is not null
  and length(telefone_numero_completo) >= 10