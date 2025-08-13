# Rastreamento de Telefone no CRM Registry

Este documento mapeia todas as ocorrências e usos da palavra "telefone" em modelos SQL e configurações YAML no projeto CRM Registry da Prefeitura do Rio de Janeiro.

## Visão Geral

O projeto possui um ecossistema complexo de modelos que lidam com dados telefônicos em diferentes contextos:
- **Consolidação de dados mestres** de pessoas físicas e jurídicas
- **Comunicação via WhatsApp** e plataformas CRM
- **Interações cidadão-prefeitura** através de diferentes canais
- **Padronização e validação** de números telefônicos

## Categorização de Uso

### 1. Macros de Padronização

#### `macros/padronize_telefone.sql`
**Função**: Macro para limpeza e padronização de números telefônicos
**Uso**: Validação e formatação de telefones em todo o projeto
**Localização**: `/macros/padronize_telefone.sql`

```sql
{% macro padronize_telefone(telefone_column) %}
```

**Features**:
- Remove números inválidos (zeros repetidos, notação científica)
- Padroniza formato brasileiro
- Filtra caracteres não numéricos

---

### 2. Dados Mestres - Pessoa Física

#### `int_pessoa_fisica_dim_telefone.sql`
**Função**: Modelo intermediário que consolida telefones de pessoas físicas
**Localização**: `models/intermediate/rmi_dados_mestre/pessoa_fisica/`
**Materialização**: Ephemeral

**Estrutura de dados**:
- `telefone` (STRUCT): Estrutura completa com indicador, principal, alternativo
- `telefone.principal`: Telefone prioritário com DDI, DDD, valor
- `telefone.alternativo`: Array de telefones secundários

**CTEs principais**:
- `telefone`: Extração de telefones de fontes SMS
- `telefone_corrigido`: Aplicação de padronização
- `telefone_ranqueado`: Ranking por qualidade/recência
- `telefone_estruturado`: Agrupamento em arrays por CPF
- `telefone_principal_alternativo`: Separação principal/alternativo
- `dim_telefone`: Estrutura final consolidada

**Fontes de dados**:
- Sistema SMS (rj-sms): Telefones de cadastros de saúde
- Sistema SMAS: Telefones de assistência social (via contato.telefone)

#### `pessoa_fisica.sql` (Core)
**Função**: Dimensão principal de pessoas físicas
**Localização**: `models/core/rmi_dados_mestre/`
**Uso de telefone**: Inclui estrutura completa via join com `dim_telefone`

```sql
left join dim_telefone using (cpf)
```

#### `pessoa_fisica.yml`
**Documentação detalhada** da estrutura de telefone:
- `telefone.indicador`: Boolean indicando presença de telefone
- `telefone.principal.*`: Campos do telefone principal (origem, sistema, DDI, DDD, valor)  
- `telefone.alternativo.*`: Array de telefones secundários
- `saude.*.telefone`: Telefones de unidades de saúde

---

### 3. Dados Mestres - Pessoa Jurídica

#### `pessoa_juridica.yml`
**Documentação** de telefones empresariais:
- `telefone.ddd`: DDD dos telefones da empresa
- `telefone.telefone`: Números de telefone da empresa

---

### 4. CRM WhatsApp

#### `fct_whatsapp_sessao.sql`
**Função**: Fatos de sessões WhatsApp
**Uso de telefone**: Campo `contato_telefone` como identificador de contato
**Localização**: `models/core/crm_whatsapp/`

```sql
flatTarget AS contato_telefone
```

#### `dim_whatsapp_telefone_sem_whatsapp.sql` 
**Função**: Dimensão de telefones não WhatsApp
**Alias**: `telefone_sem_whatsapp`
**Schema**: `crm_whatsapp`
**Materialização**: Table, tags hourly

#### `fct_whatsapp_telefone_disparado.sql`
**Função**: Fatos de telefones com disparos WhatsApp
**Alias**: `telefone_disparado`
**Chave única**: `["id_hsm", "contato_telefone", "data_particao"]`

#### `int_whatsapp_fluxo_atendimento.sql`
**Função**: Modelo intermediário de fluxo de atendimento
**Campo**: `contato_telefone` extraído de `flatTarget`

---

### 5. Interações Cidadão-Prefeitura

#### `int_interacoes_wetalkie.sql`
**Função**: Interações via plataforma Wetalkie  
**Localização**: `models/intermediate/rmi_eventos/interacoes_pessoa_fisica_prefeitura/`

