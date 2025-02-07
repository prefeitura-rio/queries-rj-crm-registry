{# DECLARE cpf_filter1 INT64 DEFAULT ;
DECLARE cpf_filter2 INT64 DEFAULT ;
DECLARE cpf_filter3 INT64 DEFAULT ; #}
CREATE OR REPLACE TABLE `rj-crm-registry.crm_identidade_unica.cadastros` 
PARTITION BY
  RANGE_BUCKET(cpf_particao, GENERATE_ARRAY(0, 100000000000, 34722222))

  AS
(
with

    all_cpfs as (
        select cpf, count as origens
        from `rj-crm-registry.crm_identidade_unica.cpf`
        where
            cpf_particao is not null
{# and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
    ),

    bcadastro as (
        select
            cpf,
            struct(
                ano_exercicio,
                data_inscricao,
                cpf,
                situacao_cadastral,
                nome,
                data_nascimento,
                genero,
                nome_mae,
                telefone_original,
                ddi,
                ddd,
                telefone,
                id_natureza_ocupacao,
                id_ocupacao,
                ocupacao,
                id_ua,
                id_municipio_domicilio,
                municipio_domicilio,
                uf_domicilio,
                id_municipio_nascimento,
                municipio_nascimento,
                uf_nascimento,
                cep,
                bairro,
                tipo_logradouro,
                logradouro,
                complemento,
                numero_logradouro,
                estrangeiro,
                residente_exterior,
                data_ultima_atualizacao
            ) as dados
        from `rj-crm-registry.brutos_bcadastro.cpf`
        where
            cpf_particao is not null
{# and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
    ),

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
        where
            cpf_particao is not null
{# and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
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
            ) as assistencia_social
        from `rj-smas.app_identidade_unica.cadastros`
        left join unnest(dados) as dados
        where
            cpf_particao is not null
{# and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3) #}
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
            cast(null as bool) as estrangeiro,
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
            cast(null as bool) as estrangeiro,
            null as rank,
            'cadunico' as source
        from smas
        union all
        select
            cpf,
            dados.nome as nome,
            null as nome_social,
            dados.data_nascimento as data_nascimento,
            dados.genero as genero,
            null as raca,
            null as nome_pai,
            dados.nome_mae as nome_mae,
            dados.ocupacao as ocupacao,
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
            cast(null as bool) as residente_exterior,
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
            dados.municipio_domicilio as cidade,
            dados.uf_domicilio as estado,
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
            null as ddi,
            telefone.ddd as ddd,
            telefone.valor as valor,
            telefone.sistema,
            telefone.rank,
            'saude' as source
        from sms, unnest(contato.telefone) as telefone
        union all
        select
            cpf,
            dados.ddi as ddi,
            dados.ddd as ddd,
            dados.telefone as valor,
            null as sistema,
            null as rank,
            'bcadastro' as source
        from bcadastro
    ),
    contato_telefone as (
        select
            cpf, array_agg(struct(source, ddi, ddd, valor, sistema, rank)) as telefone
        from contato_geral_telefone
        group by cpf
    ),

    contato_email as (
        select
            cpf,
            array_agg(
                struct(
                    'saude' as source, email.valor as valor, email.sistema, email.rank
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
    c.assistencia_social,
    cast(a.cpf as int64) as cpf_particao
from all_cpfs a
left join cadastro ca on a.cpf = ca.cpf
left join endereco e on a.cpf = e.cpf
left join contato co on a.cpf = co.cpf
left join sms s on a.cpf = s.cpf
left join
    smas c on a.cpf = c.cpf
{# ) #}

