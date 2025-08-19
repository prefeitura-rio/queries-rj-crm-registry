-- Descrição: A query abaixo gera uma matriz de qualidade e confiança para os telefones (principais e alternativos) de pessoas físicas.
-- A matriz cruza a qualidade do telefone (VALIDO, SUSPEITO, INVALIDO) com a confiança da propriedade (MUITO_PROVAVEL, PROVAVEL, POUCO_PROVAVEL, IMPROVAVEL).
-- A contagem de CPFs distintos é calculada para cada combinação de qualidade e confiança, e a porcentagem em relação ao total de CPFs é apresentada para cada hierarquia (principal, alternativo, todos).
-- Apenas telefones do tipo CELULAR são considerados.

with telefones as (
    select
        cpf,
        telefone.principal.qualidade as qualidade,
        telefone.principal.confianca as confianca,
        'principal' as hierarquia
    from `rj-crm-registry-dev.patricia__rmi_dados_mestres.pessoa_fisica`
    where telefone.principal.tipo = 'CELULAR'
    union all
    select
        cpf,
        tel.qualidade as qualidade,
        tel.confianca as confianca,
        'alternativo' as hierarquia
    from `rj-crm-registry-dev.patricia__rmi_dados_mestres.pessoa_fisica`, 
    unnest(telefone.alternativo) as tel
    where tel.tipo = 'CELULAR'
),
all_telefones as (
    select 
        distinct cpf,
        qualidade,
        confianca,
        'todos' as hierarquia 
    from telefones
),
unioned as (
    select * from telefones
    union all
    select * from all_telefones
),
counts as (
    select
        case
            when qualidade='VALIDO' then '1 - VALIDO'
            when qualidade='SUSPEITO' then '2 - SUSPEITO'
            when qualidade='INVALIDO' then '3 - INVALIDO'
        end as telefone_qualidade,
        case
            when confianca = 'MUITO_PROVAVEL' then '1 - MUITO_PROVAVEL'
            when confianca = 'PROVAVEL' then '2 - PROVAVEL'
            when confianca = 'POUCO_PROVAVEL' then '3 - POUCO_PROVAVEL'
            when confianca = 'IMPROVAVEL' then '4 - IMPROVAVEL'
        end as confianca_propriedade,
        hierarquia,
        count(distinct cpf) as cpf_count
    from unioned
    where qualidade is not null and confianca is not null
    group by 1, 2, 3
),
total as (
    select
        hierarquia,
        count(distinct cpf) as total_cpf
    from unioned
    where qualidade is not null and confianca is not null
    group by 1
)
select
    counts.telefone_qualidade,
    counts.confianca_propriedade,
    counts.hierarquia,
    counts.cpf_count,
    round(100*safe_divide(counts.cpf_count, total.total_cpf), 2) as cpf_percent
from counts
join total on counts.hierarquia = total.hierarquia
order by 3, 1, 2