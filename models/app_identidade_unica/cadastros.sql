DECLARE cpf_filter STRING DEFAULT '';

with
    sms as (
        select
            cpf,
            array_agg(
                struct(
                    registration_name,
                    social_name,
                    cns,
                    birth_date,
                    gender,
                    race,
                    deceased,
                    phone,
                    family_clinic,
                    family_health_team,
                    medical_responsible,
                    nursing_responsible,
                    validated,
                    exibicao
                )
            ) as saude
        from `rj-sms.app_historico_clinico.paciente`
        where cpf = cpf_filter
        group by cpf
    ),

    sms_ep as (
        select
            cpf,
            array_agg(
                struct(
                    id_hci,
                    entry_datetime,
                    exit_datetime,
                    location,
                    type,
                    subtype,
                    exhibition_type,
                    clinical_exams,
                    procedures,
                    measures,
                    prescription,
                    medicines_administered,
                    cids,
                    cids_summarized,
                    responsible,
                    clinical_motivation,
                    clinical_outcome,
                    deceased,
                    provider,
                    filter_tags,
                    exibicao
                )
            ) as saude_episodio
        from `rj-sms.app_historico_clinico.episodio_assistencial`
        where cpf = cpf_filter
        group by cpf
    ),

    smas as (
        select
            cpf,
            array_agg(
                struct(
                    id_membro_familia,
                    id_familia,
                    data_particao,
                    dados,
                    deficiencia,
                    escolaridade,
                    renda,
                    domicilio,
                    membros
                )
            ) as cadunico
        from `rj-smas.app_identidade_unica.cadastros`
        where cpf = cpf_filter
        group by cpf

    ),

    segovi as (
        select
            cpf,
            array_agg(
                struct(
                    origem_ocorrencia,
                    id_chamado,
                    data_inicio,
                    data_fim,
                    categoria,
                    tipo,
                    subtipo,
                    status,
                    latitude,
                    longitude,
                    tempo_prazo,
                    prazo_unidade,
                    data_alvo_finalizacao,
                    situacao,
                    reclamacoes
                )
            ) as chamados
        from `rj-segovi.app_identidade_unica.1746_chamado_cpf`
        where cpf = cpf_filter
        group by cpf

    ),

    smtr as (
        select
            cpf_cliente as cpf,
            array_agg(
                struct(
                    data,
                    hora,
                    datetime_transacao,
                    modo,
                    consorcio,
                    operadora,
                    servico_jae,
                    sentido,
                    id_veiculo,
                    tipo_pagamento,
                    tipo_transacao,
                    latitude,
                    longitude
                )
            ) as transporte
        from `rj-smtr-dev.projeto_cadastro_unico.transacao_cpf`
        where cpf_cliente = cpf_filter
        group by cpf_cliente

    ),

    b_cadastro as (
        select
            cpf_id as cpf,
            array_agg(
                struct(
                    nome,
                    nome_mae,
                    nome_municipio_domicilio,
                    nome_municipio_nascimento,
                    descricao_ocupacao,
                    sexo,
                    situacao_cadastral,
                    complemento,
                    data_inscricao,
                    data_nascimento,
                    data_ultima_atualizacao,
                    estrangeiro,
                    residente_exterior,
                    cep,
                    bairro,
                    logradouro,
                    numero_logradouro,
                    telefone,
                    tipo_logradouro,
                    uf_municipio_domicilio,
                    uf_municipio_nascimento

                )
            ) as bcadastro
        from `rj-crm-registry.brutos_bcadastro.cpf`
        where nome_municipio_domicilio = 'Rio de Janeiro' and cpf_id = cpf_filter
        group by cpf_id

    ),

    all_cpfs as (
        select cpf, origens
        from `rj-crm-registry.app_identidade_unica.cpf`
        where cpf = cpf_filter
    )

select
    a.cpf,
    a.origens,
    b.bcadastro,
    s.saude,
    c.cadunico,
    ep.saude_episodio,
    t.transporte,
    ch.chamados
from all_cpfs a
left join b_cadastro b on a.cpf = b.cpf
left join sms s on a.cpf = s.cpf
left join sms_ep ep on a.cpf = ep.cpf
left join smas c on a.cpf = c.cpf
left join smtr t on a.cpf = t.cpf
left join segovi ch on a.cpf = ch.cpf
