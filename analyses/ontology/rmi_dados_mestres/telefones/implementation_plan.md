# Plano de Implementação - RMI Telefones

## Análise da Situação Atual

### Estado Atual
- **Macro `padronize_telefone`**: Limpa e padroniza números básicos (remove zeros, parênteses, etc.)
- **Modelo `int_pessoa_fisica_dim_telefone`**: Consolida telefones por CPF com estrutura hierárquica (principal/alternativo)
- **Estrutura atual**: `telefone.{indicador, principal.{origem, sistema, ddi, ddd, valor}, alternativo[]}`

### Gaps Identificados
1. **Falta validação de qualidade** (VÁLIDO/SUSPEITO/INVÁLIDO)
2. **Falta classificação de tipo** (CELULAR/FIXO/VOIP)
3. **Falta análise de frequência** para detectar números compartilhados/falsos
4. **Falta campos do schema RMI** (nacionalidade, aparições, metadados)

## Estratégia de Implementação

### Fase 1: Configuração Centralizada

#### 1.1 Arquivo de Configuração `phone_validation_config.yml`
**Localização**: `dbt_project.yml` ou arquivo separado `config/phone_validation.yml`

```yaml
# Configuração centralizada para validação de telefones
vars:
  phone_validation:
    # Limites de frequência para classificação de qualidade
    freq_valid_max: 5           # <= 5 pessoas = VÁLIDO
    freq_suspicious_min: 6      # 6-15 pessoas = SUSPEITO  
    freq_suspicious_max: 15
    freq_invalid_min: 16        # > 15 pessoas = INVÁLIDO
    
    # Padrões para detecção de números suspeitos
    max_repeated_digits: 5      # Máximo de dígitos repetidos seguidos
    suspicious_patterns:
      - "212121"               # Repetição de dois dígitos
      - "123123123"            # Repetição de três dígitos
    
    # Padrões conhecidos de números falsos/dummy
    dummy_patterns:
      - "123456789"            # Sequência numérica
      - "987654321"            # Sequência reversa
      - "111111111"            # Todos iguais
      - "000000000"            # Todos zeros
    
    # Configuração por país
    countries:
      brasil:
        ddi: "55"
        celular_length: 9
        celular_prefix: "9"
        fixo_length: 8
        valid_ddds: [11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 31, 32, 33, 34, 35, 37, 38, 41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55, 61, 62, 63, 64, 65, 66, 67, 68, 69, 71, 73, 74, 75, 77, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99]
    
    # Configuração de auditoria
    rmi_version: "v1.0"
    hash_algorithm: "sha256"
```

### Fase 2: Criação de Macros de Validação

**Estrutura de Pastas**: Todas as macros de telefone ficam organizadas em `/macros/telefone/`

```
macros/
└── telefone/
    ├── validate_phone_quality.sql
    ├── classify_phone_type.sql
    ├── is_format_valid.sql
    ├── has_suspicious_patterns.sql
    ├── has_dummy_patterns.sql
    ├── extract_ddi.sql
    ├── extract_ddd.sql
    ├── extract_numero.sql
    ├── get_nationality.sql
    └── generate_hash.sql
```

#### 2.1 Macro `validate_phone_quality`
```sql
-- /macros/telefone/validate_phone_quality.sql
{% macro validate_phone_quality(numero_completo, freq_usage) %}
  {% set config = var('phone_validation') %}
  case
    when {{ is_format_valid(numero_completo) }} 
         and {{ freq_usage }} <= {{ config.freq_valid_max }} 
    then 'VALIDO'
    
    when {{ is_format_valid(numero_completo) }} 
         and (
           {{ freq_usage }} between {{ config.freq_suspicious_min }} and {{ config.freq_suspicious_max }}
           or {{ has_suspicious_patterns(numero_completo) }}
         )
    then 'SUSPEITO'
    
    when not {{ is_format_valid(numero_completo) }}
         or {{ freq_usage }} >= {{ config.freq_invalid_min }}
         or {{ has_dummy_patterns(numero_completo) }}
    then 'INVALIDO'
    
    else 'SUSPEITO'
  end
{% endmacro %}
```

