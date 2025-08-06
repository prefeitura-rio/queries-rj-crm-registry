{{
    config(
        alias="chatbot",
        schema="rmi_conversas", 
        materialized="incremental",
        incremental_strategy="merge",
        unique_key="id_interacao",
        partition_by={
            "field": "data_particao", 
            "data_type": "date"
        },
        cluster_by=["cpf_cidadao", "tipo_interacao", "orgao_responsavel"],
        on_schema_change="sync_all_columns"
    )
}}

-- MODELO FINAL: Todas as interações WhatsApp com dados completos
-- Usa intermediate tables para performance e manutenibilidade

with
interacoes_completas as (
    select 
        -- IDENTIFICAÇÃO - UUID determinístico simples baseado na chave única
        to_hex(md5(d.chave_unica)) as id_interacao,
        d.id_hsm,
        d.contato_telefone,
        c.cpf as cpf_cidadao,
        c.nome_contato,
        conv.id_sessao,
        
        -- TEMPORALIDADE COMPLETA
        d.data_interacao,
        d.disparo_datahora,
        se.criacao_datahora,
        se.envio_datahora,
        se.entrega_datahora,
        se.leitura_datahora,
        se.resposta_datahora,
        se.falha_datahora,
        conv.inicio_datahora as inicio_conversa_datahora,
        conv.fim_datahora as fim_conversa_datahora,
        
        -- CLASSIFICAÇÃO HIERÁRQUICA POR COMPLETUDE
        case 
            -- Problemas conhecidos
            when tp.tipo_problema = 'PHONE_INVALID_WHATSAPP' then 'PHONE_INVALID'
            when tp.tipo_problema = 'OPTED_OUT' then 'OPTED_OUT'
            
            -- Falhas técnicas
            when se.falha_datahora is not null then 'DELIVERY_FAILED'
            when se.envio_datahora is not null and se.entrega_datahora is null then 'SENT_NOT_DELIVERED'
            
            -- Diferentes níveis de engajamento
            when se.entrega_datahora is not null and se.leitura_datahora is null then 'DELIVERED_NOT_READ'
            when se.leitura_datahora is not null and se.resposta_datahora is null then 'READ_NO_RESPONSE'
            
            -- Conversas (apenas se responderam)
            when conv.resultado_conversa = 'ESCALATED_TO_HUMAN' then 'ESCALATED_TO_HUMAN'
            when conv.resultado_conversa = 'RESOLVED_AUTOMATICALLY' then 'RESOLVED_AUTOMATICALLY'
            when conv.resultado_conversa = 'CONVERSATION_ABANDONED' then 'CONVERSATION_ABANDONED'
            when conv.resultado_conversa = 'CONVERSATION_ERROR' then 'CONVERSATION_ERROR'
            when conv.resultado_conversa = 'CONVERSATION_COMPLETED' then 'CONVERSATION_COMPLETED'
            
            -- Status desconhecido (sem tracking)
            when se.id_hsm is null and conv.id_hsm is null then 'STATUS_UNKNOWN'
            else 'OTHER'
        end as tipo_interacao,
        
        -- DADOS DA CAMPANHA
        d.nome_campanha,
        d.orgao_responsavel,
        d.categoria_hsm,
        d.nome_campanha as template_hsm,
        d.ambiente,
        
        -- INDICADORES BOOLEANOS
        se.entrega_datahora is not null as foi_entregue,
        se.leitura_datahora is not null as foi_lida,
        se.resposta_datahora is not null as teve_resposta,
        conv.id_sessao is not null as gerou_conversa,
        tp.tipo_problema is not null as tem_problema_conhecido,
        
        -- DESCRIÇÕES DE ERRO
        coalesce(se.descricao_falha, tp.descricao_problema) as descricao_erro,
        
        -- DADOS DA CONVERSA (quando disponível)
        conv.mensagens,
        conv.busca,
        conv.ura,
        conv.estatisticas,
        conv.teve_erro_fluxo,
        conv.operador,
        conv.tabulacao,
        
        -- METADADOS ADICIONAIS
        d.id_externo,
        d.descricao_falha as falha_inicial,
        c.data_optin,
        c.data_optout,
        
        -- MÉTRICAS CALCULADAS (com validação)
        case 
            when conv.inicio_datahora is not null and conv.fim_datahora is not null
                and conv.fim_datahora > conv.inicio_datahora
                and timestamp_diff(conv.fim_datahora, conv.inicio_datahora, second) <= 86400
            then timestamp_diff(conv.fim_datahora, conv.inicio_datahora, second)
        end as duracao_conversa_seg,
        
        case 
            when se.resposta_datahora is not null and se.leitura_datahora is not null
                and se.resposta_datahora > se.leitura_datahora
                and timestamp_diff(se.resposta_datahora, se.leitura_datahora, second) <= 86400
            then timestamp_diff(se.resposta_datahora, se.leitura_datahora, second)
        end as tempo_resposta_seg,
        
        -- PARTICIONAMENTO E METADADOS
        d.data_particao,
        current_datetime() as data_processamento
        
    from {{ ref('int_chatbot_base_disparos') }} d
    
    -- Status de entrega (quando disponível)
    left join {{ ref('int_chatbot_status_entrega') }} se
        on d.id_hsm = se.id_hsm
    
    -- Conversas completas (quando responderam) - deduplicated
    left join {{ ref('int_chatbot_conversas_deduplicated') }} conv
        on d.id_hsm = conv.id_hsm 
        and d.contato_telefone = conv.contato_telefone
    
    -- Dados de contato para CPF (mais recente por telefone)
    left join (
        select 
            contato_telefone as telefone,
            safe_cast(cpf as string) as cpf,
            contato_nome as nome_contato,
            data_optin,
            data_optout
        from (
            select 
                *,
                row_number() over (
                    partition by contato_telefone 
                    order by data_particao desc
                ) as rn
            from `rj-crm-registry.crm_whatsapp.contato`
            where contato_telefone is not null
        )
        where rn = 1
    ) c on d.contato_telefone = c.telefone
    
    -- Telefones problemáticos
    left join (
        select 
            contato_telefone as telefone,
            'PHONE_INVALID_WHATSAPP' as tipo_problema,
            'Telefone não registrado no WhatsApp ou não aceitou termos' as descricao_problema
        from `rj-crm-registry.crm_whatsapp.telefone_sem_whatsapp`
    ) tp on d.contato_telefone = tp.telefone
)

select * from interacoes_completas

-- Filtro incremental
{% if is_incremental() %}
    where data_particao > (select max(data_particao) from {{ this }})
{% endif %}