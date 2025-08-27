{{
    config(
        alias="dim_saude_temp",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

    select b.*
        from {{ source("rj-sms", "paciente") }} b 
        where cpf = "19076463700"
        and cpf_particao between 19076453700  and 19076473700
    

