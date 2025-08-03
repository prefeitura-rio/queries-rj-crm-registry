# Mapeamento de Classificação - Sistema 1746 (SEGOVI)

## 📊 Dados Analisados
- **Dataset**: `joaoc__crm_eventos.governo_integridade__1746_chamado`
- **Registros**: 14.227.710 
- **Período**: Histórico completo
- **Data da Análise**: 30/07/2025

## 🏷️ Classificação na Ontologia

### **Tipo de Interação**: `SOLICITACAO` | `REPORTE`
- Cidadãos **solicitam** serviços ou **reportam** problemas via 1746

### **Categoria**: `SERVICOS_URBANOS`
- Todos os 14.2M registros são da categoria "Serviço"

### **Canal**: `CENTRAL_TELEFONICA` (primário)
- Sistema 1746 = Central telefônica municipal
- Alguns registros podem vir de `PORTAL_WEB` ou `APP_MOBILE`

### **Modalidade**: `DIGITAL`
- Interação iniciada remotamente (telefone/web)

## 📋 Mapeamento Detalhado por Volume

### **TOP 10 Tipos de Serviço → Subcategorias**

| Tipo (Sistema) | Frequência | % | Subcategoria Ontologia | Tipo Interação |
|----------------|------------|---|----------------------|----------------|
| Remoção Gratuita | 2.779.156 | 19.5% | `limpeza_urbana_remocao_entulho` | SOLICITACAO |
| Iluminação Pública | 1.868.312 | 13.1% | `infraestrutura_iluminacao_publica` | REPORTE |
| Estacionamento Irregular | 1.288.324 | 9.1% | `fiscalizacao_transito_estacionamento` | REPORTE |
| Limpeza | 791.126 | 5.6% | `limpeza_urbana_logradouros` | SOLICITACAO |
| Pavimentação | 776.842 | 5.5% | `infraestrutura_pavimentacao` | REPORTE |
| Manejo Arbóreo | 767.219 | 5.4% | `meio_ambiente_manejo_arvores` | SOLICITACAO |
| Drenagem e Saneamento | 530.528 | 3.7% | `infraestrutura_drenagem` | REPORTE |
| Comlurb - Vetores | 311.883 | 2.2% | `meio_ambiente_controle_vetores` | REPORTE |
| Limpeza de logradouros | 287.917 | 2.0% | `limpeza_urbana_logradouros` | SOLICITACAO |
| Estrutura de Imóvel | 244.919 | 1.7% | `fiscalizacao_estrutura_imovel` | REPORTE |

### **TOP 15 Subtipos → Especificações**

| Subtipo (Sistema) | Frequência | Subcategoria | Especificação |
|-------------------|------------|--------------|---------------|
| Remoção de entulho e bens inservíveis | 2.765.275 | `limpeza_urbana_remocao_entulho` | `entulho_residencial` |
| Fiscalização de estacionamento irregular | 1.823.192 | `fiscalizacao_transito_estacionamento` | `veiculo_irregular` |
| Reparo de lâmpada apagada | 1.226.563 | `infraestrutura_iluminacao_publica` | `lampada_apagada` |
| Reparo de buraco na pista | 601.216 | `infraestrutura_pavimentacao` | `buraco_via` |
| Poda de árvore em logradouro | 553.679 | `meio_ambiente_manejo_arvores` | `poda_preventiva` |
| Remoção de resíduos no logradouro | 401.374 | `limpeza_urbana_logradouros` | `residuos_via_publica` |
| Controle de roedores e caramujos | 292.928 | `meio_ambiente_controle_vetores` | `controle_pragas` |
| Vistoria em foco de Aedes Aegypti | 221.564 | `meio_ambiente_controle_vetores` | `dengue_zika_chikungunya` |
| Fiscalização de obras em imóvel privado | 202.020 | `fiscalizacao_estrutura_imovel` | `obra_irregular` |
| Solicitação de transporte da gestante | 185.871 | `assistencia_social_transporte` | `cegonha_carioca` |
| Capina em logradouro | 165.847 | `limpeza_urbana_logradouros` | `capina_mato` |
| Reparo de Luminária | 163.417 | `infraestrutura_iluminacao_publica` | `luminaria_defeito` |
| Varrição de logradouro | 154.838 | `limpeza_urbana_logradouros` | `varrição_rua` |
| Reparo de sinal de trânsito apagado | 121.204 | `infraestrutura_sinalizacao` | `semaforo_apagado` |
| Desobstrução de bueiros | 120.560 | `infraestrutura_drenagem` | `bueiro_entupido` |

## 🎯 Domínios Identificados

### **1. INFRAESTRUTURA URBANA** (35.8% - 5.1M registros)
```yaml
subcategorias:
  infraestrutura_iluminacao_publica:
    - lampada_apagada (1.2M)
    - luminaria_defeito (163k)  
    - lampada_piscando (82k)
    - bloco_lampadas_apagadas (85k)
    
  infraestrutura_pavimentacao:
    - buraco_via (601k)
    - deformacao_pista
    - afundamento_asfalto
    
  infraestrutura_sinalizacao:
    - semaforo_apagado (121k)
    - sinalizacao_horizontal
    - placas_transito
    
  infraestrutura_drenagem:
    - bueiro_entupido (120k)
    - galeria_pluvial
    - ramal_aguas_pluviais (107k)
    - reposicao_tampa_grelha (112k)
```