**Lógica de telefone**:
- Validação de telefone válido: `length(to) >= 10`
- **Linking CPF-Telefone**: Busca CPF através de join com `dim_pessoa_fisica` usando telefone
- **Construção de telefone completo**: Concatenação DDI + DDD + número

**CTEs de telefone**:
- `telefones_principais`: Telefones principais de `dim_pessoa_fisica`
- `telefones_alternativos`: Telefones alternativos expandidos
- `todos_telefones_pessoa`: União de principais + alternativos

**Campos de saída**:
- `telefone`: Número de destino da interação
- `cpf_linkado_por_telefone`: Indicador de sucesso no linking

#### `interacoes_pessoa_fisica_prefeitura.sql` (Core)
**Uso**: Referência a CPF obtido via telefone em comentários
**Localização**: `models/core/rmi_eventos/`

---

### 6. Dados de Saúde

#### `int_pessoa_fisica_dim_saude.sql`
**Função**: Dimensão de saúde de pessoas físicas
**Campos telefone**:
- `eqp.equipe_saude_familia.clinica_familia.telefone`: Telefone da clínica
- `equipe_saude_familia.telefone`: Telefone da equipe de saúde

---

### 7. Dados Fazenda/Secretarias

#### `base_rj-smfp_vinculo.sql`
**Função**: Base de vínculos da Secretaria Municipal de Fazenda e Planejamento
**Campo**: `telefone_requisicao` 
**Localização**: `models/raw/secretaria_fazenda/`

---

### 8. Mocked Data

#### `mart_mocked_data_dim_pessoa_fisica.sql`
**Função**: Dados mockados para testes
**Uso**: Referência a `dim_telefone` e estrutura de telefones para clínicas
**Localização**: `models/marts/mocked_data/`

---

## Padrões Arquiteturais Identificados

### 1. **Estrutura Hierárquica de Telefone**
```sql
telefone: {
  indicador: BOOLEAN,
  principal: {origem, sistema, ddi, ddd, valor},
  alternativo: [{origem, sistema, ddi, ddd, valor}, ...]
}
```

### 2. **Padronização via Macro**
Todos os modelos que processam telefones usam `{{ padronize_telefone() }}` para limpeza.

### 3. **Linking CPF-Telefone** 
O modelo `int_interacoes_wetalkie.sql` implementa um padrão avançado de linking onde:
- Interações têm apenas telefone de destino
- CPF é recuperado via join com `dim_pessoa_fisica`
- Suporte a telefones principais e alternativos

### 4. **Separação por Domínio**
- **RMI**: Consolidação de dados mestres
- **CRM WhatsApp**: Comunicação e campanhas
- **Interações**: Relacionamento cidadão-governo
- **Saúde**: Dados específicos do setor

### 5. **Materialização por Contexto**
- **Intermediate**: Ephemeral (processamento)
- **Core**: Table (consulta)
- **WhatsApp facts**: Table com refresh hourly

## Dependências e Relacionamentos

### Fluxo de Dados de Telefone:

```
Sources (SMS, SMAS, etc.)
       ↓
int_pessoa_fisica_dim_telefone (consolidação)
       ↓
pessoa_fisica.telefone (core dimension)
       ↓
int_interacoes_wetalkie (linking via telefone)
       ↓  
interacoes_pessoa_fisica_prefeitura (interações)
```

### Fluxo WhatsApp:
```
WhatsApp Sources
       ↓
int_whatsapp_fluxo_atendimento (contato_telefone)
       ↓
fct_whatsapp_sessao + dim_whatsapp_telefone_* 
```

## Campos Padronizados

Todos os modelos seguem a convenção de campos de telefone:

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `ddi` | STRING | Código do país (ex: "55") |
| `ddd` | STRING | Código de área (ex: "21") |  
| `valor`/`numero` | STRING | Número sem formatação |
| `origem` | STRING | Órgão que cadastrou |
| `sistema` | STRING | Sistema de origem |
| `rank` | INT | Ranking de qualidade/recência |

## Considerações para RMI Telefones

Este mapeamento revela que o projeto já possui:

1. **Consolidação robusta** via `int_pessoa_fisica_dim_telefone`
2. **Padronização consistente** via macro `padronize_telefone` 
3. **Linking inteligente** CPF↔Telefone em interações
4. **Estruturas hierárquicas** (principal/alternativo)
5. **Separação por contexto** (saúde, WhatsApp, interações)

O **RMI Telefones** deve se integrar a este ecossistema existente, potencialmente:
- Expandindo a lógica de `int_pessoa_fisica_dim_telefone`
- Criando views/fatos específicos para análise de qualidade
- Implementando histórico e auditoria de mudanças
- Consolidando dados de pessoa jurídica