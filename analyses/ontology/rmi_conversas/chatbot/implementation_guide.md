# Guia de Implementação - rmi_conversas.chatbot

## Estrutura de Arquivos

### 1. Modelo Principal
**Arquivo**: `models/core/rmi_conversas/chatbot.sql`
**Materialização**: `table`
**Estratégia**: Incremental com merge

### 2. Documentação
**Arquivo**: `models/core/rmi_conversas/chatbot.yml`
**Conteúdo**: Schema, testes, descrições

### 3. Modelos Intermediários (se necessário)
- `models/intermediate/rmi_conversas/int_chatbot_sessoes.sql`
- `models/intermediate/rmi_conversas/int_chatbot_hsm_standalone.sql`

## Configuração do Modelo

```sql
{{
    config(
        alias="chatbot",
        schema="rmi_conversas", 
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="id_conversa",
        partition_by={
            "field": "data_particao", 
            "data_type": "date"
        },
        cluster_by=["cpf_cidadao", "tipo_conversa", "orgao_responsavel"],
        on_schema_change="sync_all_columns"
    )
}}
```

## Estrutura do Modelo SQL

### 1. CTEs Base
```sql
with 
-- CTE 1: Sessões completas com URA
sessoes_completas as (
    select 
        -- Campos de identificação
        generate_uuid() as id_conversa,
        safe_cast(c.cpf as string) as cpf_cidadao,
        s.contato_telefone as telefone_contato,
        s.id_sessao,
        
        -- Campos temporais
        s.inicio_data as data_conversa,
        s.inicio_datahora,
        s.fim_datahora,
        coalesce(
            s.estatisticas.duracao_sessao_seg,
            timestamp_diff(s.fim_datahora, s.inicio_datahora, SECOND)
        ) as duracao_total_seg,
        
        -- Classificações
        case 
            when s.operador is not null then 'ATENDIMENTO_HUMANO'
            when array_length(s.mensagens) > 1 then 'URA_COMPLETA'
            else 'HSM_ONLY'
        end as tipo_conversa,
        
        s.hsm.categoria as categoria_hsm,
        s.hsm.orgao as orgao_responsavel,
        s.hsm.nome_hsm,
        
        -- Resultados
        case 
            when s.operador is not null then 'TRANSFERIDA_HUMANO'
            when s.busca.indicador = true and s.busca.feedback.resposta is not null 
                then 'RESOLVIDA_AUTOMATICA'
            when s.fim_datahora is null then 'ABANDONADA'
            else 'RESOLVIDA_AUTOMATICA'
        end as desfecho_conversa,
        
        s.hsm.resposta_datahora is not null as teve_resposta_cidadao,
        coalesce(s.busca.indicador, false) as teve_busca,
        coalesce(s.erro_fluxo.indicador, false) as teve_erro_fluxo,
        
        -- Estatísticas
        s.estatisticas.total_mensagens,
        s.estatisticas.total_mensagens_contato as mensagens_cidadao,
        s.estatisticas.total_mensagens_busca as mensagens_busca,
        s.estatisticas.tempo_medio_resposta_cliente_seg as tempo_resposta_medio_seg,
        
        -- Estruturas aninhadas
        s.hsm as hsm_detalhes,
        s.mensagens,
        s.busca as busca_detalhes,
        s.ura as ura_detalhes,
        
        -- Metadados
        s.data_particao,
        current_datetime() as data_processamento
        
    from {{ ref('raw_wetalkie_fluxos_ura') }} s
    left join {{ source('crm_whatsapp', 'contato') }} c
        on s.contato_telefone = c.contato_telefone
        and c.data_particao = (
            select max(data_particao)
            from {{ source('crm_whatsapp', 'contato') }} c2
            where c2.contato_telefone = c.contato_telefone
        )
    where s.inicio_datahora >= '2020-01-01'
),

-- CTE 2: HSMs sem resposta (opcional - para análise completa)
hsm_sem_resposta as (
    select 
        generate_uuid() as id_conversa,
        safe_cast(c.cpf as string) as cpf_cidadao,
        d.`to` as telefone_contato,
        null as id_sessao,
        
        date(d.dispatch_date) as data_conversa,
        datetime(d.dispatch_date) as inicio_datahora,
        null as fim_datahora,
        null as duracao_total_seg,
        
        'HSM_ONLY' as tipo_conversa,
        null as categoria_hsm,
        null as orgao_responsavel,
        d.campaignName as nome_hsm,
        
        'ABANDONADA' as desfecho_conversa,
        false as teve_resposta_cidadao,
        false as teve_busca,
        false as teve_erro_fluxo,
        
        0 as total_mensagens,
        0 as mensagens_cidadao,
        0 as mensagens_busca,
        null as tempo_resposta_medio_seg,
        
        -- Estrutura HSM simplificada
        struct(
            d.id_hsm,
            null as criacao_envio_datahora,
            timestamp(d.dispatch_date) as envio_datahora,
            null as entrega_datahora,
            null as leitura_datahora,
            null as falha_datahora,
            null as resposta_datahora,
            null as descricao_falha,
            d.campaignName as nome_hsm,
            null as ambiente,
            null as categoria,
            null as orgao
        ) as hsm_detalhes,
        
        null as mensagens,
        null as busca_detalhes, 
        null as ura_detalhes,
        
        cast(d.data_particao as date) as data_particao,
        current_datetime() as data_processamento
        
    from {{ source('brutos_wetalkie_staging', 'disparos_efetuados') }} d
    left join {{ source('crm_whatsapp', 'contato') }} c
        on d.`to` = c.contato_telefone
    where d.id_hsm not in (
        select hsm.id_hsm 
        from {{ ref('raw_wetalkie_fluxos_ura') }}
        where hsm.id_hsm is not null
    )
    and datetime(d.dispatch_date) >= '2020-01-01'
),

-- CTE 3: União das fontes
conversas_unificadas as (
    select * from sessoes_completas
    
    -- Opcional: incluir HSMs sem resposta
    -- union all
    -- select * from hsm_sem_resposta
)
```