#### 2.2 Macro `classify_phone_type`
```sql
-- /macros/telefone/classify_phone_type.sql
{% macro classify_phone_type(ddi, ddd, numero) %}
  {% set config = var('phone_validation') %}
  {% set brasil = config.countries.brasil %}
  case
    when {{ ddi }} = '{{ brasil.ddi }}' 
         and length({{ numero }}) = {{ brasil.celular_length }}
         and starts_with({{ numero }}, '{{ brasil.celular_prefix }}')
    then 'CELULAR'
    
    when {{ ddi }} = '{{ brasil.ddi }}' 
         and length({{ numero }}) = {{ brasil.fixo_length }}
    then 'FIXO'
    
    when {{ ddi }} != '{{ brasil.ddi }}'
    then 'OUTROS'  -- Internacional
    
    else 'OUTROS'
  end
{% endmacro %}
```

#### 2.3 Macro `is_format_valid`
```sql
-- /macros/telefone/is_format_valid.sql
{% macro is_format_valid(numero_completo) %}
  {% set config = var('phone_validation') %}
  {% set brasil = config.countries.brasil %}
  (
    -- Validação para números brasileiros
    (
      starts_with({{ numero_completo }}, '{{ brasil.ddi }}')
      and length({{ numero_completo }}) in (13, 14)  -- 55 + DDD + 8/9 dígitos
      and {{ extract_ddd(numero_completo) }} in ({{ brasil.valid_ddds | join(', ') }})
    )
    -- Adicionar validações para outros países aqui
  )
{% endmacro %}
```

#### 2.4 Macro `has_suspicious_patterns`
```sql
-- /macros/telefone/has_suspicious_patterns.sql
{% macro has_suspicious_patterns(numero_completo) %}
  {% set config = var('phone_validation') %}
  (
    -- Repetição excessiva de dígitos
    regexp_contains({{ numero_completo }}, r'(\d)\1{' || {{ config.max_repeated_digits }} || ',}')
    
    -- Padrões suspeitos específicos
    {% for pattern in config.suspicious_patterns %}
    or contains({{ numero_completo }}, '{{ pattern }}')
    {% endfor %}
  )
{% endmacro %}
```

#### 2.5 Macro `has_dummy_patterns`
```sql
-- /macros/telefone/has_dummy_patterns.sql
{% macro has_dummy_patterns(numero_completo) %}
  {% set config = var('phone_validation') %}
  (
    -- Padrões conhecidos como falsos
    {% for pattern in config.dummy_patterns %}
    contains({{ numero_completo }}, '{{ pattern }}')
    {% if not loop.last %} or {% endif %}
    {% endfor %}
  )
{% endmacro %}
```

#### 2.6 Macros Auxiliares

**Macro `extract_ddi`**
```sql
-- /macros/telefone/extract_ddi.sql
{% macro extract_ddi(numero_completo) %}
  {% set config = var('phone_validation') %}
  case
    when starts_with({{ numero_completo }}, '55') then '55'
    when starts_with({{ numero_completo }}, '1') then '1'
    -- Adicionar outros DDIs conforme necessário
    else substr({{ numero_completo }}, 1, 2)
  end
{% endmacro %}
```

**Macro `extract_ddd`**
```sql
-- /macros/telefone/extract_ddd.sql
{% macro extract_ddd(numero_completo) %}
  {% set config = var('phone_validation') %}
  case
    when starts_with({{ numero_completo }}, '55') 
    then substr({{ numero_completo }}, 3, 2)
    else null
  end
{% endmacro %}
```

