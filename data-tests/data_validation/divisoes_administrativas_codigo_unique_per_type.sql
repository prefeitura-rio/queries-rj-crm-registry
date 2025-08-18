-- Test: Validate that codigo_original is unique within each tipo_divisao
-- Test Name: divisoes_administrativas_codigo_unique_per_type

{{ config(severity = 'warn') }}

select
    tipo_divisao,
    codigo_original,
    count(*) as duplicata_count
from {{ ref('divisoes_administrativas') }}
where codigo_original is not null
group by tipo_divisao, codigo_original
having count(*) > 1