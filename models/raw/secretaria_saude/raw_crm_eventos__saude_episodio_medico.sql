{{ config(alias="saude__episodio_medico", schema="crm_eventos", materialized="view") }}
with
    source as (select * from {{ source("rj-sms-historico-clinico", "episodio_assistencial") }}),
    renamed as (
        select
            id_hci,
            paciente_cpf,
            cadastros_conflitantes_indicador,
            paciente,
            tipo,
            subtipo,
            entrada_data,
            entrada_datahora,
            saida_datahora,
            exames_realizados,
            procedimentos_realizados,
            medidas,
            motivo_atendimento,
            desfecho_atendimento,
            obito_indicador,
            condicoes,
            prescricoes,
            medicamentos_administrados,
            estabelecimento,
            profissional_saude_responsavel,
            prontuario,
            metadados,
            data_particao

        from source
    )
select *
from renamed
