# Mapeamento de Fontes - rmi_conversas.chatbot

## Fontes de Dados Identificadas

### 1. Tabela Principal: `crm_whatsapp.sessao`
**Descrição**: Tabela consolidada que já une dados de HSM e URA
**Cobertura**: Conversas completas com resposta do cidadão ou sessões URA
**Limitação**: Não inclui HSMs sem resposta

```sql
-- Campos mapeados da sessao
SELECT 
  id_sessao,                          -- → id_sessao
  protocolo,                          -- → protocolo (se necessário)
  inicio_data,                        -- → data_conversa  
  inicio_datahora,                    -- → inicio_datahora
  fim_datahora,                       -- → fim_datahora
  hsm,                               -- → hsm_detalhes (struct)
  mensagens,                         -- → mensagens (array)
  busca,                             -- → busca_detalhes
  ura,                               -- → ura_detalhes  
  estatisticas,                      -- → campos de estatísticas
  contato_telefone,                  -- → telefone_contato
  data_particao                      -- → data_particao
FROM `rj-crm-registry.crm_whatsapp.sessao`
```

### 2. Tabela de Contatos: `crm_whatsapp.contato`
**Descrição**: Dados de contato com linkagem CPF-Telefone
**Uso**: Enriquecer sessões com CPF do cidadão

```sql
-- Join para obter CPF
SELECT 
  c.cpf,                             -- → cpf_cidadao
  c.contato_nome,                    -- → nome_contato (se necessário)
  c.contato_telefone,                -- → chave de join
  c.data_optin,                      -- → metadados (se necessário)
  c.data_optout                      -- → metadados (se necessário)
FROM `rj-crm-registry.crm_whatsapp.contato` c
```

### 3. Fonte Complementar: `brutos_wetalkie_staging.disparos_efetuados`
**Descrição**: HSMs enviadas (incluindo sem resposta)  
**Uso**: Identificar HSMs que não geraram sessão URA
**Observação**: Para análise de taxa de resposta

```sql
-- HSMs sem resposta (não estão na sessao)
SELECT 
  id_hsm,                            -- → id_hsm
  dispatch_date,                     -- → data/hora envio
  campaignName,                      -- → nome_campanha
  `to` as telefone,                  -- → telefone_contato
  externalId,                        -- → id_externo
  vars                               -- → variáveis da HSM
FROM `rj-crm-registry.brutos_wetalkie_staging.disparos_efetuados`
WHERE id_hsm NOT IN (
  SELECT hsm.id_hsm 
  FROM `rj-crm-registry.crm_whatsapp.sessao`
  WHERE hsm.id_hsm IS NOT NULL
)
```

## Estratégia de Consolidação

### 1. Base Principal: Sessões Completas
```sql
-- CTEs para sessões com URA/resposta
WITH sessoes_completas AS (
  SELECT 
    s.*,
    c.cpf,
    'URA_COMPLETA' as tipo_conversa,
    CASE 
      WHEN s.operador IS NOT NULL THEN 'TRANSFERIDA_HUMANO'
      WHEN s.busca.indicador = true THEN 'RESOLVIDA_AUTOMATICA'  
      ELSE 'ABANDONADA'
    END as desfecho_conversa
  FROM `rj-crm-registry.crm_whatsapp.sessao` s
  LEFT JOIN `rj-crm-registry.crm_whatsapp.contato` c
    ON s.contato_telefone = c.contato_telefone
  WHERE s.hsm.resposta_datahora IS NOT NULL  -- Teve resposta
)
```

