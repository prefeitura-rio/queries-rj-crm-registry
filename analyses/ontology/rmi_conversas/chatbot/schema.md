# Schema - rmi_conversas.chatbot

## Estrutura da Tabela

### Campos de Identificação

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `id_conversa` | STRING | UUID único da conversa | Gerado |
| `cpf_cidadao` | STRING | CPF do cidadão (quando disponível) | `crm_whatsapp.contato.cpf` |
| `telefone_contato` | STRING | Telefone do contato | `crm_whatsapp.contato.contato_telefone` |
| `id_sessao` | STRING | ID da sessão no sistema Wetalkie | `crm_whatsapp.sessao.id_sessao` |

### Campos Temporais

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `data_conversa` | DATE | Data da conversa | `crm_whatsapp.sessao.inicio_data` |
| `inicio_datahora` | DATETIME | Início da sessão | `crm_whatsapp.sessao.inicio_datahora` |
| `fim_datahora` | DATETIME | Fim da sessão | `crm_whatsapp.sessao.fim_datahora` |
| `duracao_total_seg` | FLOAT | Duração total em segundos | `crm_whatsapp.sessao.estatisticas.duracao_sessao_seg` |

### Campos de Classificação

| Campo | Tipo | Descrição | Fonte |
|-------|------|-----------|-------|
| `tipo_conversa` | STRING | HSM_ONLY, URA_COMPLETA, ATENDIMENTO_HUMANO | Derivado |
| `categoria_hsm` | STRING | Categoria da mensagem (utilidade, marketing, autenticação) | `crm_whatsapp.sessao.hsm.categoria` |
| `orgao_responsavel` | STRING | Órgão que enviou a HSM | `crm_whatsapp.sessao.hsm.orgao` |
| `nome_hsm` | STRING | Nome/template da HSM | `crm_whatsapp.sessao.hsm.nome_hsm` |

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