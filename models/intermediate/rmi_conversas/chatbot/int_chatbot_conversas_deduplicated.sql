{{
    config(
        materialized="table",
        schema="intermediario_rmi_conversas",
        tags=["hourly"],
        unique_key=["id_hsm", "id_sessao", "inicio_datahora"],
        partition_by={
            "field": "data_particao",
            "data_type": "date"
        },
    )
}}

-- Conversas únicas por HSM+telefone para evitar multiplicação
-- Mantém apenas a conversa mais recente quando há múltiplas

select 
    id_sessao,
    safe_cast(hsm.id_hsm as int64) as id_hsm,
    contato_telefone,
    inicio_datahora,
    fim_datahora,
    
    -- Resultado da conversa
    case 
        when operador is not null then 'ESCALATED_TO_HUMAN'
        when busca.indicador = true and busca.feedback.resposta is not null 
            then 'RESOLVED_AUTOMATICALLY'
        when fim_datahora is null then 'CONVERSATION_ABANDONED'
        when erro_fluxo.indicador = true then 'CONVERSATION_ERROR'
        else 'CONVERSATION_COMPLETED'
    end as resultado_conversa,
    
    -- Dados estruturados da conversa
    mensagens,
    busca,
    ura,
    estatisticas,
    coalesce(erro_fluxo.indicador, false) as teve_erro_fluxo,
    operador,
    tabulacao
    
from (
    select 
        *,
        row_number() over (
            partition by safe_cast(hsm.id_hsm as int64), contato_telefone
            order by inicio_datahora desc
        ) as rn
    from `rj-crm-registry.crm_whatsapp.sessao`
    where inicio_datahora >= '2020-01-01'
)
where rn = 1