**Macro `extract_numero`**
```sql
-- /macros/telefone/extract_numero.sql
{% macro extract_numero(numero_completo) %}
  {% set config = var('phone_validation') %}
  case
    when starts_with({{ numero_completo }}, '55')
    then substr({{ numero_completo }}, 5)
    else {{ numero_completo }}
  end
{% endmacro %}
```

**Macro `get_nationality`**
```sql
-- /macros/telefone/get_nationality.sql
{% macro get_nationality(ddi) %}
  case
    when {{ ddi }} = '55' then 'Brasil'
    when {{ ddi }} = '1' then 'Estados Unidos'
    when {{ ddi }} = '54' then 'Argentina'
    -- Expandir conforme necessário
    else 'Internacional'
  end
{% endmacro %}
```

**Macro `generate_hash`**
```sql
-- /macros/telefone/generate_hash.sql
{% macro generate_hash(campo1, campo2) %}
  {% set config = var('phone_validation') %}
  {% if config.hash_algorithm == 'sha256' %}
    sha256(concat(cast({{ campo1 }} as string), cast({{ campo2 }} as string)))
  {% else %}
    farm_fingerprint(concat(cast({{ campo1 }} as string), cast({{ campo2 }} as string)))
  {% endif %}
{% endmacro %}
```

### Fase 3: Pipeline de Padronização (NOVO)

#### 3.1 Modelo `int_telefones_raw_consolidated`
**Localização**: `models/intermediate/rmi_dados_mestres/telefones/`
**Objetivo**: Consolidar e padronizar telefones de todas as fontes raw

