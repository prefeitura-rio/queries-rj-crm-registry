# Ontologia de Interações Cidadão-Prefeitura

## 📋 Visão Geral

Esta ontologia classifica **todas as interações entre cidadãos e a Prefeitura do Rio de Janeiro**, independente do sistema de origem. O foco está em entender **como**, **onde** e **por que** os cidadãos interagem com os serviços municipais.

## 🎯 Conceito Central: **INTERAÇÃO**

Uma **interação** é qualquer evento em que um cidadão:
- **Solicita** um serviço público
- **Reporta** um problema  
- **Consome** um serviço municipal
- **Recebe** uma comunicação da prefeitura
- **Acessa** um canal de atendimento

## 🏗️ Estrutura Hierárquica

```
TIPO_INTERACAO → CATEGORIA_INTERACAO → CANAL → SUBCATEGORIA_ESPECIFICA
```

### **1. TIPOS DE INTERAÇÃO** (Como o cidadão interage)

| Tipo | Descrição | Exemplos |
|------|-----------|----------|
| **SOLICITACAO** | Cidadão pede algo à prefeitura | Remoção de entulho, reparo de iluminação |
| **CONSUMO** | Cidadão usa um serviço municipal | Consulta médica, transporte público |
| **REPORTE** | Cidadão informa sobre problema | Buraco na rua, foco da dengue |
| **COMUNICACAO** | Prefeitura comunica com cidadão | WhatsApp, SMS, notificação |
| **CADASTRO** | Atualização de dados pessoais | Alteração de endereço, dados biométricos |

### **2. CATEGORIAS DE INTERAÇÃO** (Área temática)

| Categoria | Descrição | Sistemas |
|-----------|-----------|----------|
| **SAUDE** | Serviços de saúde pública | SMS |
| **SERVICOS_URBANOS** | Manutenção e infraestrutura urbana | 1746 |
| **TRANSPORTE** | Mobilidade urbana | SMTR |
| **ASSISTENCIA_SOCIAL** | Programas sociais | SMAS |
| **EDUCACAO** | Serviços educacionais | SME |
| **COMUNICACAO_INSTITUCIONAL** | Canais de atendimento | Wetalkie |
| **GESTAO_CADASTRAL** | Dados pessoais e documentos | Bcadastro |

### **3. CANAIS DE INTERAÇÃO** (Onde acontece)

#### **3.1 Canais Digitais**
- **WHATSAPP** - Chatbot e atendimento
- **PORTAL_WEB** - Sites e portais municipais  
- **APP_MOBILE** - Aplicativos móveis
- **EMAIL** - Comunicação eletrônica
- **CENTRAL_TELEFONICA** - 1746 e call centers

#### **3.2 Canais Físicos**
- **UNIDADE_SAUDE** - UPAs, clínicas, hospitais
- **POSTO_ATENDIMENTO** - Postos de atendimento ao cidadão
- **EQUIPAMENTO_PUBLICO** - Ônibus, estações, totens
- **VIA_PUBLICA** - Interações na rua (fiscalização)
- **DOMICILIO** - Atendimento residencial

## 📊 Mapeamento por Sistema

### **1746 (SEGOVI) - Chamados Cidadão**
```yaml
tipo_interacao: SOLICITACAO | REPORTE
categoria_interacao: SERVICOS_URBANOS
canal: CENTRAL_TELEFONICA | PORTAL_WEB | APP_MOBILE
modalidade: DIGITAL

subcategorias:
  INFRAESTRUTURA_URBANA:
    - iluminacao_publica
    - pavimentacao  
    - sinalizacao_transito
    - drenagem_pluvial
  LIMPEZA_URBANA:
    - remocao_entulho
    - coleta_lixo
    - capina_varrição
  MEIO_AMBIENTE:
    - poda_arvores
    - controle_vetores
    - denuncia_poluicao
  FISCALIZACAO:
    - estacionamento_irregular
    - obras_irregulares
    - comercio_irregular
```

