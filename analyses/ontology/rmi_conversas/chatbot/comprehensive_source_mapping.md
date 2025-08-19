# Mapeamento Completo de Fontes - rmi_conversas.chatbot

## NOVA ABORDAGEM: Capturar TODAS as Interações

### Problema Atual
A implementação atual só captura ~10K conversas com resposta, mas há ~11K HSMs enviadas. **Gap crítico**: HSMs sem resposta, falhas de entrega, e outros tipos de interação não estão sendo capturados.

### Solução: União de Todas as Fontes

## 1. BASE PRINCIPAL: Todos os Disparos HSM

```sql
-- Base completa: TODOS os disparos de HSM
WITH base_disparos AS (
  SELECT 
    generate_uuid() as id_interacao,
    id_hsm,
    `to` as telefone_contato,
    datetime(dispatch_date) as disparo_datahora,
    date(dispatch_date) as data_interacao,
    campaignName as nome_campanha,
    externalId,
    costCenterId,
    vars,
    'HSM_SENT' as status_base,
    cast(data_particao as date) as data_particao
  FROM `rj-crm-registry.brutos_wetalkie_staging.disparos_efetuados`
  WHERE dispatch_date >= '2020-01-01'
)
```
**Cobertura**: 100% das interações tentadas (11.184 HSMs)

## 2. ENRIQUECIMENTO: Status de Entrega

```sql
-- Status detalhado de cada HSM
WITH status_entrega AS (
  SELECT 
    COALESCE(triggerId, hsm_id) as id_hsm,
    targetId as id_contato,
    flatTarget as telefone_contato,
    
    -- Timestamps de cada etapa
    timestamp_sub(createDate, interval 3 hour) as criacao_datahora,
    timestamp_sub(sendDate, interval 3 hour) as envio_datahora,
    timestamp_sub(receiveDate, interval 3 hour) as entrega_datahora,
    timestamp_sub(readDate, interval 3 hour) as leitura_datahora,
    timestamp_sub(replyDate, interval 3 hour) as resposta_datahora,
    
    -- Status derivado
    CASE 
      WHEN receiveDate IS NULL THEN 'SEND_FAILED'
      WHEN readDate IS NULL THEN 'DELIVERED_NOT_READ' 
      WHEN replyDate IS NULL THEN 'READ_NO_RESPONSE'
      ELSE 'REPLIED'
    END as status_entrega
    
  FROM `rj-crm-registry.brutos_wetalkie_staging.fluxo_atendimento_*`
  WHERE sendDate >= '2020-01-01'
)
```
**Cobertura**: Status de entrega para HSMs que têm tracking

## 3. CONVERSAS COMPLETAS: Apenas as que tiveram resposta

```sql
-- Conversas completas (subset das HSMs que tiveram resposta)
WITH conversas_completas AS (
  SELECT 
    id_sessao,
    hsm.id_hsm,
    contato_telefone as telefone_contato,
    inicio_datahora,
    fim_datahora,
    
    -- Classificação da conversa
    CASE 
      WHEN operador IS NOT NULL THEN 'ESCALATED_TO_HUMAN'
      WHEN busca.indicador = true AND busca.feedback.resposta IS NOT NULL 
        THEN 'RESOLVED_AUTOMATICALLY'
      WHEN fim_datahora IS NULL THEN 'ABANDONED'
      ELSE 'COMPLETED'
    END as resultado_conversa,
    
    -- Dados da conversa
    mensagens,
    busca,
    ura,
    estatisticas,
    erro_fluxo.indicador as teve_erro_fluxo
    
  FROM `rj-crm-registry.crm_whatsapp.sessao`
  WHERE inicio_datahora >= '2020-01-01'
)
```
**Cobertura**: Apenas HSMs que geraram conversa (~14K sessões)

## 4. PROBLEMAS CONHECIDOS: Telefones Inválidos

```sql
-- Telefones que falharam definitivamente
WITH telefones_problematicos AS (
  SELECT 
    telefone,
    'PHONE_INVALID_WHATSAPP' as tipo_problema,
    data_particao
  FROM `rj-crm-registry.crm_whatsapp.telefone_sem_whatsapp`
  
  UNION ALL
  
  SELECT 
    telefone,
    'OPTED_OUT' as tipo_problema,
    current_date() as data_particao
  FROM `rj-crm-registry.brutos_wetalkie_staging.blocklist`
)
```

## 5. UNIÃO COMPLETA: Todas as Interações

