-- Descrição: A query abaixo gera uma matriz de qualidade e confiança para os telefones (principais e alternativos) de pessoas físicas.
-- A matriz cruza a qualidade do telefone (VALIDO, SUSPEITO, INVALIDO) com a confiança da propriedade (MUITO_PROVAVEL, PROVAVEL, POUCO_PROVAVEL, IMPROVAVEL).
-- A contagem de CPFs distintos é calculada para cada combinação de qualidade e confiança, e a porcentagem em relação ao total de CPFs é apresentada para cada hierarquia (principal, alternativo, todos).
-- Apenas telefones do tipo CELULAR são considerados.

with 
version as (
  select distinct telefone_numero, telefone_ddd, telefone_ddi, rmi_versao from `rj-iplanrio-dev.snapshots.int_telefone`
  where rmi_versao = "v1.1"
  union all
  select distinct telefone_numero, telefone_ddd, telefone_ddi, rmi_versao from `rj-crm-registry.snapshots.int_telefone`
  ),
telefones as (
    select
        cpf,
        concat(ifnull(telefone.principal.ddi,""),ifnull(telefone.principal.ddd,""), ifnull(telefone.principal.valor,"")) as telefone,
        telefone.principal.qualidade as qualidade,
        telefone.principal.confianca as confianca,
        'principal' as hierarquia,
        rmi_versao
    from `rj-crm-registry.rmi_dados_mestres.pessoa_fisica` pf
    -- from `rj-iplanrio-dev.dev_fantasma__rmi_dados_mestres.pessoa_fisica` pf
    left join version 
    on version.telefone_numero = pf.telefone.principal.valor and
      version.telefone_ddd = pf.telefone.principal.ddd and
      version.telefone_ddi = pf.telefone.principal.ddi
    where telefone.principal.tipo = 'CELULAR'
    union all
    select
        cpf,
        concat(ifnull(telefone.principal.ddi,""),ifnull(telefone.principal.ddd,""), ifnull(telefone.principal.valor,"")) as telefone,
        tel.qualidade as qualidade,
        tel.confianca as confianca,
        'alternativo' as hierarquia,
        rmi_versao
    from `rj-crm-registry.rmi_dados_mestres.pessoa_fisica`,
    -- from `rj-iplanrio-dev.dev_fantasma__rmi_dados_mestres.pessoa_fisica` pf,
    unnest(telefone.alternativo) as tel
    left join version 
    on version.telefone_numero = tel.valor and
      version.telefone_ddd = tel.ddd and
      version.telefone_ddi = tel.ddi
    where tel.tipo = 'CELULAR'
),
all_telefones as (
    select 
        distinct cpf,
        telefone,
        qualidade,
        confianca,
        'todos' as hierarquia ,
        rmi_versao
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
			when confianca = 'CONFIRMADA' then '1 - CONFIRMADA'
            when confianca = 'MUITO_PROVAVEL' then '2 - MUITO_PROVAVEL'
            when confianca = 'PROVAVEL' then '3 - PROVAVEL'
            when confianca = 'POUCO_PROVAVEL' then '4 - POUCO_PROVAVEL'
            when confianca = 'IMPROVAVEL' then '5 - IMPROVAVEL'
        end as confianca_propriedade,
        hierarquia,
        rmi_versao,
        count(distinct cpf) as cpf_count,
        count(distinct telefone) as telefone_count
    from unioned
    where qualidade is not null and confianca is not null
    group by 1, 2, 3, 4
),
total as (
    select
        hierarquia,
        rmi_versao,
        count(distinct cpf) as total_cpf,
        count(distinct telefone) as total_telefone
    from unioned
    where qualidade is not null and confianca is not null
    group by 1,2 
),
last_version_ as (select max(rmi_versao) as last_version from total),
count_totals as (
select
    distinct
    counts.telefone_qualidade,
    counts.confianca_propriedade,
    counts.hierarquia,
    counts.cpf_count,
    counts.telefone_count,
    total.total_cpf,
    total.total_telefone,
    counts.rmi_versao,
    -- total.hierarquia as hierarquia_total,
    -- total.rmi_versao as rmi_versao_total,
    round(100*safe_divide(counts.cpf_count, total.total_cpf), 1) as cpf_percent,
    round(100*safe_divide(counts.telefone_count, total.total_telefone), 1) as telefone_percent
from counts
join total on counts.hierarquia = total.hierarquia and counts.rmi_versao = total.rmi_versao
order by 3, 1, 2, 5)

select * , 
dense_rank() over (order by case when rmi_versao is null or rmi_versao = "todos" then "a" else rmi_versao end desc) as rank_version,
from count_totals
cross join last_version_
order by hierarquia, confianca_propriedade, telefone_qualidade, rmi_versao
