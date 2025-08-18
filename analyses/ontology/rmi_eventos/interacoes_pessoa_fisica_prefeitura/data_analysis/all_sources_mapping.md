# Mapeamento de Classificação - Todas as Fontes de Dados

## 📊 Visão Geral das Fontes Analisadas

| Sistema | Dataset | Tabela Principal | Registros | Tipo Interação | Status |
|---------|---------|------------------|-----------|----------------|--------|
| **1746 (SEGOVI)** | `joaoc__crm_eventos` | `governo_integridade__1746_chamado` | 14.2M | SOLICITACAO + REPORTE | ✅ Mapeado |
| **Wetalkie (WhatsApp)** | `brutos_wetalkie` | `fluxos_ura` | ~700 | COMUNICACAO | ✅ Analisado |
| **Bcadastro** | `brutos_bcadastro` | `cpf` | 207k | CADASTRO | ✅ Analisado |
| **SMS (Saúde)** | `brutos_sms` | `erro_sisreg` | ~3k | CONSUMO | ⚠️ Dados limitados |
| **SME (Educação)** | `brutos_sme` | `abandono_escolar_202507` | N/A | REPORTE | 📋 Identificado |

## 🏗️ Mapeamento Detalhado por Sistema

### **1. SEGOVI (1746) - Chamados Cidadão** ✅ **COMPLETO**

```yaml
tipo_interacao: [SOLICITACAO, REPORTE]
categoria_interacao: SERVICOS_URBANOS
canal_interacao: CENTRAL_TELEFONICA
modalidade_interacao: DIGITAL

volume: 14.227.710 registros
periodo: Histórico completo
qualidade_dados: Alta (schema estruturado)

principais_subcategorias:
  - limpeza_urbana_remocao_entulho (19.5%)
  - infraestrutura_iluminacao_publica (13.1%)
  - fiscalizacao_transito_estacionamento (9.1%)
  - limpeza_urbana_logradouros (5.6%)
  - infraestrutura_pavimentacao (5.5%)

status_resolucao:
  - RESOLVIDA: 65.2%
  - NAO_APLICAVEL: 15.0%
  - NAO_CONSTATADA: 8.2%
  - EM_ANDAMENTO: 2.1%
```

### **2. Wetalkie (WhatsApp) - Comunicação Digital** ✅ **ANALISADO**

```yaml
tipo_interacao: COMUNICACAO
categoria_interacao: COMUNICACAO_INSTITUCIONAL
canal_interacao: WHATSAPP
modalidade_interacao: DIGITAL

volume: ~700 sessões (amostra de desenvolvimento)
periodo: Dados de teste/desenvolvimento
qualidade_dados: Alta (schema estruturado com mensagens)

principais_fluxos:
  - EAI-GPT (chatbot principal): ~300 sessões
  - WEBSUMMIT (eventos): ~157 sessões  
  - IPLAN (planejamento): ~112 sessões

tipos_finalizacao:
  - Finalizado pelo cliente: 184 sessões
  - Finalizado por inatividade: 195 sessões
  - Finalizado na URA: 136 sessões

campos_chave:
  - mensagens: Array completo de conversas
  - tabulacao: Classificação do atendimento
  - contato: Identificação do cidadão
  - protocolo: Rastreabilidade

oportunidades:
  - Analisar sentimento das mensagens
  - Classificar temas das conversas
  - Medir efetividade do chatbot
  - Identificar padrões de abandono
```

### **3. Bcadastro - Cadastro Cidadão** ✅ **ANALISADO**

```yaml
tipo_interacao: CADASTRO
categoria_interacao: GESTAO_CADASTRAL
canal_interacao: POSTO_ATENDIMENTO | PORTAL_WEB
modalidade_interacao: FISICO | DIGITAL

volume: 207.470 registros CPF únicos
periodo: Base cadastral ativa
qualidade_dados: Alta (dados estruturados de cidadãos)

situacao_cadastral:
  - regular: 195.431 (94.2%)
  - titular_falecido: 10.665 (5.1%)
  - pendente_regularizacao: 1.120 (0.5%)
  - cancelada: 197 (0.1%)

dados_disponiveis:
  - Identificação completa (nome, CPF, nascimento)
  - Endereço residencial completo
  - Contatos (telefone, email)
  - Dados familiares (nome da mãe)
  - Ocupação profissional
  - Histórico de atualizações

aplicacoes_ontologia:
  - Base para unificação de identidade
  - Histórico de atualizações = interações CADASTRO
  - Segmentação demográfica para análises
  - Validação de qualidade de dados outros sistemas
```

### **4. SMS (Saúde) - SISREG Erros** ⚠️ **DADOS LIMITADOS**