### **SMS (Saúde) - Episódios Médicos**  
```yaml
tipo_interacao: CONSUMO
categoria_interacao: SAUDE
canal: UNIDADE_SAUDE
modalidade: FISICO

subcategorias:
  ATENDIMENTO_AMBULATORIAL:
    - consulta_clinica_geral
    - consulta_especializada
    - procedimento_ambulatorial
  URGENCIA_EMERGENCIA:
    - atendimento_upa
    - atendimento_emergencia
    - regulacao_samu
  EXAMES_DIAGNOSTICOS:
    - laboratorio
    - radiologia
    - ultrassonografia
```

### **SMTR (Transporte) - Uso do Transporte**
```yaml
tipo_interacao: CONSUMO
categoria_interacao: TRANSPORTE
canal: EQUIPAMENTO_PUBLICO
modalidade: FISICO

subcategorias:
  TRANSPORTE_COLETIVO:
    - onibus_municipal
    - brt_transoeste
    - integracao_modal
  MOBILIDADE_COMPARTILHADA:
    - bike_rio
    - patinete_eletrico
```

### **Wetalkie (WhatsApp) - Comunicação Digital**
```yaml
tipo_interacao: COMUNICACAO
categoria_interacao: COMUNICACAO_INSTITUCIONAL  
canal: WHATSAPP
modalidade: DIGITAL

subcategorias:
  DISPARO_PROATIVO:
    - campanha_saude
    - informativo_servicos
    - alerta_emergencia
  ATENDIMENTO_REATIVO:
    - solicitacao_informacao
    - agendamento_servico
    - acompanhamento_protocolo
```

### **SMAS (Assistência Social) - Programas Sociais**
```yaml
tipo_interacao: CONSUMO | SOLICITACAO
categoria_interacao: ASSISTENCIA_SOCIAL
canal: POSTO_ATENDIMENTO | DOMICILIO
modalidade: FISICO

subcategorias:
  PROGRAMA_TRANSFERENCIA_RENDA:
    - auxilio_carioca
    - programa_familia_carioca
  ATENDIMENTO_VULNERABILIDADE:
    - atendimento_cras
    - abordagem_social
    - acolhimento_institucional
```

## 🏛️ Campos Padronizados para Facts

### **Core Fields - Identificação da Interação**
```sql
-- IDENTIFICAÇÃO
id_interacao            STRING    -- UUID da interação
cpf_cidadao            STRING    -- CPF do cidadão (FK)
protocolo_origem       STRING    -- Protocolo do sistema origem

-- CLASSIFICAÇÃO ONTOLÓGICA  
tipo_interacao         STRING    -- SOLICITACAO | CONSUMO | REPORTE | COMUNICACAO | CADASTRO
categoria_interacao    STRING    -- SAUDE | SERVICOS_URBANOS | TRANSPORTE | etc.
canal_interacao        STRING    -- WHATSAPP | UNIDADE_SAUDE | CENTRAL_TELEFONICA | etc.
modalidade_interacao   STRING    -- DIGITAL | FISICO
subcategoria           STRING    -- Categoria específica do domínio
```

### **Business Fields - Contexto da Interação**
```sql
-- TEMPORAL
data_interacao         DATE      -- Data da interação
datahora_inicio        TIMESTAMP -- Início da interação  
datahora_fim           TIMESTAMP -- Fim da interação (quando aplicável)
duracao_minutos        INTEGER   -- Duração em minutos

-- GEOLOCALIZAÇÃO
id_estabelecimento     STRING    -- UPA, escola, posto (quando aplicável)
endereco_interacao     STRUCT    -- Local onde ocorreu
bairro_interacao       STRING    -- Bairro da interação
area_planejamento      INTEGER   -- AP onde ocorreu

-- STATUS E RESULTADO
status_interacao       STRING    -- INICIADA | CONCLUIDA | CANCELADA | PENDENTE
desfecho_interacao     STRING    -- RESOLVIDA | NAO_RESOLVIDA | NAO_APLICAVEL
satisfacao_cidadao     STRING    -- SATISFEITO | INSATISFEITO | NAO_AVALIADO

-- VALORES (quando aplicável)
valor_monetario        NUMERIC   -- Custo, valor pago, benefício
quantidade_servico     INTEGER   -- Quantidades envolvidas
```

