{{
    config(
        materialized="table",
        schema="intermediario_rmi_conversas",
        tags=["hourly"],
        unique_key=["id_hsm", "contato_telefone", "data_particao"],
        partition_by={
            "field": "data_particao",
            "data_type": "date"
    },
    )
}}

-- Status de entrega das HSMs com tracking disponível
-- União das tabelas mensais de fluxo_atendimento

WITH last_webhook AS (
    select 
    triggerId as id_hsm,
    flatTarget as contato_telefone,
    
    -- Timestamps com ajuste de fuso horário
    timestamp_sub(createDate, interval 3 hour) as criacao_datahora,
    timestamp_sub(sendDate, interval 3 hour) as envio_datahora,
    timestamp_sub(deliveryDate, interval 3 hour) as entrega_datahora,
    timestamp_sub(readDate, interval 3 hour) as leitura_datahora,
    timestamp_sub(replyDate, interval 3 hour) as resposta_datahora,
    timestamp_sub(failedDate, interval 3 hour) as falha_datahora,
    faultDescription as descricao_falha,
    status as status_entrega,
    row_number() over (
        partition by triggerId, flatTarget 
        order by datarelay_timestamp desc
    ) as rn

from `rj-crm-registry.brutos_wetalkie_staging.fluxo_atendimento_*`
where sendDate >= '2020-01-01'
    and triggerId is not null
)

SELECT *, DATE(criacao_datahora) AS data_particao FROM last_webhook
WHERE rn=1