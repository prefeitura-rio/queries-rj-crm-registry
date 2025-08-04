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

-- Modelo de conversas completas via chatbot por CPF
-- Consolida interações do WhatsApp através da plataforma Wetalkie

with 

-- Contatos com ranking por data mais recente
contatos_ranked as (
    select 
        *,
        row_number() over (
            partition by contato_telefone 
            order by data_particao desc
        ) as rn
    from `rj-crm-registry.crm_whatsapp.contato`
),

contatos_mais_recentes as (
    select * 
    from contatos_ranked 
    where rn = 1
),

-- Sessões completas com dados de URA e HSM
sessoes_completas as (
    select 
        -- IDENTIFICAÇÃO
        generate_uuid() as id_conversa,
        safe_cast(c.cpf as string) as cpf_cidadao,
        s.contato_telefone as telefone_contato,
        s.id_sessao,
        
        -- TEMPORAL
        s.inicio_data as data_conversa,
        s.inicio_datahora,
        s.fim_datahora,
        coalesce(
            s.estatisticas.duracao_sessao_seg,
            timestamp_diff(s.fim_datahora, s.inicio_datahora, SECOND)
        ) as duracao_total_seg,
        
        -- CLASSIFICAÇÃO
        case 
            when s.operador is not null then 'ATENDIMENTO_HUMANO'
            when array_length(s.mensagens) > 1 then 'URA_COMPLETA'
            else 'HSM_ONLY'
        end as tipo_conversa,
        
        coalesce(s.hsm.categoria, 'UTILIDADE') as categoria_hsm,
        coalesce(s.hsm.orgao, 'NAO_INFORMADO') as orgao_responsavel,
        s.hsm.nome_hsm,
        
        -- RESULTADO
        case 
            when s.operador is not null then 'TRANSFERIDA_HUMANO'
            when s.busca.indicador = true and s.busca.feedback.resposta is not null 
                then 'RESOLVIDA_AUTOMATICA'
            when s.fim_datahora is null then 'ABANDONADA'
            when s.hsm.resposta_datahora is null then 'ABANDONADA'
            else 'RESOLVIDA_AUTOMATICA'
        end as desfecho_conversa,
        
        coalesce(s.hsm.resposta_datahora is not null, false) as teve_resposta_cidadao,
        coalesce(s.busca.indicador, false) as teve_busca,
        coalesce(s.erro_fluxo.indicador, false) as teve_erro_fluxo,
        
        -- ESTATÍSTICAS
        coalesce(s.estatisticas.total_mensagens, 0) as total_mensagens,
        coalesce(s.estatisticas.total_mensagens_contato, 0) as mensagens_cidadao,
        coalesce(s.estatisticas.total_mensagens_busca, 0) as mensagens_busca,
        s.estatisticas.tempo_medio_resposta_cliente_seg as tempo_resposta_medio_seg,
        
        -- ESTRUTURAS ANINHADAS
        struct(
            s.hsm.id_hsm,
            s.hsm.criacao_envio_datahora,
            s.hsm.envio_datahora,
            s.hsm.entrega_datahora,
            s.hsm.leitura_datahora,
            s.hsm.falha_datahora,
            s.hsm.resposta_datahora,
            s.hsm.descricao_falha,
            s.hsm.nome_hsm,
            s.hsm.ambiente,
            s.hsm.categoria,
            s.hsm.orgao
        ) as hsm_detalhes,
        
        s.mensagens,
        
        struct(
            coalesce(s.busca.indicador, false) as indicador,
            struct(
                s.busca.feedback.pergunta,
                s.busca.feedback.resposta,
                s.busca.feedback.resposta_negativa_complemento
            ) as feedback
        ) as busca_detalhes,
        
        struct(
            s.ura.id,
            s.ura.nome,
            s.observacao,
            s.operador,
            s.usuario_finalizacao,
            s.fila,
            struct(
                s.tabulacao.nome,
                s.tabulacao.id
            ) as tabulacao
        ) as ura_detalhes,
        
        -- METADADOS
        s.data_particao,
        current_datetime() as data_processamento
        
    from `rj-crm-registry.crm_whatsapp.sessao` s
    left join contatos_mais_recentes c
        on s.contato_telefone = c.contato_telefone
    where s.inicio_datahora >= '2020-01-01'
        -- Filtrar dados de teste
        and lower(coalesce(s.hsm.nome_hsm, '')) not like '%teste%'
        and lower(coalesce(s.hsm.orgao, '')) not like '%teste%'
        -- Garantir dados válidos
        and s.contato_telefone is not null
        and length(s.contato_telefone) >= 10
),

-- Resultado final
conversas_chatbot as (
    select * from sessoes_completas
)

select * from conversas_chatbot

-- Filtro incremental
{% if is_incremental() %}
    where data_particao > (select max(data_particao) from {{ this }})
{% endif %}