# Ontologia de Interações Cidadão-Prefeitura

## 🎯 Visão Geral

Esta ontologia **unifica todas as interações entre cidadãos e a Prefeitura do Rio de Janeiro** em um modelo de dados padronizado. O objetivo é transformar dados fragmentados de diferentes sistemas (1746, SMS, Wetalkie, Bcadastro, etc.) em uma **visão 360° de como os cariocas interagem com sua cidade**.

A ontologia classifica cada interação por **tipo** (o que o cidadão está fazendo), **categoria** (área municipal) e **canal** (como está interagindo), permitindo análises integradas de jornada do cidadão, eficiência operacional e planejamento de serviços.

## 🏗️ Conceitos Principais

### **Tipos de Interação** (Como o cidadão interage)
| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| **SOLICITACAO** | Cidadão pede algo à prefeitura | Remoção de entulho, reparo de iluminação |
| **CONSUMO** | Cidadão usa um serviço municipal | Consulta médica, viagem de ônibus |
| **REPORTE** | Cidadão informa sobre problema | Buraco na rua, foco da dengue |
| **COMUNICACAO** | Prefeitura comunica com cidadão | WhatsApp, SMS, notificação |
| **CADASTRO** | Atualização de dados pessoais | Alteração de endereço, renovação |

### **Categorias de Interação** (Área municipal)
| Categoria | Sistema Principal | Volume Estimado |
|-----------|------------------|-----------------|
| **SERVICOS_URBANOS** | 1746 (SEGOVI) | 14.2M interações |
| **COMUNICACAO_INSTITUCIONAL** | Wetalkie | Em desenvolvimento |
| **GESTAO_CADASTRAL** | Bcadastro | 207k cidadãos ativos |
| **SAUDE** | SMS | A expandir |
| **TRANSPORTE** | SMTR | A mapear |
| **ASSISTENCIA_SOCIAL** | SMAS | A mapear |

## 📊 Schema v1.1 Implementado ⭐ **Atualizado**

O **fact table unificado** possui **21 campos essenciais** organizados em 9 categorias funcionais:

- **🆔 Identificação**: `id_interacao`, `cpf_cidadao`
- **📋 Origem**: `sistema_origem`, `protocolo_origem`  
- **🏷️ Classificação**: `tipo_interacao`, `categoria_interacao`, **`subcategoria_interacao`**, **`descricao_interacao`** ⭐
- **📱 Canal**: `canal_interacao`, `modalidade_interacao`
- **⏰ Temporal**: `data_interacao`, `datahora_inicio`, `data_particao`
- **🗺️ Localização**: `bairro_interacao`, `endereco_interacao`, `coordenadas`
- **✅ Resultado**: `desfecho_interacao`
- **🔄 Flexível**: `dados_origem` (JSON)
- **🏗️ Metadados**: `_datalake_loaded_at`, `_schema_version`

### **⭐ Principais Melhorias v1.1:**
- **`subcategoria_interacao`**: Identifica o **objeto específico** da interação (ex: "LIMPEZA_URBANA_REMOCAO_ENTULHO")
- **`descricao_interacao`**: Descrição aberta para contexto adicional quando disponível
- **Localização expandida**: Campos estruturados para análise geográfica completa

> 📋 **Detalhes completos**: Ver [`fact_schema.md`](#-schema-de-dados)

## 📚 Documentação

### **🏗️ Schema de Dados**
- **[`fact_schema.md`](fact_schema.md)** - Schema oficial v1 com 17 campos, validações e exemplo de implementação

### **📚 Conceitos e Definições**
- **[`interaction_types_definition.md`](interaction_types_definition.md)** - Definição detalhada dos 5 tipos de interação com critérios e exemplos
- **[`channel_classification.md`](channel_classification.md)** - Classificação completa de canais digitais, físicos e híbridos

### **📊 Análises de Dados**
- **[`data_analysis/1746_classification_mapping.md`](data_analysis/1746_classification_mapping.md)** - Análise específica dos 14.2M chamados do sistema 1746
- **[`data_analysis/all_sources_mapping.md`](data_analysis/all_sources_mapping.md)** - Mapeamento consolidado de todas as fontes de dados

## 🚀 Status de Implementação

### **✅ v1.1 - Implementada e Funcionando** ⭐
- **Schema expandido**: 21 campos com subcategorias e descrições
- **Dados em produção**: 3.4M interações do 1746 carregadas
- **Fontes mapeadas**: 1746 completo, Wetalkie/Bcadastro (skeleton)
- **Validações criadas**: 28 testes dbt (22 passando)
- **Performance**: Particionamento e clustering otimizados

### **📋 v2.0 - Planejada**
- **Campos adicionais**: Subcategorias, métricas, satisfação
- **Novas fontes**: SMS, SMTR, SMAS completos
- **Localização avançada**: Coordenadas, APs, RAs
- **Analytics**: Dashboards de jornada do cidadão

## 💡 Casos de Uso

### **Analytics Cross-Sistema**
```sql
-- Cidadãos mais ativos por categoria
SELECT cpf_cidadao, categoria_interacao, COUNT(*) as interacoes
FROM fct_interacoes_cidadao 
GROUP BY 1,2 ORDER BY 3 DESC
```

### **Jornada do Cidadão**
```sql
-- Sequência de interações de um cidadão
SELECT data_interacao, tipo_interacao, canal_interacao, desfecho_interacao
FROM fct_interacoes_cidadao 
WHERE cpf_cidadao = '12345678901'
ORDER BY datahora_inicio
```

### **Eficiência Operacional**
```sql
-- Taxa de resolução por canal
SELECT canal_interacao, 
       COUNT(*) as total,
       AVG(CASE WHEN desfecho_interacao = 'RESOLVIDA' THEN 1.0 ELSE 0.0 END) as taxa_resolucao
FROM fct_interacoes_cidadao
GROUP BY 1
```

## 🎯 Benefícios

### **Para Gestão Pública**
- **Visão 360°**: Todas as interações do cidadão em um só lugar
- **Otimização**: Identificar gargalos e oportunidades de melhoria
- **Planejamento**: Demanda real por serviços e regiões
- **Proatividade**: Antecipar necessidades baseado em padrões

### **Para Cidadãos**
- **Atendimento Integrado**: Histórico unificado cross-sistemas
- **Experiência Melhorada**: Redução de retrabalho e espera
- **Personalização**: Serviços adaptados ao perfil de uso

### **Para Desenvolvimento**
- **Padronização**: Schema único para novos sistemas
- **Escalabilidade**: Estrutura preparada para crescimento
- **Governança**: Taxonomia centralizada e versionada

---

**🏛️ Esta ontologia é a base técnica para transformar o Rio de Janeiro em uma cidade verdadeiramente centrada no cidadão, com dados unificados e inteligência operacional.**