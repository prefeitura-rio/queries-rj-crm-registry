{{
    config(
        materialized="table",
        schema="intermediario_rmi_conversas"
    )
}}

-- Base consolidada de disparos com metadados de campanha
-- Fonte: telefone_disparado + mensagem_ativa para dados completos

select 
    td.id_hsm,
    td.contato_telefone as telefone_contato,
    datetime(td.data_disparo) as disparo_datahora,
    td.data_disparo as data_interacao,
    coalesce(ma.nome_hsm, 'Unknown') as nome_campanha,
    ma.orgao as orgao_responsavel,
    ma.categoria as categoria_hsm,
    ma.ambiente,
    cast(td.id_disparo as string) as id_externo,
    td.descricao_falha,
    td.data_particao,
    
    -- Chave única determinística
    concat(
        cast(td.id_hsm as string), 
        '_',
        td.contato_telefone,
        '_',
        cast(td.id_disparo as string)
    ) as chave_unica

from `rj-crm-registry.crm_whatsapp.telefone_disparado` td
left join `rj-crm-registry.crm_whatsapp.mensagem_ativa` ma
    on td.id_hsm = ma.id_hsm
where td.data_disparo >= '2020-01-01'
    and td.contato_telefone is not null
    and length(td.contato_telefone) >= 10