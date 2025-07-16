-- Consolida informações de saúde de pessoa física a partir de múltiplas fontes do
-- município do Rio de Janeiro
-- Este modelo gera um struct de informações de saúde por CPF unificando dados do ergon
{{
    config(
        alias="dim_ergon",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
        tags=["daily"],
        partition_by={
            "field": "cpf_particao",
            "data_type": "int64",
            "range": {"start": 0, "end": 100000000000, "interval": 34722222},
        },
    )
}}

-- query inspirada em https://github.com/prefeitura-rio/queries-rj-smfp/blob/master/models/mart/ergon_saude/mart_ergon_saude_funcionarios.sql
with 

  all_cpf as (select cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}),

  funcionarios_ergon AS (
    SELECT
      lpad(id_cpf, 11, '0') as cpf, 
      id_vinculo as id_funcionario
    FROM {{ source("rj-smfp", "funcionario") }}
    where id_cpf is not null
  ),

  provimento AS (
    SELECT id_funcionario, id_vinculo, data_fim as provimento_fim
    FROM {{ source("rj-smfp", "provimento") }}
  ),

  vacancia_vinculo AS (
    SELECT id_funcionario, id_vinculo, data_vacancia
    FROM {{ source("rj-smfp", "vinculo") }}
  ),

  unifica AS (
    SELECT * ,
        if(f.cpf is not null, true, false) as indicador,
        case
          when (f.cpf is not null) and (p.provimento_fim is null) and (vv.data_vacancia is null)
          then true else false
        end as vinculo_ativo,
    FROM  all_cpf a
    LEFT JOIN funcionarios_ergon f USING(cpf)
    LEFT JOIN provimento p on f.id_funcionario = p.id_funcionario
    LEFT JOIN
              vacancia_vinculo vv
              on f.id_funcionario = vv.id_funcionario
              and p.id_vinculo = vv.id_vinculo
  ),

  dim_ergon AS (
    SELECT 
      DISTINCT cpf,
      struct(
          indicador,
          vinculo_ativo
      ) as trabalha_prefeitura,
      cast(cpf as int64) as cpf_particao
    FROM unifica
    WHERE cpf IS NOT NULL)

SELECT * FROM dim_ergon