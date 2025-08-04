# Integração com Qualidade de Telefone - Chatbot Conversas

## Visão Geral

A tabela `rmi_conversas.chatbot` é fundamental para alimentar o sistema de qualidade de telefones em `rmi_dados_mestres.pessoa_fisica`, criando um ciclo virtuoso de melhoria contínua da qualidade dos dados de contato.

## Relacionamento Bidirecional

### 1. Chatbot → Qualidade de Telefone (CONSUMO)
A tabela chatbot **consome** classificações de qualidade para:
- Otimizar seleção de destinatários para campanhas HSM
- Reduzir custos com números inválidos  
- Melhorar taxas de entrega e engajamento

### 2. Qualidade de Telefone → Chatbot (FORNECIMENTO)
A tabela chatbot **fornece** evidências de qualidade para:
- Confirmar que telefones são válidos e pertencentes ao CPF
- Atualizar classificação de confiança baseado em interações recentes
- Identificar números que falharam em campanhas

## Mapeamento de Evidências

### Evidências Fornecidas pelo Chatbot

#### 1. MUITO_PROVAVEL (Interação Confirmada)
**Critério**: Cidadão respondeu à HSM nos últimos 6 meses

```sql
-- Telefones que se qualificam para MUITO_PROVAVEL
SELECT 
  cpf_cidadao,
  telefone_contato,
  max(inicio_datahora) as data_ultima_interacao,
  'resposta_whatsapp' as tipo_interacao,
  true as sucesso_contato
FROM {{ ref('chatbot') }}
WHERE teve_resposta_cidadao = true
  AND inicio_datahora >= current_date() - 180  -- 6 meses
  AND cpf_cidadao IS NOT NULL
GROUP BY cpf_cidadao, telefone_contato
```

#### 2. IMPROVAVEL (Falha Confirmada)  
**Critério**: HSM falhou na entrega ou múltiplas tentativas sem sucesso

```sql
-- Telefones que se qualificam para IMPROVAVEL
SELECT 
  cpf_cidadao,
  telefone_contato,
  max(inicio_datahora) as data_ultima_tentativa,
  'falha_whatsapp' as tipo_interacao,
  false as sucesso_contato,
  count(*) as tentativas_contato
FROM {{ ref('chatbot') }}
WHERE hsm_detalhes.falha_datahora IS NOT NULL
  OR (tipo_conversa = 'HSM_ONLY' AND teve_resposta_cidadao = false)
  AND inicio_datahora >= current_date() - 180  -- 6 meses
  AND cpf_cidadao IS NOT NULL
GROUP BY cpf_cidadao, telefone_contato
HAVING count(*) >= 2  -- Múltiplas falhas
```

### Classificação de Qualidade por Desfecho

| Desfecho Chatbot | Classificação Telefone | Evidência |
|------------------|----------------------|-----------|
| `RESOLVIDA_AUTOMATICA` | **MUITO_PROVAVEL** | Pessoa respondeu e completou fluxo |
| `TRANSFERIDA_HUMANO` | **MUITO_PROVAVEL** | Pessoa respondeu e foi atendida |  
| `ABANDONADA` + resposta | **PROVAVEL** | Pessoa respondeu mas não completou |
| `ABANDONADA` + sem resposta | **POUCO_PROVAVEL** | HSM entregue mas sem resposta |
| HSM com falha | **IMPROVAVEL** | Falha na entrega (número inválido) |

## Implementação da Integração

### 1. Modelo Intermediário: Evidências de Qualidade
```sql
-- models/intermediate/phone_quality/int_chatbot_phone_evidence.sql
{{ config(
    materialized='ephemeral',
    alias='chatbot_phone_evidence'
) }}

WITH evidencias_qualidade AS (
  SELECT 
    cpf_cidadao,
    telefone_contato,
    
    -- Dados da última interação
    MAX(inicio_datahora) as data_ultima_interacao,
    
    -- Tipo de evidência mais forte
    CASE 
      WHEN BOOL_OR(desfecho_conversa IN ('RESOLVIDA_AUTOMATICA', 'TRANSFERIDA_HUMANO'))
        THEN 'MUITO_PROVAVEL'
      WHEN BOOL_OR(teve_resposta_cidadao = true)
        THEN 'PROVAVEL'  
      WHEN BOOL_OR(hsm_detalhes.entrega_datahora IS NOT NULL AND teve_resposta_cidadao = false)
        THEN 'POUCO_PROVAVEL'
      WHEN BOOL_OR(hsm_detalhes.falha_datahora IS NOT NULL)
        THEN 'IMPROVAVEL'
      ELSE 'POUCO_PROVAVEL'
    END as confianca_sugerida,
    
    -- Métricas de interação
    COUNT(*) as total_interacoes,
    SUM(CASE WHEN teve_resposta_cidadao THEN 1 ELSE 0 END) as interacoes_com_resposta,
    SUM(CASE WHEN hsm_detalhes.falha_datahora IS NOT NULL THEN 1 ELSE 0 END) as interacoes_com_falha,
    
    -- Taxa de sucesso
    SAFE_DIVIDE(
      SUM(CASE WHEN teve_resposta_cidadao THEN 1 ELSE 0 END),
      COUNT(*)
    ) as taxa_sucesso,
    
    'wetalkie_chatbot' as fonte_evidencia,
    MAX(data_processamento) as data_ultima_atualizacao

  FROM {{ ref('chatbot') }}
  WHERE cpf_cidadao IS NOT NULL 
    AND telefone_contato IS NOT NULL
    AND inicio_datahora >= CURRENT_DATE() - 365  -- Evidências dos últimos 12 meses
  GROUP BY cpf_cidadao, telefone_contato
)

SELECT * FROM evidencias_qualidade
```

