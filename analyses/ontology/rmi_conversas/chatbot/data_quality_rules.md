# Regras de Qualidade de Dados - rmi_conversas.chatbot

## Visão Geral

Este documento define as regras de qualidade de dados para a tabela `rmi_conversas.chatbot`, incluindo validações, testes automatizados e métricas de monitoramento da qualidade.

## Categorias de Qualidade

### 1. Completude (Completeness)
Verificação de campos obrigatórios e cobertura de dados.

### 2. Precisão (Accuracy) 
Validação de formatos e valores válidos.

### 3. Consistência (Consistency)
Coerência entre campos relacionados.

### 4. Unicidade (Uniqueness)
Ausência de duplicatas indevidas.

### 5. Atualidade (Timeliness)
Freshness e recência dos dados.

## Regras por Campo

### Campos de Identificação

#### `id_conversa`
- **Tipo**: Obrigatório
- **Formato**: UUID válido
- **Unicidade**: Deve ser único na tabela
- **Teste**: 
  ```yaml
  tests:
    - unique
    - not_null
    - custom_uuid_format
  ```

#### `cpf_cidadao`
- **Tipo**: Opcional (meta: >70% cobertura)
- **Formato**: 11 dígitos numéricos quando presente
- **Validação**: CPF válido segundo algoritmo brasileiro
- **Teste**:
  ```yaml
  tests:
    - custom_cpf_format:
        where: "cpf_cidadao is not null"
    - custom_cpf_coverage:
        min_coverage: 0.70
  ```

#### `telefone_contato`
- **Tipo**: Obrigatório
- **Formato**: Mínimo 10 dígitos, máximo 15 dígitos
- **Validação**: Deve começar com código do país/DDD válido
- **Teste**:
  ```yaml
  tests:
    - not_null
    - custom_phone_format:
        min_length: 10
        max_length: 15
  ```

### Campos Temporais

#### `data_conversa`
- **Tipo**: Obrigatório
- **Range**: Entre 2020-01-01 e data atual
- **Consistência**: Deve ser <= `data_particao`
- **Teste**:
  ```yaml
  tests:
    - not_null
    - custom_date_range:
        min_date: '2020-01-01'
        max_date: 'current_date()'
    - custom_date_consistency:
        compare_field: 'data_particao'
        rule: 'less_than_or_equal'
  ```

#### `inicio_datahora`
- **Tipo**: Obrigatório
- **Range**: Entre 2020-01-01 00:00:00 e timestamp atual
- **Consistência**: Deve ser <= `fim_datahora` quando presente
- **Teste**:
  ```yaml
  tests:
    - not_null
    - custom_datetime_range:
        min_datetime: '2020-01-01 00:00:00'
        max_datetime: 'current_datetime()'
  ```

#### `fim_datahora`
- **Tipo**: Opcional
- **Consistência**: Deve ser >= `inicio_datahora`
- **Lógica**: Obrigatório para `tipo_conversa` != 'HSM_ONLY'
- **Teste**:
  ```yaml
  tests:
    - custom_datetime_sequence:
        start_field: 'inicio_datahora'
        end_field: 'fim_datahora'
    - custom_conditional_not_null:
        condition: "tipo_conversa != 'HSM_ONLY'"
  ```

### Campos de Classificação

#### `tipo_conversa`
- **Tipo**: Obrigatório
- **Valores**: ['HSM_ONLY', 'URA_COMPLETA', 'ATENDIMENTO_HUMANO']
- **Distribuição esperada**: HSM_ONLY ~30%, URA_COMPLETA ~60%, ATENDIMENTO_HUMANO ~10%
- **Teste**:
  ```yaml
  tests:
    - not_null
    - accepted_values:
        values: ['HSM_ONLY', 'URA_COMPLETA', 'ATENDIMENTO_HUMANO']
    - custom_distribution_check:
        field: 'tipo_conversa'
        expected_distribution:
          'HSM_ONLY': [0.20, 0.40]      # Entre 20% e 40%
          'URA_COMPLETA': [0.50, 0.70]   # Entre 50% e 70%
          'ATENDIMENTO_HUMANO': [0.05, 0.15] # Entre 5% e 15%
  ```

#### `desfecho_conversa`  
- **Tipo**: Obrigatório
- **Valores**: ['RESOLVIDA_AUTOMATICA', 'TRANSFERIDA_HUMANO', 'ABANDONADA']
- **Consistência**: 
  - Se `tipo_conversa` = 'ATENDIMENTO_HUMANO' → `desfecho_conversa` = 'TRANSFERIDA_HUMANO'
  - Se `teve_resposta_cidadao` = false → `desfecho_conversa` = 'ABANDONADA'
- **Teste**:
  ```yaml
  tests:
    - not_null  
    - accepted_values:
        values: ['RESOLVIDA_AUTOMATICA', 'TRANSFERIDA_HUMANO', 'ABANDONADA']
    - custom_business_rule_consistency
  ```

### Campos de Estatísticas