```yaml
tipo_interacao: CONSUMO (implícito)
categoria_interacao: SAUDE
canal_interacao: UNIDADE_SAUDE
modalidade_interacao: FISICO

volume: ~3.000 registros (apenas erros)
periodo: Dados operacionais recentes
qualidade_dados: Média (focado em erros de sistema)

situacao_predominante:
  - SOL/AUT/REG: Solicitação autorizada/registrada

unidades_com_mais_erros:
  - CMS CARMELA DUTRA AP 33: 599 erros
  - CF MEDALHISTA OLIMPICO: 564 erros
  - CF ZILDA ARNS AP 31: 333 erros

limitacoes:
  - Apenas dados de erro (não representa volume total)
  - Falta dados de consultas, exames, procedimentos
  - Schema focado em problemas técnicos

recomendacoes:
  - Buscar tabelas SMS com dados de atendimento
  - Analisar episódios médicos completos
  - Mapear tipos de procedimento e especialidades
```

### **5. SME (Educação) - Abandono Escolar** 📋 **IDENTIFICADO**

```yaml
tipo_interacao: REPORTE (inferido)
categoria_interacao: EDUCACAO
canal_interacao: SISTEMA_INTERNO
modalidade_interacao: DIGITAL

volume: A ser analisado
periodo: 2025/07 (dados recentes)
qualidade_dados: A ser avaliada

contexto:
  - Dados sobre abandono escolar
  - Potencial para identificar vulnerabilidade social
  - Conexão com programas assistência social (SMAS)

proximos_passos:
  - Analisar schema da tabela
  - Identificar se há CPF para linkagem
  - Mapear tipos de abandono e causas
  - Conectar com dados SMAS para intervenção
```

## 🎯 Classificação Consolidada na Ontologia

### **Tipos de Interação por Volume (Estimado)**

```yaml
1. SOLICITACAO + REPORTE: ~14.2M (1746)
   - Dominam o volume total
   - Cidadãos solicitando/reportando problemas urbanos
   
2. CADASTRO: ~207k registros base + atualizações
   - Base cadastral de cidadãos ativos
   - Atualizações periódicas (frequência a determinar)
   
3. COMUNICACAO: Volume a expandir
   - WhatsApp em desenvolvimento (~700 teste)
   - Potencial massivo (campanhas, notificações)
   
4. CONSUMO: Volume significativo esperado
   - SMS: Dados limitados atuais
   - Potencial: milhões de consultas/exames/procedimentos
   
5. OUTROS: SME e novos sistemas
   - Educação: dados identificados
   - Outros sistemas municipais a mapear
```

### **Canais por Modalidade**

#### **DIGITAL (Predominante)**
- **CENTRAL_TELEFONICA**: 14.2M interações (1746)
- **WHATSAPP**: Em desenvolvimento, potencial alto
- **PORTAL_WEB**: Implícito em cadastros online
- **SISTEMA_INTERNO**: Dados operacionais (SMS, SME)

#### **FISICO (Significativo)**  
- **UNIDADE_SAUDE**: Volume alto esperado (SMS completo)
- **POSTO_ATENDIMENTO**: Cadastros e atualizações presenciais
- **EQUIPAMENTO_PUBLICO**: A ser mapeado (transporte)

### **Categorias por Domínio**

```yaml
SERVICOS_URBANOS: ████████████████████ 98% (1746)
GESTAO_CADASTRAL: █ 1% (Bcadastro)
COMUNICACAO_INSTITUCIONAL: ▌ 0.5% (Wetalkie teste)
SAUDE: ▌ 0.5% (SMS limitado)
EDUCACAO: ▌ <0.1% (SME identificado)
```

## 🏗️ Schema Unificado Proposto

