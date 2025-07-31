{{
    config(
        materialized='table',
        alias='interacoes_cidadao',
        schema='crm_eventos',
        partition_by={'field': 'data_particao', 'data_type': 'date'},
        cluster_by=['sistema_origem', 'tipo_interacao', 'categoria_interacao'],
        tags=['daily', 'core', 'facts']
    )
}}

-- Fact table unificado: Todas as interações cidadão-prefeitura
-- Consolida dados de 1746, Wetalkie e Bcadastro em schema padronizado v1

with dados_unificados as (
    
    -- 1746: Chamados e solicitações (maior volume)
    select * from {{ ref('int_interacoes_1746') }}
    
    union all
    
    -- Wetalkie: Comunicações WhatsApp
    select * from {{ ref('int_interacoes_wetalkie_v1') }}
    
    union all
    
    -- Bcadastro: Operações cadastrais
    select * from {{ ref('int_interacoes_bcadastro_v1') }}
),

interacoes_validadas as (
    select
        -- IDENTIFICAÇÃO (2 campos)
        coalesce(id_interacao, generate_uuid()) as id_interacao,
        cpf_cidadao,
        
        -- ORIGEM (2 campos)
        sistema_origem,
        protocolo_origem,
        
        -- CLASSIFICAÇÃO ONTOLÓGICA (4 campos - expandido v1.1)
        tipo_interacao,
        categoria_interacao,
        subcategoria_interacao,
        descricao_interacao,
        
        -- CANAL (2 campos)
        canal_interacao,
        modalidade_interacao,
        
        -- TEMPORAL (3 campos)
        data_interacao,
        datahora_inicio,
        data_particao,
        
        -- LOCALIZAÇÃO (3 campos)
        bairro_interacao,
        endereco_interacao,
        coordenadas,
        
        -- RESULTADO (1 campo)
        desfecho_interacao,
        
        -- FLEXÍVEL (1 campo)
        coalesce(dados_origem, json '{}') as dados_origem
        
    from dados_unificados
    where 
        -- Validações essenciais
        cpf_cidadao is not null 
        and regexp_contains(cpf_cidadao, r'^\d{11}$')  -- CPF válido
        and data_interacao >= '2020-01-01'              -- Período válido
        and sistema_origem in ('segovi', 'wetalkie', 'bcadastro')  -- Sistemas conhecidos
        and tipo_interacao in ('SOLICITACAO', 'CONSUMO', 'REPORTE', 'COMUNICACAO', 'CADASTRO')
        and categoria_interacao in ('SERVICOS_URBANOS', 'SAUDE', 'COMUNICACAO_INSTITUCIONAL', 'GESTAO_CADASTRAL', 'TRANSPORTE', 'ASSISTENCIA_SOCIAL', 'EDUCACAO')
        and modalidade_interacao in ('DIGITAL', 'FISICO')
)

select 
    *,
    -- Metadados de controle
    current_timestamp() as _datalake_loaded_at,
    '1.1' as _schema_version
from interacoes_validadas