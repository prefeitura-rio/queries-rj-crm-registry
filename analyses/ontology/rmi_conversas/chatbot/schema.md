# Schema - rmi_conversas.chatbot (REVISADO)

## Estrutura da Tabela - TODAS AS INTERAÇÕES

### Campos de Identificação

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `id_interacao` | STRING | UUID único da tentativa de interação | Gerado |
| `cpf_cidadao` | STRING | CPF do cidadão (quando disponível) | `crm_whatsapp.contato.cpf` |
| `telefone_contato` | STRING | Telefone do contato | `disparos_efetuados.to` |
| `id_hsm` | INTEGER | ID da HSM enviada | `disparos_efetuados.id_hsm` |
| `id_sessao` | STRING | ID da sessão (apenas se houve resposta) | `crm_whatsapp.sessao.id_sessao` |

### Campos Temporais (REVISADOS)

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `data_interacao` | DATE | Data da tentativa de interação | `disparos_efetuados.dispatch_date` |
| `disparo_datahora` | DATETIME | Quando a HSM foi disparada | `disparos_efetuados.dispatch_date` |
| `envio_datahora` | DATETIME | Quando foi enviada ao WhatsApp | `fluxo_atendimento.sendDate` |
| `entrega_datahora` | DATETIME | Quando foi entregue ao usuário | `fluxo_atendimento.receiveDate` |
| `leitura_datahora` | DATETIME | Quando foi lida pelo usuário | `fluxo_atendimento.readDate` |
| `resposta_datahora` | DATETIME | Quando o usuário respondeu | `fluxo_atendimento.replyDate` |
| `inicio_conversa_datahora` | DATETIME | Início da sessão URA (se houver) | `crm_whatsapp.sessao.inicio_datahora` |
| `fim_conversa_datahora` | DATETIME | Fim da sessão URA (se houver) | `crm_whatsapp.sessao.fim_datahora` |

### Campos de Classificação (REVISADOS)

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `tipo_interacao` | STRING | Nível de completude da interação | Derivado (ver tipos acima) |
| `categoria_hsm` | STRING | Categoria da mensagem | `disparos_efetuados.campaignName` |
| `orgao_responsavel` | STRING | Órgão que enviou a HSM | `mensagem_ativa.orgao` |
| `nome_campanha` | STRING | Nome da campanha | `disparos_efetuados.campaignName` |
| `template_hsm` | STRING | Template usado | `mensagem_ativa.nome_hsm` |

### Campos de Resultado

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `desfecho_conversa` | STRING | RESOLVIDA_AUTOMATICA, TRANSFERIDA_HUMANO, ABANDONADA | Derivado |
| `teve_resposta_cidadao` | BOOLEAN | Se o cidadão respondeu à HSM | Derivado |
| `teve_busca` | BOOLEAN | Se houve busca por informações | `crm_whatsapp.sessao.busca.indicador` |
| `teve_erro_fluxo` | BOOLEAN | Se houve erro no fluxo | `crm_whatsapp.sessao.erro_fluxo.indicador` |

### Campos de Estatísticas

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `total_mensagens` | INTEGER | Total de mensagens na conversa | `crm_whatsapp.sessao.estatisticas.total_mensagens` |
| `mensagens_cidadao` | INTEGER | Mensagens enviadas pelo cidadão | `crm_whatsapp.sessao.estatisticas.total_mensagens_contato` |
| `mensagens_busca` | INTEGER | Mensagens relacionadas à busca | `crm_whatsapp.sessao.estatisticas.total_mensagens_busca` |
| `tempo_resposta_medio_seg` | FLOAT | Tempo médio de resposta do cidadão | `crm_whatsapp.sessao.estatisticas.tempo_medio_resposta_cliente_seg` |

### Campos de Conteúdo (Estruturas Aninhadas)

#### `hsm_detalhes` (STRUCT)
```sql
STRUCT<
  id_hsm INTEGER,
  nome_hsm STRING,
  ambiente STRING,
  categoria STRING,
  orgao STRING,
  criacao_envio_datahora TIMESTAMP,
  envio_datahora TIMESTAMP,
  entrega_datahora TIMESTAMP,
  leitura_datahora TIMESTAMP,
  resposta_datahora TIMESTAMP,
  falha_datahora TIMESTAMP,
  descricao_falha STRING
>
```

#### `mensagens` (ARRAY<STRUCT>)
```sql
ARRAY<STRUCT<
  data TIMESTAMP,
  texto STRING,
  tipo STRING,
  fonte STRING,
  operador STRING,
  hsm STRING,
  anexos ARRAY<STRING>,
  midia STRUCT<
    arquivo STRING,
    nome STRING,
    tipo_conteudo STRING
  >,
  passo_ura STRUCT<
    nome STRING,
    id INTEGER
  >
>>
```

#### `busca_detalhes` (STRUCT)
```sql
STRUCT<
  indicador BOOLEAN,
  feedback STRUCT<
    pergunta STRING,
    resposta STRING,
    resposta_negativa_complemento STRING
  >
>
```

#### `ura_detalhes` (STRUCT)
```sql  
STRUCT<
  id STRING,
  nome STRING,
  observacao STRING,
  operador STRING,
  usuario_finalizacao STRING,
  fila STRING,
  tabulacao STRUCT<
    nome STRING,
    id STRING
  >
>
```

### Campos de Particionamento e Metadados

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `data_particao` | DATE | Data de particionamento | `crm_whatsapp.sessao.data_particao` |
| `data_processamento` | DATETIME | Timestamp do processamento dbt | Gerado |

## Configurações da Tabela

### Particionamento
- **Campo**: `data_particao` 
- **Tipo**: Particionamento por dia
- **Retenção**: Definir política de retenção

### Clustering
- **Campos**: `cpf_cidadao`, `tipo_conversa`, `orgao_responsavel`
- **Objetivo**: Otimizar consultas por cidadão e tipo de conversa

### Materialização
- **Tipo**: TABLE
- **Refresh**: Incremental baseado em `data_particao`
- **Unique Key**: `id_conversa`

## Regras de Negócio

### Classificação de Tipo de Conversa
1. **HSM_ONLY**: Apenas HSM enviada, sem resposta do cidadão
2. **URA_COMPLETA**: HSM + resposta do cidadão + fluxo URA
3. **ATENDIMENTO_HUMANO**: Transferência para operador humano

### Classificação de Desfecho
1. **RESOLVIDA_AUTOMATICA**: Fluxo concluído sem intervenção humana
2. **TRANSFERIDA_HUMANO**: Sessão transferida para operador
3. **ABANDONADA**: Cidadão não completou o fluxo

### Critérios de Qualidade
- CPF obrigatório quando disponível na tabela contato
- Telefone sempre presente
- Data de conversa sempre válida
- Duração >= 0 quando calculável