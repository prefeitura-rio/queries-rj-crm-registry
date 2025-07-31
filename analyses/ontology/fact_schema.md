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

### **2. ORIGEM E RASTREABILIDADE** 📋 - **3 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `sistema_origem` | STRING | ✅ | Sistema fonte | `accepted_values(['segovi', 'wetalkie', 'bcadastro'])` |
| `protocolo_origem` | STRING | ✅ | ID original | `not_null` |

### **3. CLASSIFICAÇÃO ONTOLÓGICA** 🏷️ - **4 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `tipo_interacao` | STRING | ✅ | Tipo baseado na natureza da solicitação | `accepted_values(['SOLICITACAO', 'REPORTE', 'FISCALIZACAO', 'INFORMACAO'])` |
| `categoria_interacao` | STRING | ✅ | Categoria baseada no domínio do serviço | `accepted_values(['INFRAESTRUTURA_URBANA', 'LIMPEZA_URBANA', 'FISCALIZACAO', 'MEIO_AMBIENTE', 'TRANSPORTE', 'SAUDE', 'ASSISTENCIA_SOCIAL', 'SERVICOS_PUBLICOS'])` |
| `subcategoria_interacao` | STRING | ✅ | **Objeto específico da interação** | Texto livre com valores principais mapeados |
| `descricao_interacao` | STRING | ❌ | Descrição aberta (quando disponível) | Texto livre, máx 500 chars |

**Subcategorias v2.0 (50 subcategorias mapeadas):**

**🏗️ INFRAESTRUTURA_URBANA (28.0%):**
- `INFRAESTRUTURA_ILUMINACAO_PUBLICA` - 15.8%
- `INFRAESTRUTURA_PAVIMENTACAO` - 5.6%  
- `INFRAESTRUTURA_DRENAGEM` - 3.6%
- `INFRAESTRUTURA_SINALIZACAO` - 2.8%
- `INFRAESTRUTURA_MOBILIARIO_URBANO` - 0.2%

**🧹 LIMPEZA_URBANA (34.5%):**
- `LIMPEZA_URBANA_REMOCAO_ENTULHO` - 18.9%
- `LIMPEZA_URBANA_LOGRADOUROS` - 15.1%
- `LIMPEZA_URBANA_EQUIPAMENTOS` - 0.4%
- `LIMPEZA_URBANA_COLETA_SELETIVA` - 0.1%

**👮 FISCALIZACAO (17.7%):**
- `FISCALIZACAO_TRANSITO_ESTACIONAMENTO` - 9.4%
- `FISCALIZACAO_ESTRUTURA_IMOVEL` - 3.1%
- `FISCALIZACAO_POLUICAO_SONORA` - 2.9%
- `FISCALIZACAO_VIAS_PUBLICAS` - 1.0%
- `FISCALIZACAO_COMERCIO_AMBULANTE` - 0.5%
- `FISCALIZACAO_VEICULO_ABANDONADO` - 0.5%
- `FISCALIZACAO_OCUPACAO_AREA_PUBLICA` - 0.2%
- `FISCALIZACAO_LIMPEZA_TERRENOS` - 0.2%
- `FISCALIZACAO_POSTURA_MUNICIPAL` - 0.1%

**🌿 MEIO_AMBIENTE (7.8%):**
- `MEIO_AMBIENTE_CONTROLE_VETORES` - 3.6%
- `MEIO_AMBIENTE_PROTECAO_ANIMAIS` - 2.5%
- `MEIO_AMBIENTE_MANEJO_ARVORES` - 1.3%
- `MEIO_AMBIENTE_CONTROLE_POLUICAO` - 0.4%
- `MEIO_AMBIENTE_PARQUES_PRACAS` - 0.1%

**🚌 TRANSPORTE (3.1%):**
- `TRANSPORTE_PUBLICO_ONIBUS` - 2.9%
- `TRANSPORTE_TAXI` - 0.2%
- `TRANSPORTE_REGULAMENTACAO_VIARIA` - 0.1%
- `TRANSPORTE_ESPECIAL` - 0.1%
- `TRANSPORTE_CICLOVIAS` - 0.02%

**🏥 SAUDE (2.4%):**
- `SAUDE_PROGRAMAS_ESPECIAIS` - 1.2%
- `SAUDE_ZOONOSES_CONTROLE_ANIMAIS` - 0.7%
- `VIGILANCIA_SANITARIA` - 0.4%
- `SAUDE_EMERGENCIA_SANITARIA` - 0.2%
- `SAUDE_INFRAESTRUTURA` - 0.03%

**🤝 ASSISTENCIA_SOCIAL (2.8%):**
- `ASSISTENCIA_SOCIAL_ATENDIMENTO` - 2.8%
- `DIREITOS_HUMANOS_ASSISTENCIA` - 0.03%

