# Schema Simplificado para Facts v1 - Interações Cidadão-Prefeitura

## 🎯 Princípios da v1
- **Simplicidade**: Apenas campos essenciais para funcionar
- **Dados Disponíveis**: Baseado no que realmente temos (1746, Wetalkie, Bcadastro)
- **Evolução**: Estrutura preparada para crescer sem quebrar
- **Implementação Rápida**: Menos de 20 campos core

## 🏗️ Schema v1 - Campos Essenciais

### **1. IDENTIFICAÇÃO** 🆔 - **4 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `id_interacao` | STRING | ✅ | UUID único | `not_null`, `unique` |
| `cpf_cidadao` | STRING | ✅ | CPF do cidadão | `not_null`, `matches_regex('^\\d{11}$')` |
| ~~`cnpj_empresa`~~ | ~~STRING~~ | ❌ | **v2** - Poucos casos B2B | |
| ~~`tipo_pessoa`~~ | ~~STRING~~ | ❌ | **v2** - Inferido do CPF/CNPJ | |
| ~~`id_pessoa_relacionada`~~ | ~~STRING~~ | ❌ | **v2** - Casos específicos | |

### **2. ORIGEM E RASTREABILIDADE** 📋 - **3 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `sistema_origem` | STRING | ✅ | Sistema fonte | `accepted_values(['segovi', 'wetalkie', 'bcadastro'])` |
| `protocolo_origem` | STRING | ✅ | ID original | `not_null` |
| ~~`versao_modelo`~~ | ~~STRING~~ | ❌ | **Auto** - Controle via dbt | |
| ~~`processado_em`~~ | ~~TIMESTAMP~~ | ❌ | **Auto** - `_airbyte_emitted_at` | |

### **3. CLASSIFICAÇÃO ONTOLÓGICA** 🏷️ - **2 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `tipo_interacao` | STRING | ✅ | Tipo principal | `accepted_values(['SOLICITACAO', 'REPORTE', 'COMUNICACAO', 'CADASTRO'])` |
| `categoria_interacao` | STRING | ✅ | Categoria | `accepted_values(['SERVICOS_URBANOS', 'COMUNICACAO_INSTITUCIONAL', 'GESTAO_CADASTRAL'])` |
| ~~`subcategoria`~~ | ~~STRING~~ | ❌ | **v2** - Análise mais madura | |
| ~~`especificacao`~~ | ~~STRING~~ | ❌ | **v2** - Preservado em JSON | |
| ~~`tags_classificacao`~~ | ~~ARRAY~~ | ❌ | **v2** - Complexidade desnecessária | |

### **4. CANAL E MODALIDADE** 📱 - **2 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `canal_interacao` | STRING | ✅ | Canal usado | Lista simplificada (abaixo) |
| `modalidade_interacao` | STRING | ✅ | Digital/Físico | `accepted_values(['DIGITAL', 'FISICO'])` |

**Canais v1 (apenas os que temos dados):**
```sql
'CENTRAL_TELEFONICA',    -- 1746
'WHATSAPP',              -- Wetalkie  
'POSTO_ATENDIMENTO'      -- Bcadastro presencial
'PORTAL_WEB'             -- Bcadastro online (futuro)
```

### **5. CONTEXTO TEMPORAL** ⏰ - **3 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `data_interacao` | DATE | ✅ | Data da interação | `not_null`, `>= '2020-01-01'` |
| `datahora_inicio` | TIMESTAMP | ✅ | Timestamp início | `not_null` |
| `data_particao` | DATE | ✅ | Para particionamento | `= data_interacao` |
| ~~`datahora_fim`~~ | ~~TIMESTAMP~~ | ❌ | **v2** - Poucos sistemas têm | |
| ~~`duracao_minutos`~~ | ~~INTEGER~~ | ❌ | **v2** - Calculado quando relevante | |
| ~~`ano_particao`~~ | ~~STRING~~ | ❌ | **Desnecessário** - `EXTRACT(YEAR FROM data_particao)` | |
| ~~`mes_particao`~~ | ~~STRING~~ | ❌ | **Desnecessário** - `EXTRACT(MONTH FROM data_particao)` | |

