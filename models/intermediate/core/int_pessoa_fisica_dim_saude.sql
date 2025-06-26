-- Consolida informações de saúde de pessoa física a partir de múltiplas fontes do
-- município do Rio de Janeiro
-- Este modelo gera um struct de informações de saúde por CPF, unificando dados de saúde
{{
    config(
        alias="dim_saude",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

with
    -- sources
    all_cpf as (select cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}),

    source_sms as (
        select b.*
        from all_cpf a
        inner join {{ source("rj-sms-historico-clinico", "paciente") }} b using (cpf)
    ),

    dim_clinica_familia as (
        select * from {{ source("rj-sms-dados-mestres", "estabelecimento") }}
    ),

    -- Equipe de saúde familiar
    equipe_saude_familia_struct as (
        select cpf, equipe_saude_familia[offset(0)] as equipe_saude_familia
        from source_sms
        where array_length(equipe_saude_familia) > 0
    ),

    -- Clínica de saúde familiar
    clinica_familia_struct as (
        select
            cpf,
            eqp.equipe_saude_familia.clinica_familia.id_cnes,
            eqp.equipe_saude_familia.clinica_familia.nome,
            eqp.equipe_saude_familia.clinica_familia.telefone,
            dcf.email,
            {{ proper_br("concat(
                dcf.endereco_logradouro,
                ' ',
                dcf.endereco_numero,
                ', ',
                dcf.endereco_bairro
            )") }} as endereco,
            "8:00 às 17:00" as horario_atendimento -- # TODO: obter horário de atendimento da clínica
        from equipe_saude_familia_struct as eqp
        left join
            dim_clinica_familia as dcf
            on eqp.equipe_saude_familia.clinica_familia.id_cnes
            = dcf.id_cnes
    ),

    -- Dimensão de saúde
    dim_saude as (
        select
            all_cpf.cpf,
            struct(
            struct(
                if(clinica_familia_struct.id_cnes is not null, true, false) as indicador,
                clinica_familia_struct.id_cnes,
                clinica_familia_struct.nome,
                clinica_familia_struct.telefone,
                clinica_familia_struct.email,
                clinica_familia_struct.endereco,
                clinica_familia_struct.horario_atendimento
            ) as clinica_familia,
            struct(
                if(equipe_saude_familia is not null, true, false) as indicador,
                equipe_saude_familia.id_ine,
                equipe_saude_familia.nome,
                equipe_saude_familia.telefone,
                equipe_saude_familia.medicos,
                equipe_saude_familia.enfermeiros
            ) as equipe_saude_familia
            ) as saude
        from all_cpf
        left join equipe_saude_familia_struct using (cpf)
        left join clinica_familia_struct using (cpf)
    )

select *
from dim_saude
