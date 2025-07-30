# Classificação de Canais de Interação

## 🎯 Objetivo
Mapear **todos os canais** através dos quais cidadãos interagem com a Prefeitura do Rio de Janeiro, classificando por modalidade, acesso e características técnicas.

## 🏗️ Estrutura de Classificação

### **Modalidade Primária**
- **DIGITAL**: Interação mediada por tecnologia, remota
- **FISICO**: Interação presencial, em local específico
- **HIBRIDO**: Combinação de elementos digitais e físicos

### **Iniciativa de Acesso**
- **ATIVO**: Cidadão busca ativamente o canal
- **PASSIVO**: Canal alcança o cidadão (push)
- **REATIVO**: Resposta a uma ação prévia

## 📱 CANAIS DIGITAIS

### **1. WHATSAPP**
```yaml
codigo: WHATSAPP
modalidade: DIGITAL
iniciativa: ATIVO | PASSIVO
sistema_origem: wetalkie
capacidades:
  - Disparo em massa (PASSIVO)
  - Chatbot 24/7 (ATIVO)
  - Atendimento humano (ATIVO)
  - Agendamentos (ATIVO)
  - Consulta de protocolos (ATIVO)

tipos_interacao:
  - COMUNICACAO (campanhas, avisos)
  - SOLICITACAO (agendamentos, informações)
  - CONSUMO (consulta de dados)

vantagens:
  - Alta penetração (95%+ dos cariocas)
  - Interface familiar
  - Suporte a mídia (áudio, imagem)
  - Baixo custo operacional

limitacoes:
  - Dependente de internet
  - Limitações de compliance
  - Dificuldade com processos complexos
```

### **2. CENTRAL_TELEFONICA** (1746)
```yaml
codigo: CENTRAL_TELEFONICA
modalidade: DIGITAL
iniciativa: ATIVO
sistema_origem: segovi
capacidades:
  - Recebimento de chamados
  - Orientação sobre serviços
  - Abertura de protocolos
  - Encaminhamento para órgãos

tipos_interacao:
  - SOLICITACAO (pedidos de serviço)
  - REPORTE (denúncias, problemas)
  - SOLICITACAO (informações)

vantagens:
  - Acessível via telefone fixo/móvel
  - Atendimento humano
  - Histórico consolidado
  - Cobertura universal

limitacoes:
  - Custo de operação alto
  - Filas de espera
  - Horário limitado
  - Sem suporte visual
```

### **3. PORTAL_WEB**
```yaml
codigo: PORTAL_WEB
modalidade: DIGITAL  
iniciativa: ATIVO
sistemas_origem: [multiple]
capacidades:
  - Informações sobre serviços
  - Formulários online
  - Consulta de processos
  - Agendamento online
  - Emissão de documentos

subcanais:
  - rio.rj.gov.br (portal principal)
  - carioca.rio (cartão carioca)
  - clinicafamilia.org.br (SMS)
  - rioonibus.com (SMTR)

tipos_interacao:
  - SOLICITACAO (formulários, agendamentos)
  - CONSUMO (consultas, downloads)
  - CADASTRO (atualizações)

vantagens:
  - Disponível 24/7
  - Interface rica
  - Integração com sistemas
  - Self-service

limitacoes:
  - Barreira digital (idosos, baixa renda)
  - Requer internet banda larga
  - Complexidade de navegação
```

### **4. APP_MOBILE**
```yaml
codigo: APP_MOBILE
modalidade: DIGITAL
iniciativa: ATIVO
sistemas_origem: [multiple]
capacidades:
  - Notificações push
  - GPS/localização
  - Câmera (fotos de problemas)
  - Offline básico

principais_apps:
  - Rio Móvel (serviços gerais)
  - Meu Rio Card (transporte)
  - Cadê o Ônibus (SMTR)
  - 1746 Rio (chamados)

tipos_interacao:
  - SOLICITACAO (chamados com GPS)
  - REPORTE (denúncias com foto)
  - CONSUMO (serviços móveis)
  - COMUNICACAO (push notifications)

vantagens:
  - Interface mobile-first
  - Recursos nativos (GPS, câmera)
  - Push notifications
  - Uso offline limitado

limitacoes:
  - Necessita smartphone
  - Atualizações frequentes
  - Armazenamento no dispositivo
```

### **5. EMAIL**
```yaml
codigo: EMAIL
modalidade: DIGITAL
iniciativa: ATIVO | PASSIVO
sistemas_origem: [multiple]
capacidades:
  - Comunicação formal
  - Anexos de documentos
  - Histórico persistente
  - Automação (newsletters)

tipos_interacao:
  - COMUNICACAO (newsletters, avisos)
  - SOLICITACAO (pedidos formais)
  - CADASTRO (confirmações)

vantagens:
  - Formal e rastreável
  - Suporte a anexos
  - Histórico persistente
  - Baixo custo

limitacoes:
  - Menor engajamento
  - Risco de spam
  - Barreira para idosos
```

## 🏢 CANAIS FÍSICOS

