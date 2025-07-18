{{
    config(
        enabled=false,
        alias="pessoa_fisica_mock_data",
        schema="crm_dados_mestres",
        materialized=("table" if target.name == "dev" or target.name == "staging" else "ephemeral")
    )
}}

with
    -- SOURCE
    all_prefeitura as (
        select distinct cpf from {{ ref("int_pessoa_fisica_all_cpf") }}
    ),

    source_bcadastro as (
        select *
        from (select * from {{ source("bcadastro", "cpf") }})
        inner join all_prefeitura using (cpf)
    ),

    source_saude as (
        select *
        from {{ source("rj-sms-historico-clinico", "paciente") }}
        inner join all_prefeitura using (cpf)
    ),

    source_cadunico as (
        select cpf, dados[offset(0)] as dados  -- #TODO: corrigir no cadunico para retornar um array de dados
        from {{ source("rj-smas", "cadastros") }}
        inner join all_prefeitura using (cpf)
    ),

    -- DIMENSIONS
    dim_documentos as (
        select all_prefeitura.cpf, struct(source_saude.cns) as documentos,
        from all_prefeitura
        left join source_saude using (cpf)
    ),
    
    dim_nascimento as (
        select
            cpf,
            struct(
                nascimento_data as data,
                nascimento_local.id_municipio as municipio_id,
                nascimento_local.municipio as municipio,
                upper(nascimento_local.uf) as uf,
                if(
                    nascimento_local.id_pais is not null,
                    nascimento_local.id_pais,
                    '105'
                ) as pais_id,
                if(
                    nascimento_local.id_pais is not null,
                    {{ proper_br("nascimento_local.pais") }},
                    'Brasil'
                ) as pais
            ) as nascimento
        from source_bcadastro
    ),

    dim_mae as (
        select cpf, struct({{ proper_br("mae_nome") }} as nome, cast(null as string) as cpf) as mae
        from source_bcadastro
    ),

    dim_endereco as (
        select * from {{ ref("int_pessoa_fisica_dim_endereco") }}
    ),

    dim_email as (
        select * from {{ ref("int_pessoa_fisica_dim_email") }}
    ),

    dim_telefone as (
        select * from {{ ref("int_pessoa_fisica_dim_telefone") }}
    ),

    dim_assistencia_social as (
        select * from {{ ref("int_pessoa_fisica_dim_assistencia_social") }}
    ),

    dim_educacao as (
        select * from {{ ref("int_pessoa_fisica_dim_educacao") }}
    ),

    dim_saude as (
        select * from {{ ref("int_pessoa_fisica_dim_saude") }}
    ),

    cpf_base as (
      select
        cpf,
        lpad(cast(MOD(abs(farm_fingerprint(cast(cpf as string))), 1000000000) as string), 9, '0') as base
      from all_prefeitura
    ),
    cpf_check1 as (
      select
        cpf,
        base,
        case when mod(
          cast(substr(base, 1, 1) as int64) * 10 +
          cast(substr(base, 2, 1) as int64) * 9 +
          cast(substr(base, 3, 1) as int64) * 8 +
          cast(substr(base, 4, 1) as int64) * 7 +
          cast(substr(base, 5, 1) as int64) * 6 +
          cast(substr(base, 6, 1) as int64) * 5 +
          cast(substr(base, 7, 1) as int64) * 4 +
          cast(substr(base, 8, 1) as int64) * 3 +
          cast(substr(base, 9, 1) as int64) * 2, 11
        ) < 2 then 0 else 11 - mod(
          cast(substr(base, 1, 1) as int64) * 10 +
          cast(substr(base, 2, 1) as int64) * 9 +
          cast(substr(base, 3, 1) as int64) * 8 +
          cast(substr(base, 4, 1) as int64) * 7 +
          cast(substr(base, 5, 1) as int64) * 6 +
          cast(substr(base, 6, 1) as int64) * 5 +
          cast(substr(base, 7, 1) as int64) * 4 +
          cast(substr(base, 8, 1) as int64) * 3 +
          cast(substr(base, 9, 1) as int64) * 2, 11
        ) end as c1
      from cpf_base
    ),
    cpf_ready as (
      select
        cpf,
        concat(
          base,
          cast(c1 as string),
          cast(
            case when mod(
              cast(substr(base, 1, 1) as int64) * 11 +
              cast(substr(base, 2, 1) as int64) * 10 +
              cast(substr(base, 3, 1) as int64) * 9 +
              cast(substr(base, 4, 1) as int64) * 8 +
              cast(substr(base, 5, 1) as int64) * 7 +
              cast(substr(base, 6, 1) as int64) * 6 +
              cast(substr(base, 7, 1) as int64) * 5 +
              cast(substr(base, 8, 1) as int64) * 4 +
              cast(substr(base, 9, 1) as int64) * 3 +
              c1 * 2, 11
            ) < 2 then 0 else 11 - mod(
              cast(substr(base, 1, 1) as int64) * 11 +
              cast(substr(base, 2, 1) as int64) * 10 +
              cast(substr(base, 3, 1) as int64) * 9 +
              cast(substr(base, 4, 1) as int64) * 8 +
              cast(substr(base, 5, 1) as int64) * 7 +
              cast(substr(base, 6, 1) as int64) * 6 +
              cast(substr(base, 7, 1) as int64) * 5 +
              cast(substr(base, 8, 1) as int64) * 4 +
              cast(substr(base, 9, 1) as int64) * 3 +
              c1 * 2, 11
            ) end as string
          )
        ) as cpf_random
      from cpf_check1
    ),

    -- FINAL TABLE
    final as (
        select
            -- cpf_ready.cpf_random as cpf,
            CASE
            WHEN cpf = "01077893701" THEN "47562396507"
            ELSE cpf
            END AS cpf,
            -- Identificação
            concat('NOME_', abs(farm_fingerprint(cast(cpf as string)))) as nome,
            concat('NOME_SOCIAL_', abs(farm_fingerprint(cast(cpf as string)))) as nome_social,
            bcadastro.sexo,
            struct(
                -- nascimento.data: random date between 1950-01-01 and 2010-12-31
                date_add(date '1950-01-01', interval mod(abs(farm_fingerprint(cast(cpf as string))), 22280) day) as data,
                concat('MUN_', mod(abs(farm_fingerprint(cast(cpf as string))), 10000)) as municipio_id,
                concat('MUNICIPIO_', mod(abs(farm_fingerprint(cast(cpf as string))), 10000)) as municipio,
                'RJ' as uf,
                '105' as pais_id,
                'Brasil' as pais
            ) as nascimento,
            -- Parentesco
            struct(concat('MAE_', abs(farm_fingerprint(cast(cpf as string)))) as nome, cast(null as string) as cpf) as mae,
            -- Outras características
            (date_diff(current_date(), date_add(date '1950-01-01', interval mod(abs(farm_fingerprint(cast(cpf as string))), 22280) day), year) < 18) as menor_idade,
            'RACA_' || mod(abs(farm_fingerprint(cast(cpf as string))), 10) as raca,
            struct(
                false as indicador,
                null as ano
            ) as obito,
            struct([concat('CNS', abs(farm_fingerprint(cast(cpf as string))))] as cns) as documentos,
            struct(
                true as indicador,
                struct(
                    'FAKE_ORIGEM' as origem,
                    'FAKE_SISTEMA' as sistema,
                    lpad(cast(mod(abs(farm_fingerprint(cast(cpf as string))), 100000000) as string), 8, '0') as cep,
                    'RJ' as estado,
                    concat('MUNICIPIO_', mod(abs(farm_fingerprint(cast(cpf as string))), 10000)) as municipio,
                    'RUA' as tipo_logradouro,
                    concat('LOGRADOURO_', mod(abs(farm_fingerprint(cast(cpf as string))), 10000)) as logradouro,
                    lpad(cast(mod(abs(farm_fingerprint(cast(cpf as string))), 10000) as string), 4, '0') as numero,
                    'COMPLEMENTO' as complemento,
                    'BAIRRO' as bairro
                ) as principal,
                [] as alternativo
            ) as endereco,
            struct(
                true as indicador,
                struct('FAKE_ORIGEM' as origem, 'FAKE_SISTEMA' as sistema, concat('user_', abs(farm_fingerprint(cast(cpf as string))), '@example.com') as valor) as principal,
                [] as alternativo
            ) as email,
            struct(
                true as indicador,
                struct('FAKE_ORIGEM' as origem, 'FAKE_SISTEMA' as sistema, '55' as ddi, '21' as ddd, lpad(cast(mod(abs(farm_fingerprint(cast(cpf as string))), 100000000) as string), 8, '0') as valor) as principal,
                [] as alternativo
            ) as telefone,
            -- Órgão da prefeitura
            dim_assistencia_social.assistencia_social,
            dim_educacao.educacao,
            dim_saude.saude,
            struct(current_timestamp() as last_updated) as datalake,
            cast(cpf as int64) as cpf_particao
        from all_prefeitura
        inner join source_bcadastro as bcadastro using (cpf)
        left join dim_assistencia_social using (cpf)
        left join dim_educacao using (cpf)
        left join dim_documentos using (cpf)
        left join dim_email using (cpf)
        left join dim_endereco using (cpf)
        left join dim_mae using (cpf)
        left join dim_nascimento using (cpf)
        left join dim_saude using (cpf)
        left join dim_telefone using (cpf)
        left join source_saude as saude using (cpf)
        left join source_cadunico as cadunico using (cpf)
        left join cpf_ready using (cpf)
    ),

    deduplicated as (
        select
            *,
            row_number() over (partition by cpf order by cpf) as row_number
        from final
        qualify row_number = 1
    )

select *
from deduplicated
where cpf not in (
  '00000000000', '11111111111', '22222222222', '33333333333', '44444444444',
  '55555555555', '66666666666', '77777777777', '88888888888', '99999999999'
) 
