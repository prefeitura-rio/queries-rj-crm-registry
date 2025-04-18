{{ config(alias="fluxos_ura") }}

with
    source as (select * from {{ source("rj-crm-registry", "fluxos_ura") }}),

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

    transformed as (
        select
            id_reply,
            protocol,
            channel,
            begin_date,
            end_date,
            ano_particao,
            mes_particao,
            data_particao,
            struct(id_ura as id, ura_name as nome) as ura,
            json_value(json_data, '$.observation') as observation,
            json_value(json_data, '$.origin') as origin,
            json_value(json_data, '$.description') as description,
            json_value(json_data, '$.finalizationUser') as finalization_user,
            json_value(json_data, '$.firstQueuingDate') as first_queuing_date,
            json_value(json_data, '$.operator') as operator,
            json_extract(json_data, '$.tags') as tags,
            struct(
                json_extract_scalar(
                    json_extract(json_data, '$.tabulation'), '$.name'
                ) as name,
                json_extract_scalar(
                    json_extract(json_data, '$.tabulation'), '$.id'
                ) as id
            ) as tabulation,
            json_extract_array(json_data, '$.transfers') as transfers,
            struct(
                json_extract_scalar(
                    json_extract(json_data, '$.contact'), '$.name'
                ) as name,
                json_extract_scalar(json_extract(json_data, '$.contact'), '$.id') as id
            ) as contact,
            (
                select
                    array_agg(  -- Re-aggregate the generated structs into an array
                        -- Define the STRUCT to be created for each JSON string
                        struct(
                            parse_timestamp(
                                '%Y-%m-%dT%H:%M:%E*S%Ez',
                                json_extract_scalar(json_str, '$.date')
                            ) as date,
                            json_query_array(json_str, '$.attachments') as attachments,
                            -- Extracts JSON array as ARRAY<STRING> of JSON values
                            json_extract_scalar(json_str, '$.hsm') as hsm,
                            safe_cast(
                                json_extract_scalar(json_str, '$.id') as int64
                            ) as id,
                            json_extract_scalar(json_str, '$.source') as source,
                            -- Nested struct for media. JSON_EXTRACT_SCALAR returns
                            -- NULL if 'media' is null or not an object,
                            -- which results in a STRUCT with all NULL fields,
                            -- effectively handling the null case.
                            struct(
                                json_extract_scalar(json_str, '$.media.file') as file,
                                json_extract_scalar(json_str, '$.media.name') as name,
                                json_extract_scalar(
                                    json_str, '$.media.contentType'
                                ) as contenttype
                            ) as media,
                            json_extract_scalar(json_str, '$.text') as text,
                            json_extract_scalar(json_str, '$.type') as type,
                            json_extract_scalar(json_str, '$.title') as title,
                            json_extract_scalar(json_str, '$.operator') as operator,
                            -- Nested struct for uraStep, handles NULLs implicitly
                            -- like 'media'.
                            struct(
                                json_extract_scalar(json_str, '$.uraStep.name') as name,
                                safe_cast(
                                    json_extract_scalar(
                                        json_str, '$.uraStep.id'
                                    ) as int64
                                ) as id
                            ) as urastep
                        )  -- End STRUCT definition
                        order by
                            parse_timestamp(
                                '%Y-%m-%dT%H:%M:%E*S%Ez',
                                json_extract_scalar(json_str, '$.date')
                            )  -- Optional: preserve order based on date
                    )
                from unnest(json_extract_array(json_data, '$.messages')) as json_str  -- Unnest the input array to process each string
            ) as messages,
            json_value(json_data, '$.id') as id,
            json_value(json_data, '$.sendToOperatorDate') as send_to_operator_date,
            json_value(json_data, '$.lastQueuingDate') as last_queuing_date,
            json_value(json_data, '$.queue') as queue
        from fix_json
    )

select *
from transformed