### **6. UNIDADE_SAUDE**
```yaml
codigo: UNIDADE_SAUDE
modalidade: FISICO
iniciativa: ATIVO
sistema_origem: sms
capacidades:
  - Consultas médicas
  - Exames diagnósticos
  - Procedimentos
  - Vacinação
  - Emergências

subcanais:
  - UPA (Unidade de Pronto Atendimento)
  - Clínica da Família
  - Centro Municipal de Saúde
  - Hospital Municipal
  - Posto de Vacinação

tipos_interacao:
  - CONSUMO (consultas, exames, procedimentos)
  - SOLICITACAO (agendamentos presenciais)
  - CADASTRO (atualização de dados)

vantagens:
  - Atendimento especializado
  - Resolução completa
  - Confiança do cidadão
  - Equipamentos específicos

limitacoes:
  - Capacidade limitada
  - Horários restritos  
  - Deslocamento necessário
  - Filas presenciais
```

### **7. POSTO_ATENDIMENTO**
```yaml
codigo: POSTO_ATENDIMENTO
modalidade: FISICO
iniciativa: ATIVO
sistemas_origem: [multiple]
capacidades:
  - Emissão de documentos
  - Cadastros e atualizações
  - Atendimento multicanal
  - Orientação presencial

subcanais:
  - Poupa Tempo Carioca
  - Central de Atendimento ao Cidadão
  - Postos de Identificação
  - DETRAN

tipos_interacao:
  - CADASTRO (documentos, registros)
  - SOLICITACAO (serviços presenciais)
  - CONSUMO (atendimento especializado)

vantagens:
  - Resolução imediata
  - Múltiplos serviços
  - Atendimento humano
  - Validação de documentos

limitacoes:
  - Filas longas
  - Horário comercial
  - Localização limitada
  - Alto custo operacional
```

### **8. EQUIPAMENTO_PUBLICO**
```yaml
codigo: EQUIPAMENTO_PUBLICO
modalidade: FISICO
iniciativa: ATIVO
sistema_origem: smtr, outros
capacidades:
  - Transações automáticas
  - Validação de cartões
  - Informações em tempo real
  - Recarga de créditos

subcanais:
  - Ônibus municipal
  - Estações BRT
  - Terminais de transporte
  - Estações Bike Rio
  - Totens de autoatendimento

tipos_interacao:
  - CONSUMO (uso de transporte, bikes)
  - CADASTRO (recarga, validação)

vantagens:
  - Disponível onde o serviço acontece
  - Transações rápidas
  - Integração com cartão
  - Funciona 24/7

limitacoes:
  - Funcionalidade limitada
  - Dependente de manutenção
  - Risco de vandalismo
  - Interface simples
```

### **9. VIA_PUBLICA**
```yaml
codigo: VIA_PUBLICA
modalidade: FISICO
iniciativa: ATIVO | PASSIVO
sistemas_origem: [fiscalizacao, gm-rio]
capacidades:
  - Fiscalização móvel
  - Abordagem social
  - Multas e notificações
  - Operações especiais

tipos_interacao:
  - REPORTE (fiscalização encontra irregularidade)
  - COMUNICACAO (notificação presencial)
  - CADASTRO (atualizações in loco)

vantagens:
  - Proativo
  - No local do problema
  - Resolução imediata possível
  - Presença municipal

limitacoes:
  - Cobertura limitada
  - Dependente de agentes
  - Clima-dependente
  - Alto custo operacional
```

### **10. DOMICILIO**
```yaml
codigo: DOMICILIO
modalidade: FISICO
iniciativa: PASSIVO
sistemas_origem: [smas, vigilancia, censo]
capacidades:
  - Visita domiciliar
  - Censo e pesquisas
  - Atendimento especializado
  - Entrega de benefícios

tipos_interacao:
  - CONSUMO (atendimento domiciliar)
  - CADASTRO (censo, atualizações)
  - COMUNICACAO (notificações presenciais)

vantagens:
  - Alcança quem não pode sair
  - Contexto familiar
  - Personalizado
  - Inclusivo

limitacoes:
  - Altíssimo custo
  - Logística complexa
  - Questões de segurança
  - Baixa escala
```

## 🔄 CANAIS HÍBRIDOS

### **11. QR_CODE**
```yaml
codigo: QR_CODE
modalidade: HIBRIDO
iniciativa: ATIVO
sistemas_origem: [multiple]
capacidades:
  - Bridge físico → digital
  - Contexto local
  - Acesso rápido
  - Rastreabilidade

aplicacoes:
  - Pontos de ônibus (horários)
  - Estabelecimentos (fiscalização)
  - Equipamentos públicos (manutenção)
  - Eventos (informações)

tipos_interacao:
  - SOLICITACAO (via QR em equipamento quebrado)
  - CONSUMO (acesso a informações contextuais)
  - REPORTE (QR para denúncias localizadas)

vantagens:
  - Contexto físico preservado
  - Acesso digital simples
  - Baixo custo de implementação
  - Rastreável por localização

limitacoes:
  - Requer smartphone com câmera
  - Dependente de sinalização física
  - Pode ser vandalizado
```

