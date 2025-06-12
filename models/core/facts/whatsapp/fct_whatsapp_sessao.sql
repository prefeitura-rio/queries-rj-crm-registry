{{ config(alias="sessao", schema="crm_whatsapp", materialized="view") }}

with
    source as (
        select *
        from {{ ref("raw_wetalkie_fluxos_ura") }}
        where inicio_datahora >= '2025-04-18 12:00:00'
    ),

    mensagens as (
        select
            DISTINCT
            id_sessao,
            protocolo,
            inicio_data as sessao_inicio_data,
            inicio_datahora as sessao_inicio_datahora,
            lower(contato.nome) as contato_nome,
            lower(tabulacao.nome) as tabulacao_nome,
            ura.id as id_ura,
            ura.nome as ura_nome,
            mensagem.data,
            mensagem.id as id_mensagem,
            mensagem.tipo,
            mensagem.fonte,
            mensagem.passo_ura.id as passo_ura_id,
            mensagem.passo_ura.nome as passo_ura_nome,
            mensagem.texto,
            lower({{ clean_name_string("texto") }}) as texto_limpo,

        from source, unnest(mensagens) as mensagem
    ),

    -- necessário pois as vezes o json repete a mesma mensagem Ex: protocolo "2506001000000990"
    sequencia_mensagens AS (
        select *,
            row_number() over (partition by id_sessao order by data) as sequencia
        from mensagens
    ),

    ultima_mensagem as (
        select *
        from sequencia_mensagens
        qualify row_number() over (partition by id_sessao order by data desc) = 1
    ),

    -- TIPOS DE ERRO:
    -- usuario forçou o encerramento da conversa:
    erro_fluxo_travado__usuario_encerra as (
        select distinct id_sessao, 'usuario_encerrou' as tipo_erro
        from ultima_mensagem
        where fonte = 'CUSTOMER' and texto_limpo in ('sair', 'encerrar')
    ),

    -- -- ultima mensagem não é a esperada de finalização
    -- erro_fluxo_travado__ultima_mensagem_nao_finalizacao as (
    --     select distinct id_sessao, 'fluxo_travado' as tipo_erro
    --     from ultima_mensagem
    --     where texto_limpo not like "%ate a proxima%"
    -- ),

    -- ultima mensagem é do usuário
    erro_fluxo_travado__ultima_mensagem_usuario as (
        select distinct id_sessao, 'fluxo_travado' as tipo_erro
        from ultima_mensagem
        where fonte = 'CUSTOMER' and texto_limpo not in ('sair', 'encerrar')
    ),

    -- usuario mandou mensagens consecutivas, isso é um erro?
    erro_fluxo_travado__usuario_mandou_mensagens_consecutivas as (
        select distinct m1.id_sessao, 'mensagens consecutivas' as tipo_erro
        from sequencia_mensagens m1
        inner join
            (
                select *, sequencia - 1 as sequencia_anterior
                from sequencia_mensagens
                where sequencia > 1
            ) m2
            on m1.id_sessao = m2.id_sessao
            and m1.fonte = 'CUSTOMER'
            and m2.fonte = 'CUSTOMER'
            and m2.sequencia_anterior = m1.sequencia

    ),

    -- loop travado: URA retorna a mesma mensagem várias vezes em tempos distintos. Ex: protocolo = '2506001000000976'
    erro_fluxo_travado__loop_ura as (
        select distinct m1.id_sessao, 'loop_ura' as tipo_erro
        from sequencia_mensagens m1
        inner join
            (
                select *, sequencia - 1 as sequencia_anterior
                from sequencia_mensagens
                where sequencia > 1
            ) m2
            on m1.id_sessao = m2.id_sessao
            and m1.fonte = 'URA'
            and m2.fonte = 'URA'
            and m2.sequencia_anterior = m1.sequencia
            and m2.texto = m1.texto
    ),

    -- chatbot retornou que a opção selecionada é inválida:
    erro_opcao_invalida as (
        select distinct id_sessao, 'opcao_invalida' as tipo_erro
        from mensagens
        where fonte = 'URA' and texto_limpo like '%opcao invalida%'
    ),

    -- ERROS CONSOLIDADOS:
    erros_consolidados as (
        select id_sessao, array_agg(tipo_erro order by tipo_erro) as tipo_erro
        from
            (
                select *
                from erro_fluxo_travado__usuario_encerra
                union all
                -- select *
                -- from erro_fluxo_travado__ultima_mensagem_nao_finalizacao
                -- union all
                select *
                from erro_fluxo_travado__ultima_mensagem_usuario
                union all
                select *
                from erro_fluxo_travado__usuario_mandou_mensagens_consecutivas
                union all
                select *
                from erro_opcao_invalida
                union all
                select *
                from erro_fluxo_travado__loop_ura
            )
        group by 1
    ),

    -- FEEDBACK DAS BUSCA:
    sessoes_com_busca as (
        select distinct id_sessao
        from sequencia_mensagens
        where passo_ura_nome ='@VLR_RESPOSTA_BUSCA' and fonte = 'URA'
    ),

    feedback_busca as (
        select
            m1.id_sessao,
            struct(
                m1.texto_limpo as pergunta,
                m2.texto_limpo as resposta,
                (
                    if(m2.texto_limpo = "nao", m3.texto_limpo, null)
                ) as resposta_negativa_complemento
            ) as feedback
        from sequencia_mensagens as m1
        left join
            sequencia_mensagens as m2
            on m1.id_sessao = m2.id_sessao
            and m1.sequencia + 1 = m2.sequencia
        left join
            sequencia_mensagens as m3
            on m1.id_sessao = m3.id_sessao
            and m1.sequencia + 3 = m3.sequencia
        where
            m1.texto_limpo like 'o whatsapp funcionou como esperado'
            and m2.texto_limpo in ('sim', 'nao')
    ),

    sessoes_com_busca_e_feedback as (
        select s.id_sessao, f.feedback
        from sessoes_com_busca as s
        left join feedback_busca as f using (id_sessao)
    ),

    -- ESTATISTICAS:
    estatisticas as (
        select
            id_sessao,
            struct(
                count(distinct id_mensagem) as total_mensagens,
                count(
                    distinct case when fonte = 'CUSTOMER' then id_mensagem end
                ) as total_mensagens_contato,
                count(
                    distinct case when lower(texto) not like 'oi%como%posso%ajudar%' and fonte = 'URA' and passo_ura_nome ='@VLR_RESPOSTA_BUSCA' then id_mensagem end
                ) as total_mensagens_busca
            ) as estatisticas
        from sequencia_mensagens
        group by 1
    ),

    -- - tabela final:
    final as (
        select
            m.*,
            struct(
                if(b.id_sessao is not null, true, false) as indicador, b.feedback
            ) as busca,
            struct(
                if(err.id_sessao is not null, true, false) as indicador, err.tipo_erro
            ) as erro_fluxo,
            stat.estatisticas
        from source as m
        left join erros_consolidados as err using (id_sessao)
        left join sessoes_com_busca_e_feedback as b using (id_sessao)
        left join estatisticas as stat using (id_sessao)
    )

select *
from final
order by inicio_datahora desc, id_sessao asc
