# Ontologia - Conversas por Chatbot (rmi_conversas.chatbot)

## Visão Geral

A tabela `rmi_conversas.chatbot` consolida todas as interações entre cidadãos e o poder público municipal através de chatbots, principalmente via WhatsApp através da plataforma Wetalkie. Esta tabela é fundamental para análise de atendimento automatizado e comportamento dos cidadãos em canais digitais.

## Objetivo

Centralizar em uma única estrutura todas as conversas completas realizadas via chatbot, permitindo:

- Análise de engajamento e satisfação em canais digitais
- Monitoramento de efetividade do atendimento automatizado  
- Identificação de padrões de comportamento dos cidadãos
- Métricas de utilização do chatbot por CPF
- Análise de temas mais demandados via chatbot

## Fontes de Dados

### 1. Mensagens Ativas (HSM - High Structured Messages)
- **Fonte**: `rj-crm-registry.brutos_wetalkie_staging.disparos_efetuados`
- **Tipo**: Mensagens enviadas pela prefeitura para cidadãos
- **Características**: Comunicações institucionais, notificações, campanhas

### 2. Mensagens Receptivas (Conversas URA)  
- **Fonte**: `rj-crm-registry.brutos_wetalkie.fluxos_ura`
- **Tipo**: Conversas completas iniciadas por HSM com resposta do cidadão
- **Características**: Interação bidirecional, fluxo de URA, possível atendimento humano

### 3. Dados Consolidados
- **Fonte**: `rj-crm-registry.crm_whatsapp.sessao` 
- **Tipo**: União das informações de HSM + URA com dados parseados
- **Características**: Sessão completa de interação com metadados

### 4. Dados de Contato
- **Fonte**: `rj-crm-registry.crm_whatsapp.contato`
- **Tipo**: Informações de contato e CPF para linkagem
- **Características**: Permite identificação do cidadão

## Arquitetura de Dados

### Granularidade
- **Uma linha por sessão de conversa completa por CPF**
- Cada sessão pode conter múltiplas mensagens (estrutura aninhada)
- Particionamento por data da conversa

### Relacionamentos
- **CPF**: Link com `rmi_dados_mestres.pessoa_fisica`
- **Telefone**: Informação de contato secundária
- **Sessão**: Identificador único da conversa

## Casos de Uso

### 1. Análise de Engajamento
- Taxa de resposta a HSMs por tipo de campanha
- Tempo médio de resposta dos cidadãos  
- Abandono de conversa por etapa do fluxo

### 2. Efetividade do Chatbot
- Resolução automática vs. transferência para humano
- Satisfação do atendimento (quando disponível)
- Identificação de pontos de melhoria no fluxo

### 3. Comportamento do Cidadão
- Padrões de uso por perfil demográfico
- Temas mais demandados por região/perfil
- Sazonalidade das interações

### 4. Operacional
- Volume de atendimentos por canal
- Carga de trabalho para operadores humanos
- Performance do sistema de chatbot

## Qualidade de Dados

### Desafios Identificados
1. **Linkagem CPF-Telefone**: Nem todos os telefones têm CPF associado
2. **Sessões Incompletas**: HSMs enviadas sem resposta
3. **Dados Históricos**: Variação na estrutura ao longo do tempo
4. **JSON Parsing**: Complexidade dos dados aninhados

### Estratégias de Qualidade
1. **CPF Prioritário**: Usar sempre que disponível via tabela contato
2. **Fallback Telefone**: Manter telefone como identificador secundário  
3. **Classificação de Completude**: Distinguir conversas completas vs. parciais
4. **Validação Temporal**: Verificar consistência de timestamps

## Próximos Passos

1. **Schema Definition**: Definir estrutura final da tabela
2. **Source Mapping**: Mapear campos de cada fonte para schema unificado
3. **Implementation Guide**: Detalhar lógica de transformação
4. **Data Quality Rules**: Estabelecer regras de validação
5. **Performance Optimization**: Definir particionamento e clustering