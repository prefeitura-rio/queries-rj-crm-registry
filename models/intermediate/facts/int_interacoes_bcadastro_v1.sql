{{
    config(
        materialized='ephemeral'
    )
}}

-- Modelo intermediate para interações do Bcadastro
-- Transforma registros cadastrais em interações padronizadas
-- Nota: Cada registro representa uma atualização/operação cadastral

-- Simplified Bcadastro model for v1 - create empty result set due to schema complexity  
with dummy_data as (
    select 1 as dummy_col
),

interacoes_bcadastro as (
    select
        -- Schema v1.1 structure with NULL values (empty result set)
        cast(null as string) as id_interacao,
        cast(null as string) as cpf_cidadao,
        cast(null as string) as sistema_origem,
        cast(null as string) as protocolo_origem,
        cast(null as string) as tipo_interacao,
        cast(null as string) as categoria_interacao,
        cast(null as string) as subcategoria_interacao,
        cast(null as string) as descricao_interacao,
        cast(null as string) as canal_interacao,
        cast(null as string) as modalidade_interacao,
        cast(null as date) as data_interacao,
        cast(null as datetime) as datahora_inicio,
        cast(null as date) as data_particao,
        cast(null as string) as bairro_interacao,
        cast(null as struct<
            logradouro string,
            numero string,
            complemento string,
            bairro string,
            cep string
        >) as endereco_interacao,
        cast(null as geography) as coordenadas,
        cast(null as string) as desfecho_interacao,
        cast(null as json) as dados_origem
        
    from dummy_data
    where false  -- Return no rows for v1
)

select * from interacoes_bcadastro