-- Consolida informações de assistência social (CRAS) de pessoa física a partir do
-- sistema SMAS
-- TODO: Ajustar nomes dos campos conforme o schema real da tabela 'cadastros' do
-- rj-smas
{{
    config(
        alias="dim_educacao",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

with
    -- Fonte de CPFs
    all_cpf as (select cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}),

    -- Fonte de dados de educação (cadastros)
    -- Estrutura de educação por CPF
    educacao_struct as (
        select
            cpf,
            "boa" as aluno_conceito,
            0.9 as aluno_frequencia,
            "EM Almirante Tamandaré" as escola_nome,
            "8:00 às 17:00" as escola_horario_funcionamento,
            "1234567890" as escola_telefone,
            "escola@email.com" as escola_email,
            "1234567890" as escola_whatsapp,
            "Rua das Flores, 123" as escola_endereco,

        from all_cpf  -- # TODO: obter relacao de alunos da educacao
    ),

    dim_educacao as (
        select
            all_cpf.cpf,
            struct(
                struct(
                    if(
                        educacao_struct.aluno_conceito is not null, true, false
                    ) as indicador,
                    educacao_struct.aluno_conceito as conceito,
                    educacao_struct.aluno_frequencia as frequencia
                ) as aluno,
                struct(
                    educacao_struct.escola_nome as nome,
                    educacao_struct.escola_horario_funcionamento
                    as horario_funcionamento,
                    educacao_struct.escola_telefone as telefone,
                    educacao_struct.escola_email as email,
                    educacao_struct.escola_whatsapp as whatsapp,
                    educacao_struct.escola_endereco as endereco
                ) as escola
            ) as educacao
        from all_cpf
        left join educacao_struct using (cpf)
    )

select *
from dim_educacao
