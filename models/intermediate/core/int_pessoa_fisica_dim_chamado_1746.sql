-- Consolida informações dos chamados do 1746
-- TODO: remover filtro de CPF e troca forçada de valores de CPFS
{{
    config(
        alias="dim_chamado_1746",
        schema="intermediario_dados_mestres",
        materialized=("table" if target.name == "dev" else "ephemeral"),
    )
}}

WITH 
-- sources
    all_cpf as (
        select
            cpf, cpf_particao from {{ ref("int_pessoa_fisica_all_cpf") }}
            WHERE cpf IN (
                "01075971799", "01077893701", "01149879718", "01181001730", "02105846700",
                "02111521370", "07933758789", "08671182703", "14027136730", "11278791701",
                "15188333732"
            ) -- TODO: remover where
    ),

    source_1746 as (
        select DISTINCT b.*
        from all_cpf a
        inner join {{ ref("raw_crm_eventos__governo_integridade_1746_chamado") }} b using (cpf)
        WHERE b.cpf IN (
                "01075971799", "01077893701", "01149879718", "01181001730", "02105846700",
                "02111521370", "07933758789", "08671182703", "14027136730", "11278791701",
                "15188333732"
            ) -- TODO: remover where
    ),

--    source_1746 as (
--         select DISTINCT b.*
--         from `rj-crm-registry.crm_eventos.governo_integridade__1746_chamado` b
--         where b.cpf in (select DISTINCT cpf from all_cpf)
--         ),

    dados_chamado_1746 AS (
        SELECT
            DISTINCT
            CASE
            WHEN cpf = "01075971799" THEN "07304210907"
            -- WHEN cpf = "01077893701" THEN "02801159204"
            WHEN cpf = "01077893701" THEN "47562396507"
            WHEN cpf = "01149879718" THEN "04913579231"
            WHEN cpf = "01181001730" THEN "00576201219"
            WHEN cpf = "02105846700" THEN "00852909128"
            WHEN cpf = "02111521370" THEN "06315524648"
            WHEN cpf = "07933758789" THEN "05343533043"
            WHEN cpf = "08671182703" THEN "07964110004"
            WHEN cpf = "14027136730" THEN "04675615830"
            WHEN cpf = "11278791701" THEN "06119211977"
            WHEN cpf = "15188333732" THEN "00813146046"
            END AS cpf, -- TODO: deixar só cpf
            ch.id_chamado,
            ch.origem_ocorrencia,
            ch.id_origem_ocorrencia,
            CAST(ch.data_inicio AS TIMESTAMP) AS data_inicio,
            CAST(ch.data_fim AS TIMESTAMP) AS data_fim,
            ch.id_bairro,
            ch.id_territorialidade,
            ch.id_logradouro,
            ch.numero_logradouro,
            ch.id_unidade_organizacional,
            ch.nome_unidade_organizacional,
            ch.id_unidade_organizacional_mae,
            ch.unidade_organizacional_ouvidoria,
            ch.categoria,
            ch.id_tipo,
            ch.tipo,
            ch.id_subtipo,
            ch.subtipo,
            CASE
                WHEN LOWER(status) LIKE ("%fechado%") THEN "Concluido"
                WHEN status in ("Pendente") OR LOWER(status) LIKE ("%andamento%") OR LOWER(status) LIKE ("%encaminhado%") THEN "Aberto"
                WHEN LOWER(status) IN ("cancelado", "fechado sem solução", "recusado", "sem possibilidade de atendimento", "não constatado") THEN "Não resolvido"
                ELSE status 
            END AS status,
            ch.longitude,
            ch.latitude,
            CAST(ch.data_alvo_finalizacao AS TIMESTAMP) AS data_alvo_finalizacao,
            CAST(ch.data_alvo_diagnostico AS TIMESTAMP) AS data_alvo_diagnostico,
            CAST(ch.data_real_diagnostico AS TIMESTAMP) AS data_real_diagnostico,
            ch.tempo_prazo,
            ch.prazo_unidade,
            ch.prazo_tipo,
            ch.dentro_prazo,
            ch.situacao,
            ch.tipo_situacao,
            ch.justificativa_status,
            ch.reclamacoes,
            ch.descricao,
            logr.nome_completo AS logradouro,
            bairro.nome AS bairro,
            CASE WHEN logr.id_logradouro IS NOT NULL THEN "Rio de Janeiro" ELSE NULL END AS cidade,
        FROM 
            source_1746 ch
        LEFT JOIN `rj-escritorio-dev.dados_mestres.logradouro` logr USING(id_logradouro)
        LEFT JOIN `rj-escritorio-dev.dados_mestres.bairro` bairro ON ch.id_bairro = bairro.id_bairro
    ),

    estatisticas_ AS (
        SELECT
            cpf,
            COUNT(DISTINCT id_chamado) AS total_chamados,
            COUNT(DISTINCT CASE WHEN LOWER(status) LIKE ("%fechado%") THEN id_chamado END) AS total_fechados
        FROM dados_chamado_1746
        GROUP BY cpf
    ),

    dim_chamado_1746 AS (
        SELECT
            dc.cpf,
            STRUCT(
                STRUCT(
                    if(
                        dc.id_chamado is not null, true, false
                    ) as indicador,
                    dc.id_chamado,
                    dc.origem_ocorrencia,
                    dc.id_origem_ocorrencia,
                    dc.id_unidade_organizacional,
                    dc.nome_unidade_organizacional,
                    dc.id_unidade_organizacional_mae,
                    dc.unidade_organizacional_ouvidoria,
                    dc.categoria,
                    dc.id_tipo,
                    dc.tipo,
                    dc.id_subtipo,
                    dc.subtipo,
                    dc.reclamacoes,
                    dc.descricao
                ) AS chamado,
                STRUCT(
                    dc.data_inicio,
                    dc.data_fim,
                    dc.data_alvo_finalizacao,
                    dc.data_alvo_diagnostico,
                    dc.data_real_diagnostico
                ) AS data,
                STRUCT(    
                    dc.id_bairro,
                    dc.id_territorialidade,
                    dc.id_logradouro,
                    dc.numero_logradouro,
                    dc.longitude,
                    dc.latitude
                ) AS localidade,
                STRUCT(            
                    dc.tempo_prazo,
                    dc.prazo_unidade,
                    dc.prazo_tipo,
                    dc.dentro_prazo
                ) AS prazo,
                STRUCT(
                    dc.situacao,
                    dc.tipo_situacao,
                    dc.justificativa_status,
                    dc.status
                ) AS status,
                STRUCT(
                    est.total_chamados,
                    est.total_fechados
                ) AS estatisticas
            ) AS chamados_1746
        FROM dados_chamado_1746 AS dc 
        LEFT JOIN estatisticas_ est ON est.cpf = dc.cpf
    )

SELECT *
FROM dim_chamado_1746
ORDER BY cpf