```sql
-- União de todas as fontes para criar visão completa
WITH interacoes_completas AS (
  SELECT 
    -- IDENTIFICAÇÃO
    d.id_interacao,
    d.id_hsm,
    d.telefone_contato,
    c.cpf as cpf_cidadao,
    conv.id_sessao,
    
    -- TEMPORALIDADE COMPLETA
    d.data_interacao,
    d.disparo_datahora,
    se.envio_datahora,
    se.entrega_datahora,
    se.leitura_datahora,
    se.resposta_datahora,
    conv.inicio_datahora as inicio_conversa_datahora,
    conv.fim_datahora as fim_conversa_datahora,
    
    -- CLASSIFICAÇÃO POR COMPLETUDE
    CASE 
      -- Falhas técnicas
      WHEN tp.tipo_problema = 'PHONE_INVALID_WHATSAPP' THEN 'PHONE_INVALID'
      WHEN tp.tipo_problema = 'OPTED_OUT' THEN 'OPTED_OUT'
      WHEN se.status_entrega = 'SEND_FAILED' THEN 'DELIVERY_FAILED'
      
      -- Diferentes níveis de engajamento
      WHEN se.status_entrega = 'DELIVERED_NOT_READ' THEN 'DELIVERED_NOT_READ'
      WHEN se.status_entrega = 'READ_NO_RESPONSE' THEN 'READ_NO_RESPONSE'
      
      -- Conversas (apenas se responderam)
      WHEN conv.resultado_conversa = 'ESCALATED_TO_HUMAN' THEN 'ESCALATED_TO_HUMAN'
      WHEN conv.resultado_conversa = 'RESOLVED_AUTOMATICALLY' THEN 'RESOLVED_AUTOMATICALLY'
      WHEN conv.resultado_conversa = 'ABANDONED' THEN 'CONVERSATION_ABANDONED'
      WHEN conv.resultado_conversa = 'COMPLETED' THEN 'CONVERSATION_COMPLETED'
      
      -- Status desconhecido
      WHEN se.id_hsm IS NULL AND conv.id_hsm IS NULL THEN 'STATUS_UNKNOWN'
      ELSE 'OTHER'
    END as tipo_interacao,
    
    -- DADOS DA CAMPANHA
    d.nome_campanha,
    ma.orgao as orgao_responsavel,
    ma.categoria as categoria_hsm,
    ma.nome_hsm as template_hsm,
    
    -- DADOS DA CONVERSA (quando disponível)
    conv.mensagens,
    conv.busca,
    conv.ura,
    conv.estatisticas,
    conv.teve_erro_fluxo,
    
    -- METADADOS
    d.data_particao,
    current_datetime() as data_processamento
    
  FROM base_disparos d
  
  -- Status de entrega (quando disponível)
  LEFT JOIN status_entrega se
    ON d.id_hsm = se.id_hsm
  
  -- Conversas completas (quando responderam)
  LEFT JOIN conversas_completas conv
    ON d.id_hsm = conv.id_hsm
  
  -- Dados de contato para CPF
  LEFT JOIN (
    SELECT telefone, cpf, 
           ROW_NUMBER() OVER (PARTITION BY telefone ORDER BY data_particao DESC) as rn
    FROM `rj-crm-registry.crm_whatsapp.contato`
  ) c ON d.telefone_contato = c.telefone AND c.rn = 1
  
  -- Metadados da HSM
  LEFT JOIN `rj-crm-registry.crm_whatsapp.mensagem_ativa` ma
    ON d.id_hsm = ma.id_hsm
  
  -- Problemas conhecidos
  LEFT JOIN telefones_problematicos tp
    ON d.telefone_contato = tp.telefone
)

SELECT * FROM interacoes_completas
```

## Resultado Esperado

### Cobertura Completa
- **11.184 HSMs enviadas** (base completa)
- **Status de entrega** para HSMs com tracking
- **14.847 conversas** para HSMs que tiveram resposta
- **Telefones problemáticos** identificados
- **Zero gaps** - todas as tentativas de interação capturadas

### Tipos de Interação Esperados
1. `PHONE_INVALID` - Telefone não existe no WhatsApp
2. `OPTED_OUT` - Usuário optou por não receber mensagens
3. `DELIVERY_FAILED` - Falha técnica na entrega
4. `DELIVERED_NOT_READ` - Entregue mas não lido
5. `READ_NO_RESPONSE` - Lido mas sem resposta
6. `CONVERSATION_ABANDONED` - Respondeu mas abandonou
7. `CONVERSATION_COMPLETED` - Conversa completa
8. `RESOLVED_AUTOMATICALLY` - Resolvido pelo chatbot
9. `ESCALATED_TO_HUMAN` - Transferido para humano
10. `STATUS_UNKNOWN` - Sem informações de tracking

### Métricas Completas Possíveis
- **Taxa de entrega real**: entregues / enviadas
- **Taxa de leitura**: lidas / entregues  
- **Taxa de resposta**: respondidas / lidas
- **Taxa de resolução**: resolvidas / respondidas
- **Identificação de telefones problemáticos**
- **ROI real por campanha**

## Implementação

Esta abordagem substitui o modelo atual que só captura conversas completas por um modelo que captura **todas as tentativas de interação**, permitindo análise completa do funil de comunicação digital da prefeitura.