### 2. Integração ao Pipeline de Pessoa Física
```sql
-- No modelo int_pessoa_fisica_dim_telefone.sql, adicionar:

chatbot_evidence AS (
  SELECT * FROM {{ ref('int_chatbot_phone_evidence') }}
),

telefones_com_evidencia_chatbot AS (
  SELECT 
    t.*,
    e.data_ultima_interacao as chatbot_ultima_interacao,
    e.confianca_sugerida as chatbot_confianca,
    e.taxa_sucesso as chatbot_taxa_sucesso,
    e.total_interacoes as chatbot_tentativas,
    
    -- Atualizar confiança baseado em evidência do chatbot
    CASE 
      -- Se chatbot tem evidência mais forte, usar ela
      WHEN e.confianca_sugerida = 'MUITO_PROVAVEL' 
        AND e.data_ultima_interacao >= CURRENT_DATE() - 180
        THEN 'MUITO_PROVAVEL'
      
      -- Se chatbot confirma falha, downgrade
      WHEN e.confianca_sugerida = 'IMPROVAVEL'
        AND e.taxa_sucesso < 0.2  -- < 20% sucesso
        THEN 'IMPROVAVEL'
        
      -- Caso contrário, manter classificação original
      ELSE t.confianca_propriedade
    END as confianca_propriedade_final
    
  FROM telefones_base t
  LEFT JOIN chatbot_evidence e 
    ON t.cpf = e.cpf_cidadao 
    AND t.telefone = e.telefone_contato
)
```

### 3. Atualização do Schema pessoa_fisica
```sql
-- Adicionar campos ao struct telefone
telefone: STRUCT<
  principal: STRUCT<
    origem: STRING,
    sistema: STRING,
    ddi: STRING,
    ddd: STRING,
    valor: STRING,
    qualidade_numero: STRING,
    confianca_propriedade: STRING,
    
    -- Novos campos de evidência do chatbot
    chatbot_ultima_interacao: DATETIME,
    chatbot_taxa_sucesso: FLOAT,
    chatbot_tentativas: INTEGER,
    chatbot_evidencia: STRING  -- 'CONFIRMA', 'CONTRADIZ', 'NEUTRO'
  >
>
```

## Casos de Uso da Integração

### 1. Seleção Inteligente para Campanhas
```sql
-- Otimizar seleção de destinatários usando qualidade integrada
SELECT 
  cpf,
  nome,
  telefone.principal.valor,
  telefone.principal.confianca_propriedade,
  telefone.principal.chatbot_taxa_sucesso,
  
  -- Score composto para priorização
  CASE 
    WHEN telefone.principal.confianca_propriedade = 'CONFIRMADA' THEN 95
    WHEN telefone.principal.confianca_propriedade = 'MUITO_PROVAVEL' 
      AND telefone.principal.chatbot_taxa_sucesso >= 0.8 THEN 90
    WHEN telefone.principal.confianca_propriedade = 'MUITO_PROVAVEL' 
      AND telefone.principal.chatbot_taxa_sucesso >= 0.5 THEN 85
    WHEN telefone.principal.confianca_propriedade = 'PROVAVEL'
      AND telefone.principal.chatbot_tentativas = 0 THEN 75  -- Nunca testado
    WHEN telefone.principal.confianca_propriedade = 'PROVAVEL'
      AND telefone.principal.chatbot_taxa_sucesso >= 0.6 THEN 70
    ELSE 30
  END as score_qualidade

FROM {{ ref('pessoa_fisica') }}
WHERE telefone.indicador = TRUE
  AND telefone.principal.qualidade_numero = 'VALIDO'
ORDER BY score_qualidade DESC
```

