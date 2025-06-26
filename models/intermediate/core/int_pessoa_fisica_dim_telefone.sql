-- Consolida contatos de pessoa física a partir de múltiplas fontes do município do
-- Rio de Janeiro
-- Este modelo gera um array de contatos por CPF, unificando dados de saúde e BCadastro
{{
    config(
        alias="dim_telefone",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

with
    all_cpf as (select cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}),

    source_bcadastro as (
        select b.*
        from all_cpf a
        inner join {{ source("bcadastro", "cpf") }} b using (cpf_particao)
    ),

    source_sms as (
        select b.*
        from all_cpf a
        inner join {{ source("rj-sms-historico-clinico", "paciente") }} b using (cpf_particao)
    ),

    -- CONTATO - TELEFONE
    telefone as (
        select
            cpf,
            null as ddi,
            telefone.ddd as ddd,
            telefone.valor as valor,
            telefone.rank,
            'sms' as origem,
            telefone.sistema
        from source_sms, unnest(contato.telefone) as telefone
        union all
        select
            cpf,
            contato.telefone.ddi as ddi,
            contato.telefone.ddd as ddd,
            contato.telefone.numero as valor,
            1 as rank,
            'receita_federal' as origem,
            'bcadastro' as sistema
        from source_bcadastro
        where contato.telefone.numero is not null
    ),

    telefone_corrigido as (
        select
            cpf,
            if(ddi is null and ddd is not null, '55', ddi) as ddi,
            {{ clean_numeric_string("ddd") }} as ddd,
            {{ clean_numeric_string("valor") }} as valor,
            rank,
            origem,
            sistema,
        from telefone
    ),

    telefone_ranqueado as (
        select
            *,
            case
                when origem = 'sms' then 1 when origem = 'receita_federal' then 2 else 3
            end as rank_origem
        from telefone_corrigido
    ),

    telefone_estruturado as (
        select
            cpf,
            array_agg(
                struct(origem, sistema, ddi, ddd, valor)
                order by rank_origem asc, rank asc
            ) as telefone
        from telefone_ranqueado
        group by cpf
    ),

    telefone_principal_alternativo as (
        select
            cpf,
            telefone[offset(0)] as principal,
            array(
                select as struct * except (pos)
                from unnest(telefone)
                with
                offset pos
                where pos > 0
            ) as alternativo
        from telefone_estruturado
    ),

    dim_telefone as (
        select
            cpf,
            struct(
                if(principal is not null, true, false) as indicador,
                principal,
                alternativo
            ) as telefone
        from all_cpf
        left join telefone_principal_alternativo using (cpf)
    )

select *
from dim_telefone