```sql
-- Aplicar padronização early no pipeline de TODAS as fontes identificadas
with 

-- 1. PESSOA FÍSICA - BCadastro (Receita Federal)
telefones_bcadastro_cpf as (
  select 
    cpf as origem_id,
    'CPF' as origem_tipo,
    concat(
      coalesce(contato.telefone.ddi, '55'),
      contato.telefone.ddd,
      {{ padronize_telefone('contato.telefone.numero') }}
    ) as telefone_numero_completo,
    'bcadastro' as sistema_nome,
    'contato.telefone' as campo_origem,
    'PESSOAL' as contexto,
    data_atualizacao
  from {{ source('bcadastro', 'cpf') }}
  where contato.telefone.numero is not null
),

-- 2. PESSOA FÍSICA - SMS Health System (rj-sms)
telefones_sms as (
  select 
    cpf as origem_id,
    'CPF' as origem_tipo,
    concat(
      '55',  -- Assumir Brasil para SMS
      tel.ddd,
      {{ padronize_telefone('tel.valor') }}
    ) as telefone_numero_completo,
    coalesce(tel.sistema, 'sms') as sistema_nome,
    'contato.telefone[]' as campo_origem,
    'PESSOAL' as contexto,
    data_atualizacao
  from {{ source('rj-sms', 'paciente') }}, unnest(contato.telefone) as tel
  where tel.valor is not null
),

-- 3. PESSOA FÍSICA - SMAS Social Assistance (investigar estrutura)
-- TODO: Investigar estrutura real de telefone em rj-smas.app_identidade_unica.cadastros
-- telefones_smas as (
--   select 
--     cpf as origem_id,
--     'CPF' as origem_tipo,
--     {{ padronize_telefone('campo_telefone') }} as telefone_numero_completo,
--     'smas' as sistema_nome,
--     'campo_origem' as campo_origem,
--     'SOCIAL' as contexto,
--     data_atualizacao
--   from {{ source('rj-smas', 'cadastros') }}
--   where campo_telefone is not null
-- ),

-- 4. PESSOA JURÍDICA - BCadastro CNPJ
telefones_bcadastro_cnpj as (
  select 
    cnpj as origem_id,
    'CNPJ' as origem_tipo,
    concat(
      '55',  -- Assumir Brasil para empresas
      tel_info.ddd,
      {{ padronize_telefone('tel_info.telefone') }}
    ) as telefone_numero_completo,
    'bcadastro' as sistema_nome,
    'telefone[]' as campo_origem,
    'COMERCIAL' as contexto,
    data_atualizacao
  from {{ source('bcadastro', 'cnpj') }},
       unnest(telefone) as tel_info with offset pos
  where tel_info.telefone is not null
    and tel_info.ddd is not null
),

-- 5. FUNCIONÁRIOS MUNICIPAIS - ERGON
telefones_ergon as (
  select 
    num_cpf as origem_id,  -- Assumindo que há CPF do funcionário
    'CPF' as origem_tipo,
    concat('55', {{ padronize_telefone('telefone_requisicao') }}) as telefone_numero_completo,
    'ergon' as sistema_nome,
    'telefone_requisicao' as campo_origem,
    'FUNCIONAL' as contexto,
    data_atualizacao
  from {{ source('rj-smfp', 'vinculo') }}
  where telefone_requisicao is not null
    and length(trim(telefone_requisicao)) >= 10
),

-- 6. COMUNICAÇÃO - Wetalkie Dispatches (WhatsApp)
telefones_wetalkie_dispatches as (
  select 
    null as origem_id,  -- Não tem CPF diretamente
    'COMUNICACAO' as origem_tipo,
    {{ padronize_telefone('to') }} as telefone_numero_completo,
    'wetalkie' as sistema_nome,
    'to' as campo_origem,
    'WHATSAPP' as contexto,
    created_at as data_atualizacao
  from {{ source('wetalkie', 'disparos_efetuados') }}
  where to is not null
    and length(trim(to)) >= 10
),

-- 7. COMUNICAÇÃO - Wetalkie Flow Target
telefones_wetalkie_flow as (
  select 
    null as origem_id,  -- Não tem CPF diretamente
    'COMUNICACAO' as origem_tipo,
    {{ padronize_telefone('flatTarget') }} as telefone_numero_completo,
    'wetalkie' as sistema_nome,
    'flatTarget' as campo_origem,
    'ATENDIMENTO' as contexto,
    created_at as data_atualizacao
  from {{ source('wetalkie', 'fluxo_atendimento_staging') }}
  where flatTarget is not null
    and length(trim(flatTarget)) >= 10
),

-- 8. COMUNICAÇÃO - Wetalkie School Phones (em vars JSON)
telefones_wetalkie_escola as (
  select 
    null as origem_id,
    'COMUNICACAO' as origem_tipo,
    {{ padronize_telefone("json_extract_scalar(vars, '$.telefoneescola')") }} as telefone_numero_completo,
    'wetalkie' as sistema_nome,
    'vars.telefoneescola' as campo_origem,
    'EDUCACIONAL' as contexto,
    created_at as data_atualizacao
  from {{ source('wetalkie', 'disparos_efetuados') }}
  where json_extract_scalar(vars, '$.telefoneescola') is not null
    and length(trim(json_extract_scalar(vars, '$.telefoneescola'))) >= 10
),

-- Union de todas as fontes padronizadas
telefones_all_sources as (
  select * from telefones_bcadastro_cpf
  union all
  select * from telefones_sms
  -- union all
  -- select * from telefones_smas  -- Ativar após investigar estrutura
  union all
  select * from telefones_bcadastro_cnpj
  union all
  select * from telefones_ergon
  union all
  select * from telefones_wetalkie_dispatches
  union all
  select * from telefones_wetalkie_flow
  union all
  select * from telefones_wetalkie_escola
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
  and length(telefone_numero_completo) >= 12  -- Mínimo para número brasileiro completo (55 + DDD + número)
```

### Fase 4: Consolidação RMI

#### 4.1 Modelo `int_rmi_telefones_consolidated`
**Localização**: `models/intermediate/rmi_dados_mestres/telefones/`
**Objetivo**: Implementar schema RMI completo com qualidade e metadados

