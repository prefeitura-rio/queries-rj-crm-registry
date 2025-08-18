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

### COMPLETUDE: Capturar TODAS as interações, incluindo falhas

**Total de HSMs enviadas**: ~11.184 
**Total de sessões com resposta**: ~14.847 
**Gap de dados**: Precisa incluir HSMs sem resposta e falhas de entrega

### 1. HSMs Enviadas (TODAS - com e sem resposta)
- **Fonte**: `rj-crm-registry.brutos_wetalkie_staging.disparos_efetuados`
- **Cobertura**: 100% das mensagens enviadas pela prefeitura
- **Dados**: ID HSM, telefone, data disparo, campanha, variáveis
- **Status**: CRÍTICO - inclui HSMs que falharam ou não tiveram resposta

### 2. Estados da HSM (Delivery Status)
- **Fonte**: `rj-crm-registry.brutos_wetalkie_staging.fluxo_atendimento_*`
- **Cobertura**: Status de entrega, leitura, resposta por HSM
- **Dados**: Criação, envio, recebimento, leitura, resposta, falhas
- **Status**: CRÍTICO - distingue HSMs entregues vs. não entregues

### 3. Início e Fim de Atendimento
- **Fontes**: 
  - `rj-crm-registry.brutos_wetalkie_staging.atendimento_iniciado_*`
  - `rj-crm-registry.brutos_wetalkie_staging.atendimento_finalizado_*`
- **Cobertura**: Metadados de sessões de atendimento
- **Dados**: ID, protocolo, tabulação de finalização

### 4. Conversas Completas (APENAS com resposta do cidadão)
- **Fontes**: 
  - `rj-crm-registry.brutos_wetalkie.fluxos_ura`
  - `rj-crm-registry.crm_whatsapp.sessao` (view processada)
- **Cobertura**: PARCIAL - apenas HSMs que tiveram resposta
- **Dados**: Mensagens completas, URA, operadores, busca
- **Limitação**: Exclui HSMs sem resposta (maioria dos casos)

### 5. Telefones com Problemas
- **Fonte**: `rj-crm-registry.crm_whatsapp.telefone_sem_whatsapp`
- **Cobertura**: Telefones que falharam definitivamente
- **Dados**: Números que não estão no WhatsApp ou rejeitaram termos

### 6. Dados de Contato e CPF
- **Fonte**: `rj-crm-registry.crm_whatsapp.contato`
- **Cobertura**: Linkagem telefone-CPF (quando disponível)
- **Status**: PROBLEMA - CPFs não estão preenchidos atualmente

### 7. Blocklist (Opt-outs)
- **Fonte**: `rj-crm-registry.brutos_wetalkie_staging.blocklist`
- **Cobertura**: Cidadãos que solicitaram parar de receber HSMs
- **Dados**: Telefones que optaram por sair das comunicações

## Arquitetura de Dados

### Nova Granularidade (REVISADA)
- **Uma linha por tentativa de interação com cidadão via WhatsApp**
- Inclui HSMs sem resposta, falhas de entrega, conversas completas
- Estrutura que cresce do simples (HSM enviada) ao complexo (conversa completa)
- Particionamento por data do disparo/interação

### Tipos de Interação por Completude
1. **HSM_SENT_ONLY**: HSM enviada, status desconhecido
2. **HSM_DELIVERY_FAILED**: HSM falhou na entrega (erro conhecido)
3. **HSM_DELIVERED_NO_READ**: HSM entregue mas não lida
4. **HSM_READ_NO_RESPONSE**: HSM lida mas sem resposta
5. **CONVERSATION_PARTIAL**: Respondeu mas não completou fluxo
6. **CONVERSATION_COMPLETE**: Conversa completa com resolução
7. **CONVERSATION_ESCALATED**: Transferida para atendimento humano

### Relacionamentos
- **CPF**: Link com `rmi_dados_mestres.pessoa_fisica` (quando disponível)
- **Telefone**: Chave primária de identificação do cidadão
- **ID_HSM**: Link entre todas as tabelas de disparo
- **ID_Sessão**: Disponível apenas para conversas com resposta

## Casos de Uso

### 1. Análise Completa de Engajamento (ATUALIZADA)
- **Funil completo**: HSMs enviadas → entregues → lidas → respondidas
- Taxa de entrega por operadora/região
- Taxa de abertura por tipo de mensagem/horário
- Taxa de resposta por campanha/conteúdo
- Identificação de telefones problemáticos

### 2. Qualidade da Base de Contatos
- Telefones inválidos/inexistentes no WhatsApp
- Números que mudaram de proprietário
- Telefones em blocklist/opt-out
- Limpeza proativa da base de dados

### 3. Otimização de Campanhas
- Melhores horários para envio por perfil
- Tipos de conteúdo que geram mais engajamento
- Segmentação de audiência por responsividade
- A/B testing de mensagens

### 4. Efetividade Operacional
- Volume total de interações (tentadas vs. bem-sucedidas)
- Carga real de trabalho para operadores
- Custos por interação efetiva
- ROI de campanhas de comunicação

### 5. Identificação de Problemas Técnicos
- Falhas de infraestrutura (deliverabilidade)
- Bugs no fluxo de conversa
- Problemas de integração entre sistemas
- Monitoramento de SLA de resposta

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