### **6. LOCALIZAÇÃO** 🗺️ - **1 campo**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `bairro_interacao` | STRING | ❌ | Bairro (quando disponível) | Texto livre |
| ~~`id_estabelecimento`~~ | ~~STRING~~ | ❌ | **v2** - Precisa dim_estabelecimento | |
| ~~`endereco_interacao`~~ | ~~STRUCT~~ | ❌ | **v2** - Complexo para início | |
| ~~`area_planejamento`~~ | ~~INTEGER~~ | ❌ | **v2** - Derivado de bairro | |
| ~~`regiao_administrativa`~~ | ~~STRING~~ | ❌ | **v2** - Derivado de bairro | |
| ~~`coordenadas`~~ | ~~GEOGRAPHY~~ | ❌ | **v2** - Poucos dados têm lat/lng | |

### **7. STATUS E RESULTADO** ✅ - **1 campo**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `desfecho_interacao` | STRING | ❌ | Resultado quando disponível | Lista simplificada (abaixo) |
| ~~`status_interacao`~~ | ~~STRING~~ | ❌ | **v2** - Confunde com desfecho | |
| ~~`satisfacao_cidadao`~~ | ~~STRING~~ | ❌ | **v2** - Poucos sistemas coletam | |
| ~~`prioridade_interacao`~~ | ~~STRING~~ | ❌ | **v2** - Não disponível | |
| ~~`motivo_cancelamento`~~ | ~~STRING~~ | ❌ | **v2** - Específico demais | |

**Desfechos v1 (simplificados):**
```sql
'RESOLVIDA',           -- Sucesso
'NAO_RESOLVIDA',       -- Problema não solucionado  
'NAO_APLICAVEL',       -- Não se aplica
'EM_ANDAMENTO'         -- Ainda processando
```

### **8. ~~MÉTRICAS E VALORES~~** 💰 - **0 campos v1**
> **Todos para v2** - Poucos sistemas têm valores monetários inicialmente

### **9. DADOS FLEXÍVEIS** 🔄 - **1 campo**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `dados_origem` | JSON | ✅ | Dados originais preservados | `not_null`, `valid_json()` |
| ~~`metadados_tecnicos`~~ | ~~JSON~~ | ❌ | **Auto** - Airbyte já fornece | |
| ~~`dados_integracao`~~ | ~~JSON~~ | ❌ | **v2** - Quando houver integrações | |

---

## 📊 **RESUMO v1: 17 campos totais**

### **Campos Obrigatórios (11):**
1. `id_interacao` 
2. `cpf_cidadao`
3. `sistema_origem`
4. `protocolo_origem` 
5. `tipo_interacao`
6. `categoria_interacao`
7. `canal_interacao`
8. `modalidade_interacao`
9. `data_interacao`
10. `datahora_inicio`
11. `data_particao`

### **Campos Opcionais (6):**
12. `bairro_interacao`
13. `desfecho_interacao`
14. `dados_origem`

### **Total Removido da Especificação Original: ~25 campos**
- Complexidades desnecessárias para v1
- Campos que poucos sistemas preenchem  
- Derivações automáticas
- Funcionalidades avançadas para v2+

## 🛠️ Implementação v1 Simplificada