```sql
with telefones_all_sources as (
  -- Usar fonte padronizada
  select telefone_numero_completo, cpf, cnpj, sistema_nome, data_atualizacao
  from {{ ref('int_telefones_raw_consolidated') }}
),

telefones_frequency as (
  -- Análise de frequência para qualidade
  select 
    telefone_numero_completo,
    count(distinct coalesce(cpf, cnpj)) as telefone_proprietarios_quantidade,
    count(distinct sistema_nome) as telefone_sistemas_quantidade,
    count(*) as telefone_aparicoes_quantidade
  from telefones_all_sources
  group by telefone_numero_completo
),

telefones_aparicoes as (
  -- Estruturação das aparições
  select
    telefone_numero_completo,
    array_agg(
      struct(
        sistema_nome,
        coalesce(cpf, cnpj) as proprietario_id,
        if(cpf is not null, 'CPF', 'CNPJ') as proprietario_tipo,
        data_atualizacao as registro_data_atualizacao
      )
    ) as telefone_aparicoes
  from telefones_all_sources
  group by telefone_numero_completo
)

select 
  t.telefone_numero_completo,
  
  -- Decomposição do número
  {{ extract_ddi('telefone_numero_completo') }} as telefone_ddi,
  {{ extract_ddd('telefone_numero_completo') }} as telefone_ddd,
  {{ extract_numero('telefone_numero_completo') }} as telefone_numero,
  
  -- Classificação
  {{ classify_phone_type('telefone_ddi', 'telefone_ddd', 'telefone_numero') }} as telefone_tipo,
  {{ get_nationality('telefone_ddi') }} as telefone_nacionalidade,
  {{ validate_phone_quality('telefone_numero_completo', 'freq.telefone_proprietarios_quantidade') }} as telefone_qualidade,
  
  -- Metadados de aparição
  aparicoes.telefone_aparicoes,
  freq.telefone_aparicoes_quantidade,
  freq.telefone_proprietarios_quantidade,
  freq.telefone_sistemas_quantidade,
  
  -- Auditoria RMI
  current_datetime() as rmi_data_criacao,
  current_datetime() as rmi_data_atualizacao,
  '{{ var("phone_validation").rmi_version }}' as rmi_versao,
  {{ generate_hash('telefone_numero_completo', 'telefone_aparicoes') }} as rmi_hash_validacao

from telefones_frequency freq
left join telefones_aparicoes aparicoes using (telefone_numero_completo)
```

### Fase 5: Integração com Sistema Existente

#### 5.1 Atualização do `int_pessoa_fisica_dim_telefone`

**Estratégia**: Manter estrutura atual + usar fonte padronizada + adicionar campos RMI via JOIN

```sql
-- Substituir a lógica de origem por fonte padronizada:
telefone as (
  select
    cpf,
    rmi.telefone_ddi as ddi,
    rmi.telefone_ddd as ddd, 
    rmi.telefone_numero as valor,
    rmi.telefone_tipo,
    rmi.telefone_qualidade,
    rmi.telefone_nacionalidade,
    tc.sistema_nome as sistema,
    tc.data_atualizacao,
    row_number() over (
      partition by cpf 
      order by 
        case when tc.sistema_nome = 'sms' then 1 
             when tc.sistema_nome = 'bcadastro' then 2 
             else 3 end,
        tc.data_atualizacao desc
    ) as rank
  from {{ ref('int_rmi_telefones_consolidated') }} rmi
  inner join {{ ref('int_telefones_raw_consolidated') }} tc
    on rmi.telefone_numero_completo = tc.telefone_numero_completo
  where rmi.telefone_qualidade in ('VALIDO', 'SUSPEITO')  -- Filtrar apenas telefones válidos/suspeitos
),

telefone_with_rmi as (
  select 
    cpf,
    rmi.telefone_tipo,
    rmi.telefone_qualidade, 
    rmi.telefone_nacionalidade,
    -- Manter estrutura original para compatibilidade
    'consolidado_rmi' as origem,
    tc.sistema_nome as sistema,
    rmi.telefone_ddi as ddi,
    rmi.telefone_ddd as ddd,
    rmi.telefone_numero as valor,
    rank
  from {{ ref('int_rmi_telefones_consolidated') }} rmi
  inner join {{ ref('int_telefones_raw_consolidated') }} tc using (telefone_numero_completo)
  where rmi.telefone_qualidade in ('VALIDO', 'SUSPEITO')
)

select
  cpf,
  struct(
    telefone.indicador,
    struct(
      telefone.principal.origem,
      telefone.principal.sistema,
      telefone.principal.ddi,
      telefone.principal.ddd,
      telefone.principal.valor,
      -- Novos campos RMI
      telefone_tipo,
      telefone_qualidade,
      telefone_nacionalidade
    ) as principal,
    telefone.alternativo
  ) as telefone
from telefone_with_rmi
```