### 2. Complemento: HSMs Sem Resposta
```sql
-- CTEs para HSMs enviadas sem resposta
WITH hsm_sem_resposta AS (
  SELECT 
    generate_uuid() as id_conversa,
    c.cpf as cpf_cidadao,
    d.`to` as telefone_contato,
    null as id_sessao,
    date(d.dispatch_date) as data_conversa,
    datetime(d.dispatch_date) as inicio_datahora,
    null as fim_datahora,
    'HSM_ONLY' as tipo_conversa,
    'ABANDONADA' as desfecho_conversa,
    false as teve_resposta_cidadao,
    -- Estrutura HSM simplificada
    struct(
      d.id_hsm,
      d.campaignName as nome_hsm,
      null as ambiente,
      null as categoria,
      null as orgao,
      timestamp(d.dispatch_date) as envio_datahora
    ) as hsm_detalhes
  FROM `rj-crm-registry.brutos_wetalkie_staging.disparos_efetuados` d
  LEFT JOIN `rj-crm-registry.crm_whatsapp.contato` c
    ON d.`to` = c.contato_telefone
  WHERE d.id_hsm NOT IN (
    SELECT hsm.id_hsm 
    FROM `rj-crm-registry.crm_whatsapp.sessao`
    WHERE hsm.id_hsm IS NOT NULL
  )
)
```

## Transformações de Dados

### 1. Classificação de Tipo de Conversa
```sql
CASE 
  WHEN hsm.resposta_datahora IS NULL THEN 'HSM_ONLY'
  WHEN operador IS NOT NULL THEN 'ATENDIMENTO_HUMANO' 
  WHEN array_length(mensagens) > 1 THEN 'URA_COMPLETA'
  ELSE 'HSM_ONLY'
END as tipo_conversa
```

### 2. Classificação de Desfecho
```sql
CASE 
  WHEN operador IS NOT NULL THEN 'TRANSFERIDA_HUMANO'
  WHEN busca.indicador = true AND busca.feedback.resposta IS NOT NULL 
    THEN 'RESOLVIDA_AUTOMATICA'
  WHEN hsm.resposta_datahora IS NULL THEN 'ABANDONADA'
  WHEN fim_datahora IS NULL THEN 'ABANDONADA'
  ELSE 'RESOLVIDA_AUTOMATICA'
END as desfecho_conversa
```

### 3. Cálculo de Métricas
```sql
-- Teve resposta do cidadão
hsm.resposta_datahora IS NOT NULL as teve_resposta_cidadao,

-- Duração calculada quando não disponível
COALESCE(
  estatisticas.duracao_sessao_seg,
  timestamp_diff(fim_datahora, inicio_datahora, SECOND)
) as duracao_total_seg
```

## Lógica de Junção (JOIN)

### Contato → Sessão
```sql
LEFT JOIN `rj-crm-registry.crm_whatsapp.contato` c
  ON s.contato_telefone = c.contato_telefone
  AND c.data_particao = (
    SELECT MAX(data_particao) 
    FROM `rj-crm-registry.crm_whatsapp.contato` c2
    WHERE c2.contato_telefone = c.contato_telefone
  )
```

### Tratamento de Duplicatas
- **Sessão**: `id_sessao` é único
- **Contato**: Usar `data_particao` mais recente por telefone
- **HSM**: `id_hsm` pode ter múltiplos disparos (usar mais recente)

## Filtros de Qualidade

### 1. Filtros Temporais
```sql
WHERE inicio_datahora >= '2020-01-01'  -- Data mínima confiável
  AND inicio_datahora <= current_datetime()
```

### 2. Filtros de Dados Válidos  
```sql
WHERE telefone_contato IS NOT NULL
  AND length(telefone_contato) >= 10
  AND (cpf_cidadao IS NULL OR length(cpf_cidadao) = 11)
```

### 3. Filtros de Teste
```sql
WHERE lower(coalesce(hsm.nome_hsm, '')) NOT LIKE '%teste%'
  AND lower(coalesce(hsm.orgao, '')) NOT LIKE '%teste%'
```

## Observações de Implementação

1. **Performance**: Particionar por `data_particao` e usar clustering em `cpf_cidadao`
2. **Incrementalidade**: Processar apenas partições modificadas
3. **Versionamento**: Manter histórico de mudanças no schema
4. **Monitoramento**: Alertas para quedas bruscas no volume de dados