### 2. Análise de Performance de Campanhas
```sql
-- Comparar performance esperada vs. real
WITH campanha_performance AS (
  SELECT 
    p.telefone.principal.confianca_propriedade,
    p.telefone.principal.qualidade_numero,
    COUNT(*) as total_enviados,
    SUM(CASE WHEN c.teve_resposta_cidadao THEN 1 ELSE 0 END) as total_respostas,
    AVG(
      CASE 
        WHEN p.telefone.principal.confianca_propriedade = 'MUITO_PROVAVEL' THEN 0.90
        WHEN p.telefone.principal.confianca_propriedade = 'PROVAVEL' THEN 0.75
        WHEN p.telefone.principal.confianca_propriedade = 'POUCO_PROVAVEL' THEN 0.50
        ELSE 0.20
      END
    ) as taxa_esperada,
    SAFE_DIVIDE(
      SUM(CASE WHEN c.teve_resposta_cidadao THEN 1 ELSE 0 END),
      COUNT(*)
    ) as taxa_real
    
  FROM {{ ref('pessoa_fisica') }} p
  JOIN {{ ref('chatbot') }} c
    ON p.cpf = c.cpf_cidadao
  WHERE c.data_conversa >= '2024-01-01'  -- Última campanha
  GROUP BY 1, 2
)

SELECT 
  *,
  taxa_real - taxa_esperada as diferenca,
  CASE 
    WHEN ABS(taxa_real - taxa_esperada) > 0.1 THEN 'REVISAR_CRITERIOS'
    WHEN taxa_real > taxa_esperada THEN 'PERFORMANCE_ACIMA'
    ELSE 'PERFORMANCE_DENTRO'
  END as status_classificacao
FROM campanha_performance
ORDER BY diferenca DESC
```

### 3. Identificação de Melhorias
```sql
-- Encontrar telefones que podem ter classificação melhorada
SELECT 
  p.cpf,
  p.telefone.principal.valor,
  p.telefone.principal.confianca_propriedade as classificacao_atual,
  c.confianca_sugerida as classificacao_sugerida,
  c.taxa_sucesso as evidencia_taxa_sucesso,
  c.total_interacoes as evidencia_tentativas,
  
  CASE 
    WHEN p.telefone.principal.confianca_propriedade = 'POUCO_PROVAVEL'
      AND c.confianca_sugerida = 'MUITO_PROVAVEL'
      AND c.taxa_sucesso >= 0.8
    THEN 'UPGRADE_PARA_MUITO_PROVAVEL'
    
    WHEN p.telefone.principal.confianca_propriedade IN ('PROVAVEL', 'MUITO_PROVAVEL')
      AND c.confianca_sugerida = 'IMPROVAVEL' 
      AND c.taxa_sucesso <= 0.2
    THEN 'DOWNGRADE_PARA_IMPROVAVEL'
    
    ELSE 'MANTER_CLASSIFICACAO'
  END as acao_recomendada

FROM {{ ref('pessoa_fisica') }} p
JOIN {{ ref('int_chatbot_phone_evidence') }} c
  ON p.cpf = c.cpf_cidadao 
  AND p.telefone.principal.valor = c.telefone_contato
WHERE c.total_interacoes >= 3  -- Evidência suficiente
ORDER BY c.taxa_sucesso DESC
```

## Métricas de Qualidade da Integração

### 1. Taxa de Concordância
Percentual de telefones onde classificação chatbot confirma classificação pessoa_fisica

### 2. Taxa de Melhoria
Percentual de telefones que tiveram classificação melhorada com evidência chatbot

### 3. Precisão Preditiva
Comparação entre taxa de sucesso esperada vs. real por classificação

### 4. Cobertura de Evidência
Percentual de telefones pessoa_fisica que têm evidência do chatbot

## Cronograma de Implementação

1. **Semana 1**: Criar modelo `int_chatbot_phone_evidence`
2. **Semana 2**: Integrar ao pipeline pessoa_fisica  
3. **Semana 3**: Testar e validar classificações
4. **Semana 4**: Implementar dashboards de monitoramento

## Benefícios Esperados

- **Melhoria na Qualidade**: Classificações mais precisas baseadas em evidência real
- **Redução de Custos**: Menos envios para números inválidos
- **Maior Engajamento**: Foco em telefones com maior probabilidade de resposta
- **Ciclo Virtuoso**: Cada campanha melhora a qualidade dos dados para a próxima