### Fase 6: Modelos Core RMI

#### 6.1 Dimensão `telefones.sql` 
**Localização**: `models/core/rmi_dados_mestres/telefones.sql`
**Alias**: `telefones` (seguindo convenção do projeto)
**Materialização**: Table
**Particionamento**: Por hash do telefone

```sql
-- Dimensão principal de telefones RMI
{{ config(
    alias="telefones",
    schema="rmi_dados_mestres", 
    materialized="table",
    partition_by={"field": "rmi_data_criacao", "data_type": "datetime"},
    cluster_by=["telefone_qualidade", "telefone_tipo"]
) }}

select * from {{ ref('int_rmi_telefones_consolidated') }}
```

#### 6.2 Modelo Intermediate de Aparições (se necessário)
**Localização**: `models/intermediate/rmi_dados_mestres/telefones/int_rmi_telefones_aparicoes.sql`
**Objetivo**: Análise detalhada de aparições (caso seja necessário para debugging/auditoria)

```sql
-- Modelo intermediate para análise de aparições
select
  telefone_numero_completo,
  aparicao.sistema_nome,
  aparicao.proprietario_id,
  aparicao.proprietario_tipo,
  aparicao.registro_data_atualizacao,
  telefone_qualidade,
  telefone_tipo
from {{ ref('int_rmi_telefones_consolidated') }},
     unnest(telefone_aparicoes) as aparicao
```

### Fase 7: Testes e Validação

#### 7.1 Testes de Qualidade
```yaml
# int_rmi_telefones_consolidated.yml
tests:
  - accepted_values:
      name: telefone_qualidade_valid_values
      column_name: telefone_qualidade
      values: ['VALIDO', 'SUSPEITO', 'INVALIDO']
  
  - accepted_values:
      name: telefone_tipo_valid_values  
      column_name: telefone_tipo
      values: ['CELULAR', 'FIXO', 'VOIP', 'OUTROS']
```

#### 7.2 Testes de Integridade
- Validação de formato brasileiro para DDI=55
- Consistência entre `telefone_aparicoes_quantidade` e array length
- Hash de validação único por telefone

## Gerenciamento de Configuração

### Localização da Configuração
A configuração centralizada pode ser implementada de duas formas:

#### Opção 1: Dentro do `dbt_project.yml`
```yaml
# dbt_project.yml
vars:
  phone_validation:
    freq_valid_max: 5
    # ... resto da configuração
```

#### Opção 2: Arquivo Separado + Import
```yaml
# config/phone_validation.yml
phone_validation:
  freq_valid_max: 5
  # ... resto da configuração

# dbt_project.yml  
vars: "{{ load_yaml('config/phone_validation.yml') }}"
```

### Benefícios da Abordagem Centralizada
1. **Fácil manutenção**: Todos os parâmetros em um local
2. **Flexibilidade por ambiente**: Diferentes configs para dev/staging/prod
3. **Versionamento**: Mudanças de regras rastreadas via git
4. **Consistência**: Todas as macros usam os mesmos valores
5. **Testabilidade**: Fácil de alterar valores para testes