## 📊 Matriz de Canais por Tipo de Interação

| Canal | SOLICITACAO | CONSUMO | REPORTE | COMUNICACAO | CADASTRO |
|-------|-------------|---------|---------|-------------|----------|
| **WHATSAPP** | ✅ Alta | ⚠️ Média | ⚠️ Média | ✅ Alta | ⚠️ Média |
| **CENTRAL_TELEFONICA** | ✅ Alta | ❌ Baixa | ✅ Alta | ⚠️ Média | ❌ Baixa |
| **PORTAL_WEB** | ✅ Alta | ✅ Alta | ⚠️ Média | ⚠️ Média | ✅ Alta |
| **APP_MOBILE** | ✅ Alta | ✅ Alta | ✅ Alta | ✅ Alta | ⚠️ Média |
| **EMAIL** | ⚠️ Média | ❌ Baixa | ⚠️ Média | ✅ Alta | ⚠️ Média |
| **UNIDADE_SAUDE** | ⚠️ Média | ✅ Alta | ❌ Baixa | ❌ Baixa | ⚠️ Média |
| **POSTO_ATENDIMENTO** | ✅ Alta | ✅ Alta | ❌ Baixa | ❌ Baixa | ✅ Alta |
| **EQUIPAMENTO_PUBLICO** | ❌ Baixa | ✅ Alta | ❌ Baixa | ❌ Baixa | ⚠️ Média |
| **VIA_PUBLICA** | ❌ Baixa | ❌ Baixa | ✅ Alta | ⚠️ Média | ⚠️ Média |
| **DOMICILIO** | ❌ Baixa | ✅ Alta | ❌ Baixa | ⚠️ Média | ✅ Alta |

## 🎯 Estratégias por Canal

### **Para Escala (Volume Alto)**
1. **WHATSAPP** - Automação máxima, chatbots inteligentes
2. **PORTAL_WEB** - Self-service, formulários inteligentes  
3. **APP_MOBILE** - Features offline, sincronização
4. **EQUIPAMENTO_PUBLICO** - Integração total, manutenção preditiva

### **Para Qualidade (Resolução Alta)**
1. **UNIDADE_SAUDE** - Especialização, equipamentos
2. **POSTO_ATENDIMENTO** - Atendimento multicanal integrado
3. **DOMICILIO** - Casos específicos, alta vulnerabilidade
4. **CENTRAL_TELEFONICA** - Triagem inteligente, scripts

### **Para Inovação (Futuro)**
1. **QR_CODE** - IoT urbana, contexto físico-digital
2. **AI_CHATBOTS** - Resolução autônoma avançada
3. **REALIDADE_AUMENTADA** - Manutenção, fiscalização
4. **BLOCKCHAIN** - Transparência, rastreabilidade

## 💡 Aplicação no Schema de Facts

```sql
-- Classificação de canal por sistema
CASE 
    WHEN sistema_origem = 'wetalkie' THEN 'WHATSAPP'
    WHEN sistema_origem = 'segovi' AND protocolo LIKE '1746%' THEN 'CENTRAL_TELEFONICA'
    WHEN sistema_origem = 'sms' AND local_atendimento IS NOT NULL THEN 'UNIDADE_SAUDE'
    WHEN sistema_origem = 'smtr' AND tipo = 'validacao_cartao' THEN 'EQUIPAMENTO_PUBLICO'
    WHEN origem LIKE '%web%' OR origem LIKE '%portal%' THEN 'PORTAL_WEB'
    WHEN origem LIKE '%app%' OR origem LIKE '%mobile%' THEN 'APP_MOBILE'
    WHEN origem LIKE '%email%' THEN 'EMAIL'
    WHEN origem LIKE '%presencial%' THEN 'POSTO_ATENDIMENTO'
    WHEN origem LIKE '%domicilio%' THEN 'DOMICILIO'
    WHEN origem LIKE '%rua%' OR origem LIKE '%via_publica%' THEN 'VIA_PUBLICA'
    ELSE 'NAO_IDENTIFICADO'
END as canal_interacao,

-- Modalidade automática
CASE 
    WHEN canal_interacao IN ('WHATSAPP', 'CENTRAL_TELEFONICA', 'PORTAL_WEB', 'APP_MOBILE', 'EMAIL') 
        THEN 'DIGITAL'
    WHEN canal_interacao IN ('UNIDADE_SAUDE', 'POSTO_ATENDIMENTO', 'EQUIPAMENTO_PUBLICO', 'VIA_PUBLICA', 'DOMICILIO') 
        THEN 'FISICO'
    WHEN canal_interacao IN ('QR_CODE') 
        THEN 'HIBRIDO'
    ELSE 'NAO_CLASSIFICADO'
END as modalidade_interacao
```

---

**🌐 Esta classificação permite otimizar cada canal para seu melhor uso, criando uma experiência omnichannel integrada para os cariocas!**