### **2. LIMPEZA URBANA** (22.8% - 3.2M registros)
```yaml
subcategorias:
  limpeza_urbana_remocao_entulho:
    - entulho_residencial (2.8M)
    - bens_inserviveis
    - veiculo_abandonado (106k)
    
  limpeza_urbana_logradouros:
    - residuos_via_publica (401k)
    - capina_mato (166k)
    - varrição_rua (155k)
    - coleta_irregular (94k)
```

### **3. FISCALIZAÇÃO** (13.3% - 1.9M registros)
```yaml
subcategorias:
  fiscalizacao_transito_estacionamento:
    - veiculo_irregular (1.8M)
    - obstrucao_via
    
  fiscalizacao_estrutura_imovel:
    - obra_irregular (202k)
    - rachadura_infiltracao (110k)
    - ameaca_desabamento
    
  fiscalizacao_comercio:
    - atividade_sem_alvara (97k)
    - comercio_ambulante (109k)
    - obstrucao_calcada (95k)
```

### **4. MEIO AMBIENTE** (7.0% - 1.0M registros)
```yaml
subcategorias:
  meio_ambiente_manejo_arvores:
    - poda_preventiva (554k)
    - remocao_arvore (95k)
    - plantio_arvore
    
  meio_ambiente_controle_vetores:
    - controle_pragas (293k)
    - dengue_zika_chikungunya (222k)
    - desratizacao
```

## 📊 Status de Resolução

| Status Original | Frequência | % | Status Padronizado |
|----------------|------------|---|-------------------|
| Fechado com solução | 9.280.451 | 65.2% | `RESOLVIDA` |
| Sem possibilidade de atendimento | 2.132.278 | 15.0% | `NAO_APLICAVEL` |
| Não constatado | 1.164.687 | 8.2% | `NAO_CONSTATADA` |
| Fechado com providências | 716.999 | 5.0% | `RESOLVIDA_PARCIAL` |
| Fechado de Ofício | 225.644 | 1.6% | `ADMINISTRATIVA` |
| Aberto | 154.705 | 1.1% | `EM_ANDAMENTO` |
| Em Andamento | 139.392 | 1.0% | `EM_ANDAMENTO` |
| Pendente | 103.173 | 0.7% | `AGUARDANDO` |
| Outros | 310.381 | 2.2% | `OUTROS` |

## 🏗️ Schema Proposto para Fact

```sql
-- fct_interacoes_1746.sql
SELECT
    -- Identificação
    GENERATE_UUID() as id_interacao,
    cpf as cpf_cidadao,
    id_chamado as protocolo_origem,
    
    -- Classificação Ontológica
    CASE 
        WHEN categoria IN ('SOLICITACAO', 'PEDIDO') THEN 'SOLICITACAO'
        ELSE 'REPORTE' 
    END as tipo_interacao,
    
    'SERVICOS_URBANOS' as categoria_interacao,
    'CENTRAL_TELEFONICA' as canal_interacao,
    'DIGITAL' as modalidade_interacao,
    
    -- Mapeamento específico por tipo
    CASE 
        WHEN tipo = 'Remoção Gratuita' THEN 'limpeza_urbana_remocao_entulho'
        WHEN tipo = 'Iluminação Pública' THEN 'infraestrutura_iluminacao_publica'
        WHEN tipo = 'Estacionamento Irregular' THEN 'fiscalizacao_transito_estacionamento'
        WHEN tipo = 'Limpeza' THEN 'limpeza_urbana_logradouros'
        WHEN tipo = 'Pavimentação' THEN 'infraestrutura_pavimentacao'
        WHEN tipo = 'Manejo Arbóreo' THEN 'meio_ambiente_manejo_arvores'
        -- ... outros mapeamentos
        ELSE 'outros_servicos_urbanos'
    END as subcategoria,
    
    -- Contexto
    data_inicio as data_interacao,
    data_inicio as datahora_inicio,
    data_fim as datahora_fim,
    CASE 
        WHEN status IN ('Fechado com solução') THEN 'RESOLVIDA'
        WHEN status IN ('Sem possibilidade de atendimento') THEN 'NAO_APLICAVEL'
        WHEN status = 'Não constatado' THEN 'NAO_CONSTATADA'
        WHEN status LIKE 'Aberto%' OR status LIKE 'Em Andamento%' THEN 'EM_ANDAMENTO'
        ELSE 'OUTROS'
    END as desfecho_interacao,
    
    -- Localização
    id_bairro,
    id_logradouro,
    latitude,
    longitude,
    
    -- Dados específicos preservados
    STRUCT(
        origem_ocorrencia,
        categoria,
        tipo,
        subtipo,
        descricao,
        justificativa_status,
        nome_unidade_organizacional
    ) as dados_origem

FROM {{ source('crm_eventos', 'governo_integridade__1746_chamado') }}
WHERE cpf IS NOT NULL
```

## 🎯 Insights para Gestão

### **Padrões de Demanda**
1. **Infraestrutura** domina (35.8%) - foco em manutenção preventiva
2. **Limpeza urbana** é crítica (22.8%) - otimizar coleta e limpeza
3. **Fiscalização** consome recursos (13.3%) - automação possível

### **Eficiência de Resolução**
- **65.2%** dos chamados resolvidos com sucesso
- **15%** não aplicáveis (filtrar melhor na entrada)
- **8.2%** não constatados (melhorar triagem)

### **Oportunidades de Melhoria**
1. **Proatividade**: Antecipar manutenção de iluminação
2. **Prevenção**: Educação para reduzir entulho irregular
3. **Automation**: Classificação automática de chamados
4. **Integration**: Cruzar com dados de campo para validação

---

**📞 Este mapeamento transforma 14.2M chamados em inteligência sobre demandas urbanas do Rio!**