#### `total_mensagens`
- **Tipo**: Obrigatório
- **Range**: >= 0
- **Consistência**: Deve ser >= `mensagens_cidadao`
- **Lógica**: HSM_ONLY deve ter total_mensagens = 1
- **Teste**:
  ```yaml
  tests:
    - not_null
    - custom_non_negative
    - custom_message_count_consistency
  ```

#### `duracao_total_seg`
- **Tipo**: Opcional para HSM_ONLY, obrigatório para outros
- **Range**: >= 0, <= 86400 (24 horas)
- **Consistência**: Deve ser consistente com início/fim quando calculável
- **Teste**:
  ```yaml
  tests:
    - custom_duration_range:
        min_seconds: 0
        max_seconds: 86400
    - custom_duration_consistency
  ```

## Regras de Negócio Complexas

### 1. Consistência de Resposta
**Regra**: Se `teve_resposta_cidadao` = true, então `tipo_conversa` não pode ser 'HSM_ONLY'

```sql
-- Teste personalizado
select *
from {{ ref('chatbot') }}
where teve_resposta_cidadao = true 
  and tipo_conversa = 'HSM_ONLY'
```

### 2. Consistência de Desfecho
**Regra**: Desfecho deve ser coerente com outros indicadores

```sql
-- Regras de consistência
select *
from {{ ref('chatbot') }}
where (
  -- Regra 1: Atendimento humano → Transferida
  (tipo_conversa = 'ATENDIMENTO_HUMANO' and desfecho_conversa != 'TRANSFERIDA_HUMANO')
  
  -- Regra 2: Sem resposta → Abandonada  
  or (teve_resposta_cidadao = false and desfecho_conversa != 'ABANDONADA')
  
  -- Regra 3: HSM sem fim → Abandonada
  or (tipo_conversa = 'HSM_ONLY' and desfecho_conversa != 'ABANDONADA')
)
```

### 3. Coerência Temporal
**Regra**: Sequência temporal deve ser lógica

```sql
select *
from {{ ref('chatbot') }}
where inicio_datahora > fim_datahora
   or date(inicio_datahora) != data_conversa
   or data_conversa > data_particao
```

## Métricas de Qualidade

### 1. Taxa de Linkagem CPF
**Meta**: >= 70% das conversas com CPF identificado

```sql
select 
  count(*) as total_conversas,
  sum(case when cpf_cidadao is not null then 1 else 0 end) as com_cpf,
  safe_divide(
    sum(case when cpf_cidadao is not null then 1 else 0 end),
    count(*)
  ) as taxa_linkagem_cpf
from {{ ref('chatbot') }}
where data_particao >= current_date() - 7
```

### 2. Distribuição de Tipos de Conversa
**Meta**: Manter distribuição estável

```sql
select 
  tipo_conversa,
  count(*) as quantidade,
  count(*) / sum(count(*)) over () as percentual
from {{ ref('chatbot') }}
where data_particao >= current_date() - 30
group by tipo_conversa
```

### 3. Taxa de Conversas Completas
**Meta**: >= 80% das conversas têm duração calculável

```sql
select 
  count(*) as total,
  sum(case when duracao_total_seg is not null then 1 else 0 end) as com_duracao,
  safe_divide(
    sum(case when duracao_total_seg is not null then 1 else 0 end),
    count(*)
  ) as taxa_duracao_calculavel
from {{ ref('chatbot') }}
where data_particao >= current_date() - 7
  and tipo_conversa != 'HSM_ONLY'
```

## Alertas e Monitoramento

### 1. Alertas Críticos (Bloquear execução)
- Taxa de linkagem CPF < 50%
- >10% de registros com erro de consistência temporal
- >5% de registros com campos obrigatórios nulos

### 2. Alertas de Atenção (Log warning)
- Taxa de linkagem CPF entre 50-70%
- Mudança >20% na distribuição de tipos de conversa
- Aumento >50% em conversas abandonadas

### 3. Métricas de Freshness
- Dados devem estar atualizados D+1
- Partições não podem ter gaps >2 dias
- Volume diário não pode variar >30% da média móvel 7 dias

## Implementação dos Testes

### 1. Testes Básicos (dbt)
```yaml
# models/core/rmi_conversas/chatbot.yml
tests:
  - unique:
      column_name: id_conversa
  - not_null:
      column_name: id_conversa
  - accepted_values:
      column_name: tipo_conversa
      values: ['HSM_ONLY', 'URA_COMPLETA', 'ATENDIMENTO_HUMANO']
```

### 2. Testes Personalizados
```yaml
# data-tests/chatbot_quality_tests.yml
data_tests:
  - name: chatbot_cpf_linkage_rate
    sql: |
      {{ quality_check_cpf_linkage('chatbot', 0.70) }}
      
  - name: chatbot_business_consistency
    sql: |
      {{ quality_check_business_rules('chatbot') }}
```

### 3. Macros de Qualidade
Criar macros reutilizáveis em `macros/quality/`:
- `quality_check_cpf_linkage.sql`
- `quality_check_business_rules.sql`
- `quality_check_temporal_consistency.sql`