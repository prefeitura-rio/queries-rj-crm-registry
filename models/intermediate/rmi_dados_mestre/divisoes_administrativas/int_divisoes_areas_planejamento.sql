{{ config(
    alias="interacoes_pessoa_fisica_areas_planejamento",
    schema="intermediario_dados_mestres",
    materialized=("table" if target.name == "dev" else "ephemeral")
) }}

-- Áreas de Planejamento derivadas dos dados de bairro

with areas_planejamento as (
    select distinct
        id_area_planejamento,
        first_value(nome_regiao_planejamento) over (
            partition by id_area_planejamento 
            order by nome_regiao_planejamento
        ) as primeira_regiao
    from {{ ref('raw_dados_mestres_bairro') }}
)

select
    concat('ap_', id_area_planejamento) as id_divisao,
    'AREA_PLANEJAMENTO' as tipo_divisao,
    cast(id_area_planejamento as string) as codigo_original,
    concat('AP', id_area_planejamento) as nome,
    concat('AP', id_area_planejamento) as nome_abreviado,
    'IPP' as orgao_responsavel,
    cast(['planejamento_territorial'] as array<string>) as competencias,
    cast(null as date) as data_criacao,
    'Plano Diretor Municipal' as legislacao_base,
    cast(null as float64) as area_m2, -- Será calculado posteriormente via agregação
    cast(null as float64) as perimetro_m,
    cast(null as float64) as centroide_latitude,
    cast(null as float64) as centroide_longitude,
    cast(null as geography) as geometry, -- Será calculado posteriormente via união de geometrias
    cast(null as string) as geometry_wkt,
    cast(null as float64) as densidade_populacional,
    'misto' as uso_solo_predominante,
    cast([] as array<string>) as restricoes_urbanisticas,
    cast(['planejamento_urbano'] as array<string>) as instrumentos_urbanisticos,
    to_json(struct(
        cast(null as string) as caracteristicas_socioeconomicas,
        cast([] as array<string>) as diretrizes_planejamento
    )) as atributos_especificos,
    to_json(struct(
        'bairro_derived' as tabela_origem
    )) as metadados_fonte,
    true as ativo,
    current_timestamp() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.bairro' as fonte_dados,
    '1.0' as versao_schema
from areas_planejamento