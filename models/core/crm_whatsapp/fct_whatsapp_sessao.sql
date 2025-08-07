{{ config(alias="sessao", schema="crm_whatsapp", materialized="view") }}

with
    source as (
        select *
        from {{ ref("int_chatbot_base_receptiva") }}
        where inicio_datahora >= '2025-04-18 12:00:00'
    ),

    mensagem_ativa as (
        select *
        from `rj-crm-registry`.`crm_whatsapp`.`mensagem_ativa`
    ),

    fluxo_atendimento AS (
    SELECT
        triggerId AS id_disparo, 
        replyId AS id_sessao,
        targetId AS id_contato,
        flatTarget AS contato_telefone,
        CAST(EXTRACT(YEAR FROM
                timestamp_sub(
                   sendDate,
                    interval 3 hour  -- Ajuste de fuso horário para -3
                )
            ) AS STRING) as ano_particao_hsm,
        CAST(EXTRACT(MONTH FROM
                timestamp_sub(
                   sendDate,
                    interval 3 hour  -- Ajuste de fuso horário para -3
                )
            ) AS STRING) as mes_particao_hsm,
        DATE(DATE_TRUNC(
                timestamp_sub(
                   sendDate,
                    interval 3 hour  -- Ajuste de fuso horário para -3
                ),
              day
            )) as data_particao_hsm,
        struct(
          templateId AS id_hsm,
          createDate AS criacao_envio_datahora,
          sendDate AS envio_datahora,
          deliveryDate AS entrega_datahora,
          readDate AS leitura_datahora,
          failedDate AS falha_datahora,
          replyDate AS resposta_datahora,
          faultDescription AS descricao_falha,
          mensagem_ativa.nome_hsm,
          mensagem_ativa.ambiente,
          mensagem_ativa.categoria,
          mensagem_ativa.orgao
            ) as hsm,
        lower(status) AS status_disparo
    FROM {{ source("brutos_wetalkie_staging", "fluxo_atendimento_*") }}
    left join mensagem_ativa ON mensagem_ativa.id_hsm = templateId
    QUALIFY row_number() OVER (PARTITION BY replyId ORDER BY datarelay_timestamp DESC) = 1
),

    source_com_hsm AS (
        select COALESCE(source_.id_sessao, fluxo_atendimento.id_sessao) as id_sessao,
        source_.* EXCEPT(id_sessao), fluxo_atendimento.id_disparo, fluxo_atendimento.hsm, fluxo_atendimento.status_disparo,
        fluxo_atendimento.id_contato,
        fluxo_atendimento.contato_telefone,
        fluxo_atendimento.ano_particao_hsm,
        fluxo_atendimento.mes_particao_hsm,
        fluxo_atendimento.data_particao_hsm,
        from source as source_
        full outer join fluxo_atendimento using (id_sessao)
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
--             lower(

--     upper(
--         trim(
--             regexp_replace(
--                 regexp_replace(normalize(texto, nfd), r"\pM", ''), r'[^ A-Za-z]', ' '
--             )
--         )
--     )

-- ) as texto_limpo,
            source_com_hsm.hsm,
            source_com_hsm.status_disparo

        from source_com_hsm, unnest(mensagens) as mensagem
    ),

    -- necessário o distinct anterior pois as vezes o json repete a mesma mensagem Ex: protocolo "2506001000000990"
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
        from sequencia_mensagens
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

    -- CALCULOS DE TEMPO
    session_timestamps AS (
      SELECT
        id_sessao,
        MIN(data) as primeira_mensagem,
        MAX(CASE WHEN fonte = 'CUSTOMER' THEN data ELSE NULL END) as ultima_mensagem_cliente
      FROM sequencia_mensagens
      GROUP BY id_sessao
    ),

    message_response_times AS (
      SELECT
        id_sessao,
        id_mensagem,
        fonte,
        data,
        CASE 
          WHEN fonte = 'CUSTOMER' AND 
            LAG(fonte) OVER (PARTITION BY id_sessao ORDER BY data) = 'URA'
          THEN TIMESTAMP_DIFF(
              data,
              LAG(data) OVER (PARTITION BY id_sessao ORDER BY data), 
              MILLISECOND)/1000
          ELSE NULL
        END as tempo_resposta_cliente_seg
      FROM sequencia_mensagens
    ),

    -- ESTATISTICAS:
    estatisticas as (
        select
            sm.id_sessao,
            struct(
                count(distinct sm.id_mensagem) as total_mensagens,
                count(
                    distinct case when sm.fonte = 'CUSTOMER' then sm.id_mensagem end
                ) as total_mensagens_contato,
                count(
                    distinct case when lower(texto) not like 'oi%como%posso%ajudar%' and sm.fonte = 'URA' and sm.passo_ura_nome ='@VLR_RESPOSTA_BUSCA' then sm.id_mensagem end
                ) as total_mensagens_busca,
                -- ?? Deixar a ultima mensagem do cliente ou filtrar a ultima mensagem que não for finalizacao automarica?
                -- Tempo efetivo de sessão (do início/hsm até a última mensagem do cliente) 
                MAX(TIMESTAMP_DIFF(TIMESTAMP(st.ultima_mensagem_cliente), COALESCE(TIMESTAMP(hsm.leitura_datahora), TIMESTAMP(sessao_inicio_datahora)), MILLISECOND))/1000 as duracao_sessao_seg,
                -- Tempo efetivo de interação do cliente sessão (do início da interação até a última mensagem do cliente)
                MAX(TIMESTAMP_DIFF(TIMESTAMP(st.ultima_mensagem_cliente), TIMESTAMP(st.primeira_mensagem), MILLISECOND))/1000 as duracao_interacao_seg,
                -- Tempo efetivo de sessão (do início da URA até a última mensagem do cliente)
                MAX(TIMESTAMP_DIFF(TIMESTAMP(st.ultima_mensagem_cliente), TIMESTAMP(sm.sessao_inicio_datahora), MILLISECOND))/1000 as duracao_ura_seg,
                AVG(mrt.tempo_resposta_cliente_seg) as tempo_medio_resposta_cliente_seg
            ) as estatisticas
        from sequencia_mensagens sm
        LEFT JOIN session_timestamps st ON sm.id_sessao = st.id_sessao
        LEFT JOIN message_response_times mrt ON 
          sm.id_sessao = mrt.id_sessao AND 
          sm.id_mensagem = mrt.id_mensagem
        group by 1
    ),

    -- - tabela final:
    final as (
        select
            m.* EXCEPT(ano_particao, mes_particao, data_particao, ano_particao_hsm, mes_particao_hsm, data_particao_hsm, id_contato, contato),
            struct(
              if(contato.id is null, CAST(id_contato AS STRING), contato.id) as id, contato.nome, m.contato_telefone as telefone 
            ) AS contato,
            struct(
                if(b.id_sessao is not null, true, false) as indicador, b.feedback
            ) as busca,
            struct(
                if(err.id_sessao is not null, true, false) as indicador, err.tipo_erro
            ) as erro_fluxo,
            stat.estatisticas,
            COALESCE(ano_particao, ano_particao_hsm) as ano_particao,
            COALESCE(mes_particao, mes_particao_hsm) as mes_particao,
            COALESCE(data_particao, data_particao_hsm) as data_particao
        from source_com_hsm as m
        left join erros_consolidados as err using (id_sessao)
        left join sessoes_com_busca_e_feedback as b using (id_sessao)
        left join estatisticas as stat using (id_sessao)
    )

select *
from final
order by inicio_datahora desc, id_sessao asc