**📋 SERVICOS_PUBLICOS (3.4%):**
- `SERVICOS_DOCUMENTOS_TECNICOS` - 1.1%
- `LICENCIAMENTO_ALVARA` - 1.0%
- `SERVICOS_ATENDIMENTO_CIDADAO` - 0.4%
- `DIREITOS_CONSUMIDOR` - 0.4%
- `SERVICOS_PROCESSOS_ADMINISTRATIVOS` - 0.1%
- `SERVICOS_QUALIDADE_ATENDIMENTO` - 0.04%
- `DEFESA_CIVIL_GEOTECNIA` - 0.2%
- `OBRAS_PUBLICAS` - 0.02%
- `SERVICOS_FUNERARIOS` - 0.02%
- `PATRIMONIO_PUBLICIDADE` - 0.02%
- `EDUCACAO` - 0.03%
- `CULTURA_ESPORTE_LAZER` - 0.01%
- `TRABALHO_INCLUSAO` - 0.002%
- `SERVICOS_DIGITAIS` - 0.001%

**❓ OUTROS (0.26%):**
- `OUTROS_SERVICOS_URBANOS` - 0.03%

### **4. CANAL E MODALIDADE** 📱 - **2 campos**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `canal_interacao` | STRING | ✅ | Canal usado | Lista simplificada (abaixo) |
| `modalidade_interacao` | STRING | ✅ | Digital/Físico | `accepted_values(['DIGITAL', 'FISICO'])` |

**Canais v1 (apenas os que temos dados):**```sql
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

### **6. LOCALIZAÇÃO** 🗺️ - **1 campo**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `bairro_interacao` | STRING | ❌ | Bairro (quando disponível) | Texto livre |
| `endereco_interacao` | STRUCT | ❌ |  | |
| `coordenadas` | GEOGRAPHY | ❌  |  | |

### **7. STATUS E RESULTADO** ✅ - **1 campo**

| Campo | Tipo | Obrigatório | Descrição | Validação |
|-------|------|-------------|-----------|-----------|
| `desfecho_interacao` | STRING | ❌ | Resultado quando disponível | Lista simplificada (abaixo) |

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

---

## 📊 **RESUMO v1.1: 21 campos totais**

### **Campos Obrigatórios (13):**
1. `id_interacao` 
2. `cpf_cidadao`
3. `sistema_origem`
4. `protocolo_origem` 
5. `tipo_interacao`
6. `categoria_interacao`
7. **`subcategoria_interacao`** ⭐ **NOVO**
8. `canal_interacao`
9. `modalidade_interacao`
10. `data_interacao`
11. `datahora_inicio`
12. `data_particao`

### **Campos Opcionais (8):**
13. **`descricao_interacao`** ⭐ **NOVO**
14. `bairro_interacao`
15. `endereco_interacao`
16. `coordenadas`
17. `desfecho_interacao`
18. `dados_origem`
19. `_datalake_loaded_at`
20. `_schema_version`

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
  -- IDENTIFICAÇÃO (2)
  COALESCE(id_interacao, GENERATE_UUID()) as id_interacao,
  cpf_cidadao,
  
  -- ORIGEM (2)  
  sistema_origem,
  protocolo_origem,
  
  -- CLASSIFICAÇÃO ONTOLÓGICA (4) ⭐ EXPANDIDA
  tipo_interacao,
  categoria_interacao,
  subcategoria_interacao,    -- NOVO: objeto específico
  descricao_interacao,       -- NOVO: descrição aberta
  
  -- CANAL (2)
  canal_interacao,
  modalidade_interacao,
  
  -- TEMPORAL (3)
  data_interacao,
  datahora_inicio,
  data_interacao as data_particao,
  
  -- LOCALIZAÇÃO (3)
  bairro_interacao,
  endereco_interacao,
  coordenadas,
  
  -- RESULTADO (1)
  desfecho_interacao,
  
  -- FLEXÍVEL (1)
  COALESCE(dados_origem, JSON '{}') as dados_origem,
  
  -- METADADOS (2)
  CURRENT_TIMESTAMP() as _datalake_loaded_at,
  '1.1' as _schema_version

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

### **✅ Melhorias v1.1 (Implementadas):**
1. **✅ Subcategoria**: Campo `subcategoria_interacao` obrigatório para identificar objeto específico
2. **✅ Descrição**: Campo `descricao_interacao` opcional para contexto adicional
3. **✅ Localização Expandida**: Campos `endereco_interacao` e `coordenadas` para análise geográfica

### **⚠️ Limitações Remanescentes:**
1. **Localização Avançada**: APs, RAs e validações geográficas para v2
2. **Métricas Básicas**: Valores monetários ficam para v2
3. **Satisfação**: Não medimos qualidade inicialmente

## 📋 Roadmap de Evolução

### **v1.2 (Quick Wins)**
- Incluir `datahora_fim` para sistemas que têm
- Expandir lista de canais conforme novos sistemas
- Implementar mapeamento de subcategorias do Wetalkie e Bcadastro

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
