{{ config(alias="fluxos_ura") }}

-- Model para extrair e transformar dados dos fluxos de URA do sistema Wetalkie
with

    source as (select * from {{ source("rj-crm-registry", "fluxos_ura") }}),

    -- Corrige valores no formato JSON para compatibilidade com BigQuery
    fix_json as (
        select
            * except (json_data),
            replace(
                replace(replace(json_data, 'None', 'null'), 'True', 'true'),
                'False',
                'false'
            ) as json_data
        from source
    ),

    -- Transformação dos dados extraídos do JSON
    transformed as (
        select
            -- Informações básicas do fluxo
            id_reply as id_resposta,
            protocol as protocolo,
            channel as canal,

            -- Datas de início e fim do fluxo
            date(
                parse_timestamp(
                    '%Y-%m-%dT%H:%M:%E*S%Ez', json_value(json_data, '$.beginDate')
                )
            ) as inicio_data,
            datetime(
                parse_timestamp(
                    '%Y-%m-%dT%H:%M:%E*S%Ez', json_value(json_data, '$.beginDate')
                )
            ) as inicio_datahora,
            datetime(
                parse_timestamp(
                    '%Y-%m-%dT%H:%M:%E*S%Ez', json_value(json_data, '$.endDate')
                )
            ) as fim_datahora,

            -- Identificadores do fluxo
            json_value(json_data, '$.id') as id,
            struct(id_ura as id, ura_name as nome) as ura,

            -- Metadados descritivos
            json_value(json_data, '$.observation') as observacao,
            json_value(json_data, '$.origin') as origem,
            json_value(json_data, '$.description') as descricao,

            -- Informações de operadores e usuários
            json_value(json_data, '$.operator') as operador,
            json_value(json_data, '$.finalizationUser') as usuario_finalizacao,

            -- Datas de enfileiramento e processamento
            json_value(json_data, '$.firstQueuingDate') as data_primeiro_enfileiramento,
            json_value(json_data, '$.sendToOperatorDate') as data_envio_operador,
            json_value(json_data, '$.lastQueuingDate') as data_ultimo_enfileiramento,

            -- Informações de fila e classificação
            json_value(json_data, '$.queue') as fila,
            json_extract(json_data, '$.tags') as tags,

            -- Estrutura de tabulação
            struct(
                json_extract_scalar(
                    json_extract(json_data, '$.tabulation'), '$.name'
                ) as nome,
                json_extract_scalar(
                    json_extract(json_data, '$.tabulation'), '$.id'
                ) as id
            ) as tabulacao,

            -- Informações de transferências
            json_extract_array(json_data, '$.transfers') as transferencias,

            -- Dados do contato
            struct(
                json_extract_scalar(
                    json_extract(json_data, '$.contact'), '$.name'
                ) as nome,
                json_extract_scalar(json_extract(json_data, '$.contact'), '$.id') as id
            ) as contato,

            -- Processamento das mensagens do fluxo
            (
                select
                    array_agg(
                        struct(
                            -- Dados temporais da mensagem
                            parse_timestamp(
                                '%Y-%m-%dT%H:%M:%E*S%Ez',
                                json_extract_scalar(json_str, '$.date')
                            ) as data,

                            -- Conteúdo e metadados da mensagem
                            json_query_array(json_str, '$.attachments') as anexos,
                            json_extract_scalar(json_str, '$.hsm') as hsm,
                            safe_cast(
                                json_extract_scalar(json_str, '$.id') as int64
                            ) as id,
                            json_extract_scalar(json_str, '$.source') as fonte,

                            -- Informações de mídia
                            struct(
                                json_extract_scalar(
                                    json_str, '$.media.file'
                                ) as arquivo,
                                json_extract_scalar(json_str, '$.media.name') as nome,
                                json_extract_scalar(
                                    json_str, '$.media.contentType'
                                ) as tipo_conteudo
                            ) as midia,

                            -- Conteúdo textual e classificação
                            json_extract_scalar(json_str, '$.text') as texto,
                            json_extract_scalar(json_str, '$.type') as tipo,
                            json_extract_scalar(json_str, '$.title') as titulo,
                            json_extract_scalar(json_str, '$.operator') as operador,

                            -- Informações do passo da URA
                            struct(
                                json_extract_scalar(json_str, '$.uraStep.name') as nome,
                                safe_cast(
                                    json_extract_scalar(
                                        json_str, '$.uraStep.id'
                                    ) as int64
                                ) as id
                            ) as passo_ura
                        )
                        order by
                            parse_timestamp(
                                '%Y-%m-%dT%H:%M:%E*S%Ez',
                                json_extract_scalar(json_str, '$.date')
                            )
                    )
                from unnest(json_extract_array(json_data, '$.messages')) as json_str
            ) as mensagens,

            -- Campos de particionamento
            ano_particao,
            mes_particao,
            cast(data_particao as date) as data_particao
        from fix_json
    )

-- Seleção final dos dados transformados
select *
from transformed
