{{
    config(
        enabled=false,
        alias="chamado_1746_mock_data",
        schema="crm_dados_mestres",
        materialized=("table" if target.name == "dev" or target.name == "staging" else "ephemeral")
    )
}}

with
    -- SOURCE
    source_pessoa_fisica as (
        select *
        from `rj-crm-registry-dev.crm_dados_mestres.pessoa_fisica_mock_data` -- TODO: voltar com esse {{ ref("mart_mocked_data_dim_pessoa_fisica") }}
    ),

    dim_chamado_1746 as (
        select * from {{ ref("int_pessoa_fisica_dim_chamado_1746") }}
    ),

    -- FINAL TABLE
    final as (
        select
            cpf,
            dim_chamado_1746.chamados_1746,
        from source_pessoa_fisica
        inner join dim_chamado_1746 using (cpf) --TODO: trocar pra left
    )

select *
from final