### 2. Query Final
```sql
select * from conversas_unificadas

-- Filtro incremental
{% if is_incremental() %}
    where data_particao > (select max(data_particao) from {{ this }})
{% endif %}

order by inicio_datahora desc
```

## Configuração de Testes

### 1. Testes Básicos
```yaml
# chatbot.yml
version: 2

models:
  - name: chatbot
    description: "Conversas completas via chatbot por CPF"
    
    config:
      materialized: table
      
    columns:
      - name: id_conversa
        description: "UUID único da conversa"
        tests:
          - unique
          - not_null
          
      - name: cpf_cidadao  
        description: "CPF do cidadão (quando disponível)"
        tests:
          - custom_cpf_format
          
      - name: data_conversa
        description: "Data da conversa"
        tests:
          - not_null
          - custom_valid_date_range:
              min_date: '2020-01-01'
              max_date: 'current_date()'
              
      - name: tipo_conversa
        description: "Tipo de conversa"
        tests:
          - accepted_values:
              values: ['HSM_ONLY', 'URA_COMPLETA', 'ATENDIMENTO_HUMANO']
              
      - name: desfecho_conversa
        description: "Resultado da conversa"  
        tests:
          - accepted_values:
              values: ['RESOLVIDA_AUTOMATICA', 'TRANSFERIDA_HUMANO', 'ABANDONADA']
```

### 2. Testes de Qualidade de Dados
```yaml
# Arquivo separado: data-tests/chatbot_quality_tests.yml
version: 2

data_tests:
  - name: chatbot_cpf_linkage_rate
    description: "Taxa de linkagem CPF deve ser >= 70%"
    sql: |
      select 
        count(*) as total_conversas,
        sum(case when cpf_cidadao is not null then 1 else 0 end) as com_cpf,
        safe_divide(
          sum(case when cpf_cidadao is not null then 1 else 0 end),
          count(*)
        ) as taxa_linkagem
      from {{ ref('chatbot') }}
      where data_particao >= current_date() - 30
      having taxa_linkagem < 0.7
      
  - name: chatbot_response_consistency
    description: "Consistência entre teve_resposta_cidadao e tipo_conversa"
    sql: |
      select *
      from {{ ref('chatbot') }}
      where (teve_resposta_cidadao = true and tipo_conversa = 'HSM_ONLY')
         or (teve_resposta_cidadao = false and tipo_conversa in ('URA_COMPLETA', 'ATENDIMENTO_HUMANO'))
```

## Estratégia de Deploy

### 1. Desenvolvimento
```bash
# Teste local
dbt run --select chatbot --target dev

# Validação  
dbt test --select chatbot --target dev
```

### 2. Produção
```bash
# Full refresh inicial
dbt run --select chatbot --full-refresh --target prod

# Runs incrementais subsequentes
dbt run --select chatbot --target prod
```

## Monitoramento

### 1. Métricas de Volume
- Total de conversas por dia
- Taxa de crescimento semanal/mensal
- Distribuição por tipo de conversa

### 2. Métricas de Qualidade
- Taxa de linkagem CPF
- Percentual de conversas com erro
- Cobertura temporal (gaps de dados)

### 3. Alertas
- Queda >20% no volume diário
- Taxa de linkagem CPF <60%
- Aumento >50% em conversas com erro

## Otimizações de Performance

### 1. Clustering Strategy
- `cpf_cidadao`: Para consultas por cidadão
- `tipo_conversa`: Para análises por tipo
- `orgao_responsavel`: Para análises por órgão

### 2. Partition Pruning
- Sempre incluir filtro em `data_particao` nas consultas
- Manter partições dos últimos 24 meses

### 3. Query Optimization
- Pre-agregar métricas em modelos mart se necessário
- Considerar views materializadas para consultas frequentes