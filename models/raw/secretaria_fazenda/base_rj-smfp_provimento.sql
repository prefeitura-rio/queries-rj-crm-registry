with source as (
        select * from {{ source('rj-smfp', 'provimento') }}
  ),
  renamed as (
      select
          {{ adapter.quote("id_funcionario") }},
        {{ adapter.quote("id_vinculo") }},
        {{ adapter.quote("data_inicio") }},
        {{ adapter.quote("data_fim") }},
        {{ adapter.quote("id_setor") }},
        {{ adapter.quote("id_cargo") }},
        {{ adapter.quote("id_referencia") }},
        {{ adapter.quote("id_jornada") }},
        {{ adapter.quote("forma") }},
        {{ adapter.quote("observacoes") }},
        {{ adapter.quote("regime_horas") }},
        {{ adapter.quote("empresa_vinculo") }},
        {{ adapter.quote("ponto_lei") }},
        {{ adapter.quote("ponto_publicacao") }},
        {{ adapter.quote("horario_trabalho") }},
        {{ adapter.quote("numero_vaga") }},
        {{ adapter.quote("flex_campo_04") }},
        {{ adapter.quote("flex_campo_05") }},
        {{ adapter.quote("flex_campo_20") }},
        {{ adapter.quote("updated_at") }}

      from source
  )
  select * from renamed
    