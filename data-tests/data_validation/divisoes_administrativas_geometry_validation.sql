-- Test: Validate that geometries are valid and non-empty where present
-- Test Name: divisoes_administrativas_geometry_validation

{{ config(severity = 'error') }}

select
    id_divisao,
    tipo_divisao,
    nome,
    case
        when geometry is null then 'NULL_GEOMETRY'
        when st_area(geometry) = 0 then 'EMPTY_GEOMETRY'
        else 'VALID'
    end as geometry_status
from {{ ref('divisoes_administrativas') }}
where case
    when geometry is null then false  -- NULL geometries are allowed for some division types
    when st_area(geometry) = 0 and tipo_divisao in ('BAIRRO', 'AEIS', 'CRE', 'SUBPREFEITURA') then true  -- These should have area
    else false
end