### **Fact Interações Unificado**
```sql
-- fct_interacoes_cidadao_unified.sql
WITH todas_interacoes AS (
  
  -- 1746: Solicitações e Reportes
  SELECT
    GENERATE_UUID() as id_interacao,
    cpf as cpf_cidadao,
    id_chamado as protocolo_origem,
    'segovi' as sistema_origem,
    
    -- Classificação ontológica
    CASE 
      WHEN categoria LIKE '%solicitação%' THEN 'SOLICITACAO'
      ELSE 'REPORTE' 
    END as tipo_interacao,
    'SERVICOS_URBANOS' as categoria_interacao,
    'CENTRAL_TELEFONICA' as canal_interacao,
    'DIGITAL' as modalidade_interacao,
    
    -- Contexto temporal
    data_inicio as data_interacao,
    data_inicio as datahora_inicio,
    data_fim as datahora_fim,
    
    -- Resultado
    CASE 
      WHEN status = 'Fechado com solução' THEN 'RESOLVIDA'
      WHEN status = 'Sem possibilidade de atendimento' THEN 'NAO_APLICAVEL'
      WHEN status = 'Não constatado' THEN 'NAO_CONSTATADA'
      ELSE 'OUTROS'
    END as desfecho_interacao,
    
    -- Dados específicos
    STRUCT(tipo, subtipo, descricao, categoria, status) as dados_origem
    
  FROM {{ source('crm_eventos', 'governo_integridade__1746_chamado') }}
  WHERE cpf IS NOT NULL
  
  UNION ALL
  
  -- Wetalkie: Comunicações WhatsApp
  SELECT
    GENERATE_UUID() as id_interacao,
    contato.id as cpf_cidadao,
    protocolo as protocolo_origem,
    'wetalkie' as sistema_origem,
    
    'COMUNICACAO' as tipo_interacao,
    'COMUNICACAO_INSTITUCIONAL' as categoria_interacao,
    'WHATSAPP' as canal_interacao,
    'DIGITAL' as modalidade_interacao,
    
    inicio_data as data_interacao,
    inicio_datahora as datahora_inicio,
    fim_datahora as datahora_fim,
    
    CASE 
      WHEN tabulacao.nome LIKE '%cliente%' THEN 'RESOLVIDA'
      WHEN tabulacao.nome LIKE '%inatividade%' THEN 'ABANDONADA'
      ELSE 'OUTROS'
    END as desfecho_interacao,
    
    STRUCT(ura.nome, tabulacao.nome, canal, ARRAY_LENGTH(mensagens)) as dados_origem
    
  FROM {{ source('brutos_wetalkie', 'fluxos_ura') }}
  WHERE contato.id IS NOT NULL
  
  UNION ALL
  
  -- Bcadastro: Atualizações cadastrais
  SELECT
    GENERATE_UUID() as id_interacao,
    cpf as cpf_cidadao,
    CONCAT('bcad_', cpf, '_', atualizacao_data) as protocolo_origem,
    'bcadastro' as sistema_origem,
    
    'CADASTRO' as tipo_interacao,
    'GESTAO_CADASTRAL' as categoria_interacao,
    CASE 
      WHEN tipo = 'online' THEN 'PORTAL_WEB'
      ELSE 'POSTO_ATENDIMENTO' 
    END as canal_interacao,
    CASE 
      WHEN tipo = 'online' THEN 'DIGITAL'
      ELSE 'FISICO' 
    END as modalidade_interacao,
    
    atualizacao_data as data_interacao,
    DATETIME(atualizacao_data) as datahora_inicio,
    NULL as datahora_fim,
    
    CASE 
      WHEN situacao_cadastral_tipo = 'regular' THEN 'RESOLVIDA'
      WHEN situacao_cadastral_tipo = 'pendente_regularizacao' THEN 'PENDENTE'
      ELSE 'OUTROS'
    END as desfecho_interacao,
    
    STRUCT(situacao_cadastral_tipo, tipo, nome, endereco_municipio) as dados_origem
    
  FROM {{ source('brutos_bcadastro', 'cpf') }}
  WHERE cpf IS NOT NULL AND atualizacao_data IS NOT NULL
  
  -- SMS: A ser expandido quando dados completos disponíveis
  -- SME: A ser adicionado quando analisado
)

SELECT * FROM todas_interacoes
```

## 📋 Próximos Passos Recomendados

### **Prioridade Alta**
1. **Expandir dados SMS**: Buscar tabelas com consultas, exames, procedimentos completos
2. **Analisar SME**: Schema da tabela `abandono_escolar_202507`
3. **Implementar fact unificado**: Começar com 1746 + Wetalkie + Bcadastro

### **Prioridade Média**
4. **Buscar dados SMTR**: Transporte público (uso massivo esperado)
5. **Expandir Wetalkie**: Dados de produção (campanhas reais)
6. **Mapear SMAS**: Programas sociais e benefícios

### **Prioridade Baixa**
7. **Outros sistemas**: Cultura, meio ambiente, fazenda
8. **Dados históricos**: Expandir períodos de análise
9. **Dashboards**: Visualização da jornada do cidadão

## 💡 Insights Preliminares

### **Padrão de Interação dos Cariocas**
1. **Dominância Urban Services**: 98% das interações são sobre problemas urbanos
2. **Canal Telefônico Predominante**: 1746 ainda é o principal meio de contato
3. **Base Cadastral Sólida**: 207k cidadãos com dados estruturados  
4. **Potencial Digital**: WhatsApp em desenvolvimento, alta expectativa

### **Oportunidades de Integração**
1. **Identidade Única**: Bcadastro como base para unificar todas as interações
2. **Proatividade**: Usar padrões 1746 para antecipar problemas via WhatsApp
3. **Cross-selling**: Cidadãos que usam saúde podem precisar de serviços urbanos
4. **Prevenção**: Dados educação (abandono) conectar com assistência social

---

**🏛️ Este mapeamento consolida 14.4M+ interações em uma visão unificada de como os cariocas se relacionam com sua prefeitura!**