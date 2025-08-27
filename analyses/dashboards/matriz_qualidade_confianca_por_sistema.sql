-- Descrição: A query abaixo gera uma matriz de qualidade e confiança para os telefones de pessoas físicas, agrupados por sistema de origem.
-- A matriz cruza a qualidade do telefone (VALIDO, SUSPEITO, INVALIDO) com a confiança da propriedade (MUITO_PROVAVEL, PROVAVEL, POUCO_PROVAVEL, IMPROVAVEL).
-- A contagem de CPFs distintos é calculada para cada combinação de qualidade, confiança e sistema, e a porcentagem em relação ao total de CPFs de cada sistema é apresentada.
-- Apenas telefones do tipo CELULAR são considerados.

with 
telefones as (
    select
        cpf,
        concat(ifnull(telefone.principal.ddi,""),ifnull(telefone.principal.ddd,""), ifnull(telefone.principal.valor,"")) as telefone,
        telefone.principal.qualidade as qualidade,
        telefone.principal.confianca as confianca,
        telefone.principal.sistema as sistema
    from `rj-crm-registry.rmi_dados_mestres.pessoa_fisica`
    where telefone.principal.tipo = 'CELULAR'
    union all
    select
        cpf,
        concat(ifnull(telefone.principal.ddi,""),ifnull(telefone.principal.ddd,""), ifnull(telefone.principal.valor,"")) as telefone,
        tel.qualidade as qualidade,
        tel.confianca as confianca,
        tel.sistema as sistema
    from `rj-crm-registry.rmi_dados_mestres.pessoa_fisica`,
  	unnest(telefone.alternativo) as tel
    where tel.tipo = 'CELULAR'
),
counts as (
    select
        sistema,
        case
            when qualidade='VALIDO' then '1 - VALIDO'
            when qualidade='SUSPEITO' then '2 - SUSPEITO'
            when qualidade='INVALIDO' then '3 - INVALIDO'
        end as telefone_qualidade,
        case
			when confianca = 'CONFIRMADA' then '1 - CONFIRMADA'
            when confianca = 'MUITO_PROVAVEL' then '2 - MUITO_PROVAVEL'
            when confianca = 'PROVAVEL' then '3 - PROVAVEL'
            when confianca = 'POUCO_PROVAVEL' then '4 - POUCO_PROVAVEL'
            when confianca = 'IMPROVAVEL' then '5 - IMPROVAVEL'
        end as confianca_propriedade,
        count(distinct cpf) as cpf_count,
        count(distinct telefone) as telefone_count
    from telefones
    where qualidade is not null and confianca is not null and sistema is not null
    group by 1, 2, 3
),
total as (
    select
        sistema,
        count(distinct cpf) as total_cpf,
        count(distinct telefone) as total_telefone
    from telefones
    where qualidade is not null and confianca is not null and sistema is not null
    group by 1
)
select
    counts.sistema,
    counts.telefone_qualidade,
    counts.confianca_propriedade,
    counts.cpf_count,
    counts.telefone_count,
    round(100*safe_divide(counts.cpf_count, total.total_cpf), 2) as cpf_percent,
    round(100*safe_divide(counts.telefone_count, total.total_telefone), 2) as telefone_percent
from counts
join total on counts.sistema = total.sistema
order by 1, 2, 3