### **Flexible Fields - Dados Específicos**
```sql
-- DADOS ESPECÍFICOS DO SISTEMA
dados_origem           JSON      -- Dados originais do sistema
detalhes_interacao     STRUCT    -- Estrutura específica por categoria
metadados_tecnicos     JSON      -- Informações técnicas do processamento
```

## 💡 Casos de Uso da Ontologia

### **1. Analytics Cross-Sistema**
```sql
-- Cidadãos que mais interagem por categoria
SELECT 
    cpf_cidadao,
    categoria_interacao,
    COUNT(*) as total_interacoes,
    COUNT(DISTINCT canal_interacao) as canais_usados
FROM fct_interacoes_cidadao
GROUP BY 1, 2
ORDER BY total_interacoes DESC
```

### **2. Jornada do Cidadão**
```sql
-- Sequência de interações de um cidadão
SELECT 
    cpf_cidadao,
    data_interacao,
    tipo_interacao,
    categoria_interacao,
    canal_interacao,
    desfecho_interacao
FROM fct_interacoes_cidadao 
WHERE cpf_cidadao = '12345678901'
ORDER BY datahora_inicio
```

### **3. Eficiência por Canal**
```sql
-- Performance por canal de atendimento
SELECT 
    canal_interacao,
    categoria_interacao,
    COUNT(*) as total_interacoes,
    AVG(duracao_minutos) as duracao_media,
    COUNT(CASE WHEN desfecho_interacao = 'RESOLVIDA' THEN 1 END) / COUNT(*) as taxa_resolucao
FROM fct_interacoes_cidadao
GROUP BY 1, 2
```

### **4. Demanda por Região**
```sql
-- Demanda por serviços por bairro
SELECT 
    bairro_interacao,
    categoria_interacao,
    subcategoria,
    COUNT(*) as total_solicitacoes
FROM fct_interacoes_cidadao
WHERE tipo_interacao = 'SOLICITACAO'
GROUP BY 1, 2, 3
ORDER BY total_solicitacoes DESC
```

## 🎯 Benefícios da Abordagem

### **✅ Para Gestão Pública**
- **Visão 360° do Cidadão**: Todas as interações em um só lugar
- **Identificação de Padrões**: Jornadas típicas e pontos de fricção  
- **Otimização de Canais**: Onde investir em melhorias
- **Planejamento de Serviços**: Demanda por região e categoria

### **✅ Para Cidadãos**
- **Atendimento Integrado**: Histórico unificado across sistemas
- **Proatividade**: Antecipar necessidades baseado em padrões
- **Personalização**: Serviços customizados por perfil

### **✅ Para Desenvolvimento**
- **Padronização**: Schema único para novos sistemas
- **Flexibilidade**: Campos específicos preservados  
- **Escalabilidade**: Fácil adição de novos tipos de interação
- **Governança**: Taxonomia centralizada e versionada

## 📋 Próximos Passos

1. **Validar** ontologia com stakeholders das secretarias
2. **Implementar seeds** de classificação no dbt
3. **Prototipar** com dados do 1746 (maior volume)
4. **Expandir** para SMS e outros sistemas
5. **Criar dashboards** de jornada do cidadão
6. **Estabelecer governança** para evolução da ontologia

---

**🏛️ Esta ontologia transforma dados de sistemas em inteligência sobre como os cariocas interagem com sua cidade!**