### **Schema YAML Mínimo**
```yaml
# models/core/facts/schema.yml
version: 2

models:
  - name: fct_interacoes_cidadao_v1
    description: "Fact table v1 - interações cidadão-prefeitura (simplificado)"
    
    columns:
      # CAMPOS OBRIGATÓRIOS
      - name: id_interacao
        tests: [not_null, unique]
        
      - name: cpf_cidadao
        tests: 
          - not_null
          - dbt_utils.matches_regex:
              regex: '^\\d{11}$'
              
      - name: sistema_origem
        tests:
          - not_null
          - accepted_values:
              values: ['segovi', 'wetalkie', 'bcadastro']
              
      - name: tipo_interacao
        tests:
          - not_null
          - accepted_values:
              values: ['SOLICITACAO', 'REPORTE', 'COMUNICACAO', 'CADASTRO']
              
      - name: categoria_interacao
        tests:
          - not_null
          - accepted_values:
              values: ['SERVICOS_URBANOS', 'COMUNICACAO_INSTITUCIONAL', 'GESTAO_CADASTRAL']
              
      - name: canal_interacao
        tests:
          - not_null
          - accepted_values:
              values: ['CENTRAL_TELEFONICA', 'WHATSAPP', 'POSTO_ATENDIMENTO', 'PORTAL_WEB']
              
      - name: modalidade_interacao
        tests:
          - not_null
          - accepted_values:
              values: ['DIGITAL', 'FISICO']
              
      - name: data_interacao
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "data_interacao >= '2020-01-01'"
              
      - name: data_particao
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "data_particao = data_interacao"
```

### **Modelo SQL v1**
```sql
-- models/core/facts/fct_interacoes_cidadao_v1.sql
{{ config(
    materialized='table',
    schema='crm_eventos',
    partition_by={'field': 'data_particao', 'data_type': 'date'},
    cluster_by=['sistema_origem', 'tipo_interacao']
) }}

WITH dados_unificados AS (
  SELECT * FROM {{ ref('int_interacoes_1746_v1') }}
  UNION ALL
  SELECT * FROM {{ ref('int_interacoes_wetalkie_v1') }}
  UNION ALL  
  SELECT * FROM {{ ref('int_interacoes_bcadastro_v1') }}
)

SELECT
  -- IDENTIFICAÇÃO (4)
  COALESCE(id_interacao, GENERATE_UUID()) as id_interacao,
  cpf_cidadao,
  
  -- ORIGEM (3)  
  sistema_origem,
  protocolo_origem,
  
  -- CLASSIFICAÇÃO (2)
  tipo_interacao,
  categoria_interacao,
  
  -- CANAL (2)
  canal_interacao,
  modalidade_interacao,
  
  -- TEMPORAL (3)
  data_interacao,
  datahora_inicio,
  data_interacao as data_particao,
  
  -- LOCALIZAÇÃO (1)
  bairro_interacao,
  
  -- RESULTADO (1)
  desfecho_interacao,
  
  -- FLEXÍVEL (1)
  COALESCE(dados_origem, JSON '{}') as dados_origem

FROM dados_unificados
WHERE cpf_cidadao IS NOT NULL 
  AND REGEXP_CONTAINS(cpf_cidadao, r'^\d{11}$')
  AND data_interacao >= '2020-01-01'
```

## 🎯 Benefícios da v1 Simplificada

### **✅ Vantagens:**
1. **Implementação Rápida**: 17 campos vs 40+ da spec completa
2. **Dados Reais**: Baseado no que realmente temos disponível
3. **Menos Bugs**: Menos validações complexas para falhar
4. **Performance**: Tabela menor e mais rápida
5. **Evolução**: Estrutura permite crescimento incremental

### **⚠️ Limitações Aceitas:**
1. **Menos Granularidade**: Subcategorias ficam em JSON por ora
2. **Localização Simples**: Apenas bairro, sem coordenadas
3. **Métricas Básicas**: Valores ficam para v2
4. **Satisfação**: Não medimos qualidade inicialmente

## 📋 Roadmap de Evolução

### **v1.1 (Quick Wins)**
- Adicionar `subcategoria` quando mapeamento estiver maduro
- Incluir `datahora_fim` para sistemas que têm
- Expandir lista de canais conforme novos sistemas

### **v2.0 (Funcionalidades Avançadas)**
- Localização completa (coordenadas, APs, RAs)
- Métricas e valores monetários
- Satisfação e qualidade
- Integração com outras dimensões

### **v3.0 (Analytics Avançados)**
- Jornada do cidadão
- Predição e ML
- Dashboards executivos

---

**🚀 Esta v1 permite começar a usar os dados de interação HOJE, com 80% do valor em 20% da complexidade!**