### Exemplo de Configuração por Ambiente
```yaml
# profiles.yml
crm:
  target: dev
  outputs:
    dev:
      type: bigquery
      vars:
        phone_validation:
          freq_valid_max: 3  # Mais restritivo em dev
    
    prod:
      type: bigquery  
      vars:
        phone_validation:
          freq_valid_max: 5  # Valores de produção
```

## Cronograma de Implementação

### Sprint 1 (Semana 1)
- [x] Análise de requisitos e pipeline atual
- [ ] Configuração centralizada (phone_validation vars)
- [ ] Criação das macros de validação em `/macros/telefone/`
- [ ] Testes unitários das macros

### Sprint 2 (Semana 2)  
- [ ] Modelo `int_telefones_raw_consolidated` (padronização early)
- [ ] Modelo `int_rmi_telefones_consolidated` (schema RMI completo)
- [ ] Testes de validação de dados

### Sprint 3 (Semana 3)
- [ ] Integração com `int_pessoa_fisica_dim_telefone` (usar fonte padronizada)
- [ ] Modelo core `telefones.sql` (dimensão RMI)
- [ ] Testes de integração backward-compatible

### Sprint 4 (Semana 4)
- [ ] Modelo intermediate de aparições (se necessário)
- [ ] Documentação completa e testes de qualidade
- [ ] Deploy em staging e validação

### Sprint 5 (Semana 5)
- [ ] Validação em produção
- [ ] Monitoramento de performance (particionamento/clustering)
- [ ] Ajustes finais e otimizações

## Considerações Técnicas

### Performance
- **Particionamento**: Usar hash do telefone para distribuir dados
- **Materialização**: Table para core, ephemeral para intermediate
- **Índices**: Criar índices em `telefone_numero_completo` e `telefone_qualidade`

### Compatibilidade
- **Mantém estrutura atual**: Não quebra modelos downstream
- **Adiciona campos gradualmente**: Permite migração incremental
- **Usa macros reutilizáveis**: Facilita manutenção

### Monitoramento
- **Métricas de qualidade**: % de telefones VÁLIDOS vs SUSPEITOS vs INVÁLIDOS
- **Cobertura de classificação**: % de telefones classificados corretamente
- **Performance**: Tempo de execução dos modelos RMI

## Entregáveis

1. **Macros Organizadas** (`/macros/telefone/`): 10 macros especializadas
   - `validate_phone_quality.sql` - Validação de qualidade
   - `classify_phone_type.sql` - Classificação de tipo
   - `is_format_valid.sql` - Validação de formato
   - `has_suspicious_patterns.sql` - Detecção de padrões suspeitos
   - `has_dummy_patterns.sql` - Detecção de padrões falsos
   - `extract_ddi.sql` - Extração de DDI
   - `extract_ddd.sql` - Extração de DDD
   - `extract_numero.sql` - Extração de número
   - `get_nationality.sql` - Determinação de nacionalidade
   - `generate_hash.sql` - Geração de hash para auditoria

2. **Configuração Centralizada**: Arquivo YAML com todas as variáveis de validação

3. **Modelos Intermediate**: 
   - `int_telefones_raw_consolidated.sql` - Padronização early no pipeline
   - `int_rmi_telefones_consolidated.sql` - Schema RMI completo
   - `int_rmi_telefones_aparicoes.sql` - Aparições detalhadas (opcional)

4. **Modelos Core**: 
   - `telefones.sql` - Dimensão principal de telefones RMI

5. **Testes**: 15+ testes de qualidade e integridade

6. **Documentação**: YAML completo + este plano de implementação

### Benefícios da Organização em Pasta
- **Namespace claro**: Todas as macros de telefone agrupadas
- **Fácil manutenção**: Localização intuitiva das funções
- **Reutilização**: Macros podem ser facilmente referenciadas
- **Modularidade**: Cada macro tem responsabilidade específica
- **Versionamento**: Mudanças organizadas por domínio