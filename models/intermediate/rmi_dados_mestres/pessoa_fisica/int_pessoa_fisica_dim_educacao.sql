with
    -- sources
    all_cpf as (select cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}),

    source_alunos as (
        select * from {{ source("rj-sme-brutos_gestao_escolar", "vw_bi_aluno") }}
    ),

    source_turmas as (
        select * from {{ source("rj-sme-educacao_basica_frequencia", "turma") }}
    ),

    source_escolas as (select * from {{ source("rj-sme-educacao_basica", "escola") }}),

    -- dados de alunos
    alunos as (
        select
            e.id_cre,
            e.id_inep,
            e.id_escola as escola_id,
            e.id_designacao,
            e.nome as nome_escola,
            t.id_turma,
            t.id_turma_escola,
            t.grupamento,
            t.nivel_ensino,
            t.turno,
            t.id_escola,
            a.matricula,
            a.nome,
            a.sexo,
            a.cpf,
            a.raca_cor,
            a.datanascimento,
            a.deficiencia,
            a.ult_movimentacao,
            a.situacao
        from source_alunos a
        left join source_turmas t on a.tur_id = t.id_turma
        left join source_escolas e on t.id_escola = e.id_escola
    ),

    dim_educacao as (
        select

            all_cpf.cpf,

            struct(

                if(alunos.cpf is not null, true, false) as indicador,

                struct(
                    alunos.matricula as id,
                    case
                        when lower(alunos.situacao) = 'ativo' then 'ativa'
                        when lower(alunos.situacao) = 'inativo' then 'inativa'
                        else lower(alunos.situacao)
                    end as situacao
                ) as matricula,

                struct(
                    alunos.id_turma as id,
                    {{ remove_accents_lower("alunos.nivel_ensino") }} as nivel_ensino,
                    {{ remove_accents_lower("alunos.grupamento") }} as grupamento,
                    {{ remove_accents_lower("alunos.turno") }} as turno
                ) as turma,

                struct(
                    alunos.id_escola as id,
                    alunos.nome_escola as nome,
                    alunos.id_cre,
                    alunos.id_inep
                ) as escola
            ) as educacao

        from all_cpf
        left join alunos using (cpf)

    )

select *
from dim_educacao
