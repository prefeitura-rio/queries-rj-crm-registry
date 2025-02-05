DECLARE cpf_filter1 INT64 DEFAULT 17752723703;
DECLARE cpf_filter2 INT64 DEFAULT 20129248754;
DECLARE cpf_filter3 INT64 DEFAULT 15706658773;

with
    sms as (
        select
            cpf,
            dados,
            endereco,
            contato,
            struct(
                cadastros_conflitantes_indicador,
                cns,
                equipe_saude_familia,
                prontuario,
                metadados
            ) as saude
        from `rj-sms.saude_historico_clinico.paciente`
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
    ),

    sms_ep as (
        select
            cpf,
            struct(
                id_hci,
                entry_datetime,
                exit_datetime,
                location,
                type,
                subtype,
                exhibition_type,
                procedures,
                prescription,
                cids_summarized,
                clinical_motivation,
                clinical_outcome,
                deceased,
                filter_tags,
                provider,
                clinical_exams,
                measures,
                medicines_administered,
                cids,
                responsible,
                exibicao,
                exibicao
            ) as saude_episodio
        from `rj-sms.app_historico_clinico.episodio_assistencial`
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
    ),

    smas as (
        select
            cpf,
            dados,
            struct(
                id_membro_familia,
                id_familia,
                data_particao,
                deficiencia,
                escolaridade,
                renda,
                domicilio,
                membros
            ) as cadunico
        from `rj-smas.app_identidade_unica.cadastros`
        left join unnest(dados) as dados
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)

    ),

    segovi as (
        select
            cpf,
            array_agg(
                struct(
                    origem_ocorrencia,
                    id_chamado,
                    id_origem_ocorrencia,
                    data_inicio,
                    data_fim,
                    id_bairro,
                    id_territorialidade,
                    id_logradouro,
                    numero_logradouro,
                    id_unidade_organizacional,
                    nome_unidade_organizacional,
                    id_unidade_organizacional_mae,
                    unidade_organizacional_ouvidoria,
                    categoria,
                    id_tipo,
                    tipo,
                    id_subtipo,
                    subtipo,
                    status,
                    longitude,
                    latitude,
                    data_alvo_finalizacao,
                    data_alvo_diagnostico,
                    data_real_diagnostico,
                    tempo_prazo,
                    prazo_unidade,
                    prazo_tipo,
                    dentro_prazo,
                    situacao,
                    tipo_situacao,
                    justificativa_status,
                    reclamacoes,
                    descricao,
                    data_particao
                )
            ) as chamados
        from `rj-segovi.app_identidade_unica.1746_chamado_cpf`
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
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
                    datetime_processamento,
                    datetime_captura,
                    modo,
                    id_consorcio,
                    consorcio,
                    id_operadora,
                    operadora,
                    id_servico_jae,
                    servico_jae,
                    descricao_servico_jae,
                    sentido,
                    id_veiculo,
                    id_validador,
                    id_transacao,
                    tipo_pagamento,
                    tipo_transacao,
                    tipo_transacao_smtr,
                    tipo_gratuidade,
                    latitude,
                    longitude,
                    geo_point_transacao,
                    valor_transacao,
                    versao,
                    datetime_ultima_atualizacao
                )
            ) as transporte
        from `rj-smtr-dev.projeto_cadastro_unico.transacao_cpf`
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
        group by cpf_cliente

    ),

    bcadastro as (
        select
            cpf_id as cpf,
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
            ) as dados
        from `rj-crm-registry.brutos_bcadastro.cpf`
        where cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)

    ),

    all_cpfs as (
        select cpf, count as origens
        from `rj-crm-registry.app_identidade_unica.cpf`
        where safe_cast(cpf as int64) in (cpf_filter1, cpf_filter2, cpf_filter3)
    ),

    cadastro_geral as (
        select
            cpf,
            dados.nome as nome,
            dados.nome_social as nome_social,
            dados.data_nascimento as data_nascimento,
            dados.genero as genero,
            dados.raca as raca,
            dados.mae_nome as nome_mae,
            dados.pai_nome as nome_pai,
            null as ocupacao,
            null as data_ultima_atualizacao,
            null as situacao_cadastral,
            CAST(null AS BOOL) as estrangeiro,
            null as rank,
            'saude' as source
        from sms
        union all
        select
            cpf,
            dados.nome as nome,
            null as nome_social,
            dados.data_nascimento as data_nascimento,
            dados.sexo as genero,
            dados.raca_cor as raca,
            dados.nome_mae as nome_mae,
            dados.nome_pai as nome_pai,
            null as ocupacao,
            null as data_ultima_atualizacao,
            null as situacao_cadastral,
            CAST(null AS BOOL) as estrangeiro,
            null as rank,
            'cadunico' as source
        from smas
        union all
        select
            cpf,
            dados.nome as nome,
            null as nome_social,
            dados.data_nascimento as data_nascimento,
            dados.sexo as genero,
            null as raca,
            null as nome_pai,
            dados.nome_mae as nome_mae,
            dados.descricao_ocupacao as ocupacao,
            dados.data_ultima_atualizacao as data_ultima_atualizacao,
            dados.situacao_cadastral as situacao_cadastral,
            dados.estrangeiro as estrangeiro,
            null as rank,
            'bcadastro' as source
        from bcadastro
    ),

    cadastro as (
        select
            cpf,
            array_agg(
                struct(
                    source,
                    nome,
                    nome_social,
                    data_nascimento,
                    genero,
                    raca,
                    nome_mae,
                    nome_pai,
                    ocupacao,
                    data_ultima_atualizacao,
                    situacao_cadastral,
                    estrangeiro,
                    rank
                )
            ) as dados
        from cadastro_geral
        group by cpf
    ),

    endereco_geral as (
        select
            cpf,
            endereco.cep as cep,
            endereco.tipo_logradouro as tipo_logradouro,
            endereco.logradouro as logradouro,
            endereco.numero as numero,
            endereco.complemento as complemento,
            endereco.bairro as bairro,
            endereco.cidade as cidade,
            endereco.estado as estado,
            CAST(null AS BOOL) as residente_exterior,
            endereco.sistema as sistema,
            endereco.rank as rank,
            'saude' as source
        from sms, unnest(endereco) endereco
        union all
        select
            cpf as cpf,
            dados.cep as cep,
            dados.tipo_logradouro as tipo_logradouro,
            dados.logradouro as logradouro,
            dados.numero_logradouro as numero,
            dados.complemento as complemento,
            dados.bairro as bairro,
            dados.nome_municipio_domicilio as cidade,
            dados.uf_municipio_domicilio as estado,
            dados.residente_exterior as residente_exterior,
            null as sistema,
            null as rank,
            'bcadastro' as source
        from bcadastro
    ),

    endereco as (
        select
            cpf,
            array_agg(
                struct(
                    source,
                    cep,
                    tipo_logradouro,
                    logradouro,
                    numero,
                    complemento,
                    bairro,
                    cidade,
                    estado,
                    residente_exterior,
                    sistema,
                    rank
                )
            ) as endereco
        from endereco_geral
        group by cpf
    ),

    contato_geral_telefone as (
        select
            cpf,
            telefone.ddd as ddd,
            telefone.valor as valor,
            telefone.sistema,
            telefone.rank,
            'saude' as source
        from sms, unnest(contato.telefone) as telefone
        union all
        select
            cpf,
            null as ddd,
            dados.telefone as valor,
            null as sistema,
            null as rank,
            'bcadastro' as source
        from bcadastro
    ),
    contato_telefone as (
        select cpf, array_agg(struct(source, ddd, valor, sistema, rank)) as telefone
        from contato_geral_telefone
        group by cpf
    ),

    contato_email as (
        select
            cpf,
            array_agg(
                struct(
                    'saude' as source,
                    email.valor as valor,
                    email.sistema,
                    email.rank
                )
            ) as email
        from sms, unnest(contato.email) as email
        group by cpf
    ),

    contato as (
        select a.cpf, struct(t.telefone, e.email) contato
        from all_cpfs a
        left join contato_telefone t on a.cpf = t.cpf
        left join contato_email e on a.cpf = e.cpf
    )

select
    a.cpf,
    a.origens,
    ca.dados,
    e.endereco,
    co.contato,
    s.saude,
    c.cadunico,
    ep.saude_episodio,
    t.transporte,
    ch.chamados
from all_cpfs a
left join cadastro ca on a.cpf = ca.cpf
left join endereco e on a.cpf = e.cpf
left join contato co on a.cpf = co.cpf
left join sms s on a.cpf = s.cpf
left join sms_ep ep on a.cpf = ep.cpf
left join smas c on a.cpf = c.cpf
left join smtr t on a.cpf = t.cpf
left join segovi ch on a.cpf = ch.cpf

