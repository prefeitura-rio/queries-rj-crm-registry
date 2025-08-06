# Definição dos Tipos de Interação Cidadão-Prefeitura

## 🎯 Objetivo
Classificar **todas as formas** como um cidadão pode interagir com a Prefeitura do Rio de Janeiro, criando uma taxonomia abrangente e sistemática.

## 📚 Metodologia de Classificação

### **Critérios de Classificação:**
1. **Iniciativa**: Quem inicia a interação (cidadão vs prefeitura)
2. **Propósito**: Objetivo da interação 
3. **Direção**: Fluxo da informação/serviço
4. **Modalidade**: Como acontece (físico vs digital)

## 🏗️ Tipos de Interação Definidos

### **1. SOLICITACAO** 
**Definição**: Cidadão **pede** algo à prefeitura que requer **ação/providência**

**Características:**
- Iniciativa: Cidadão
- Direção: Cidadão → Prefeitura  
- Expectativa: Resposta/ação da prefeitura
- Rastreabilidade: Protocolo para acompanhamento

**Exemplos por Sistema:**
```yaml
1746_SEGOVI:
  - Remoção de entulho
  - Poda de árvore
  - Reparo de iluminação
  - Solicitação de transporte (Cegonha Carioca)
  
SMS_SAUDE:
  - Agendamento de consulta
  - Solicitação de exame
  - Pedido de medicamento
  - Solicitação de transporte médico
  
SMAS_SOCIAL:
  - Inscrição em programa social
  - Solicitação de benefício
  - Pedido de atendimento CRAS
  
SMTR_TRANSPORTE:
  - Solicitação de nova linha
  - Pedido de ponto de ônibus
  - Reclamação formal sobre serviço
```

### **2. CONSUMO**
**Definição**: Cidadão **usa** um serviço que a prefeitura já oferece

**Características:**
- Iniciativa: Cidadão
- Direção: Prefeitura → Cidadão
- Expectativa: Receber/consumir o serviço
- Transacional: Gera registro de uso

**Exemplos por Sistema:**
```yaml
SMS_SAUDE:
  - Consulta médica realizada
  - Exame laboratorial
  - Atendimento de emergência
  - Procedimento cirúrgico
  - Vacinação
  
SMTR_TRANSPORTE:
  - Viagem de ônibus
  - Uso do BRT  
  - Aluguel de Bike Rio
  - Recarga de cartão de transporte
  
SME_EDUCACAO:
  - Matrícula escolar
  - Merenda escolar
  - Uso de biblioteca pública
  
OUTROS:
  - Entrada em parque municipal
  - Uso de equipamento público
  - Participação em evento municipal
```


### **3. COMUNICACAO**
**Definição**: Prefeitura **comunica** proativamente com o cidadão

**Características:**
- Iniciativa: Prefeitura  
- Direção: Prefeitura → Cidadão
- Expectativa: Informar/educar/notificar
- Proativo: Não solicitado pelo cidadão

**Exemplos por Sistema:**
```yaml
WETALKIE_WHATSAPP:
  - Campanha de vacinação
  - Alerta de chuva forte
  - Informações sobre serviços
  - Resultado de exame
  - Confirmação de agendamento
  
SMS_NOTIFICACAO:
  - Lembrete de consulta
  - Data de coleta de lixo
  - Convocação para regularização
  
EMAIL_MARKETING:
  - Newsletter da prefeitura
  - Programação cultural
  - Editais e concursos
  
PORTAL_WEB:
  - Notícias municipais
  - Transparência pública
  - Avisos importantes
```

### **4. CADASTRO**
**Definição**: Atualização/manutenção de **dados pessoais** nos sistemas municipais

**Características:**
- Iniciativa: Cidadão ou Prefeitura
- Direção: Bidirectional
- Expectativa: Manter dados atualizados
- Regulatório: Muitas vezes obrigatório

**Exemplos por Sistema:**
```yaml
BCADASTRO:
  - Atualização de endereço
  - Inclusão de dependentes
  - Alteração de dados biométricos
  - Correção de informações pessoais
  
CARTAO_CARIOCA:
  - Emissão de cartão
  - Atualização de foto
  - Alteração de categoria
  
IPTU:
  - Cadastro de imóvel
  - Alteração de proprietário
  - Atualização de endereço de cobrança
  
VIGILANCIA_SANITARIA:
  - Cadastro de estabelecimento
  - Renovação de licença
  - Atualização de responsável técnico
```

## 🔄 Fluxos de Interação Complexos

### **Solicitação → Comunicação → Consumo**
```mermaid
cidadão --SOLICITACAO--> prefeitura : "Preciso de consulta"
prefeitura --COMUNICACAO--> cidadão : "Consulta agendada para X"  
cidadão --CONSUMO--> prefeitura : "Realiza consulta médica"
```

## 📊 Distribuição Esperada por Tipo

### **Por Volume (Estimado)**
1. **CONSUMO** (60-70%) - Uso massivo de serviços (transporte, saúde)
2. **COMUNICACAO** (15-20%) - Campanhas e notificações
3. **SOLICITACAO** (10-15%) - Chamados e pedidos específicos  
5. **CADASTRO** (1-5%) - Atualizações eventuais

### **Por Frequência Cidadão**
1. **CONSUMO** - Diário/semanal (transporte, saúde básica)
2. **COMUNICACAO** - Semanal (campanhas)
3. **SOLICITACAO** - Mensal/eventual (problemas específicos)
5. **CADASTRO** - Anual/eventual (mudanças na vida)

## 🎯 Aplicação nos Facts

### **Regras de Classificação**
```sql
CASE 
    -- CONSUMO: Uso efetivo de serviços
    WHEN sistema_origem = 'sms' AND tipo IN ('consulta', 'exame', 'procedimento') THEN 'CONSUMO'
    WHEN sistema_origem = 'smtr' AND tipo = 'viagem' THEN 'CONSUMO'
    
    -- SOLICITACAO: Pedidos explícitos
    WHEN sistema_origem = '1746' AND categoria LIKE '%solicitação%' THEN 'SOLICITACAO'
    WHEN sistema_origem = 'smas' AND tipo LIKE '%inscricao%' THEN 'SOLICITACAO'
    
    -- REPORTE: Informações sobre problemas
    WHEN sistema_origem = '1746' AND categoria LIKE '%fiscalização%' THEN 'REPORTE'
    WHEN sistema_origem = '1746' AND tipo LIKE '%buraco%' THEN 'REPORTE'
    
    -- COMUNICACAO: Contatos proativos da prefeitura
    WHEN sistema_origem = 'wetalkie' AND iniciador = 'prefeitura' THEN 'COMUNICACAO'
    
    -- CADASTRO: Alterações em dados
    WHEN sistema_origem = 'bcadastro' THEN 'CADASTRO'
    
    ELSE 'NAO_CLASSIFICADO'
END as tipo_interacao
```

## 💡 Valor para Gestão Pública

### **Planejamento de Capacidade**
- **CONSUMO**: Dimensionar infraestrutura (hospitais, ônibus)
- **SOLICITACAO**: Prever demandas sazonais  
- **COMUNICACAO**: Medir efetividade de campanhas
- **CADASTRO**: Planejar atualizações de sistemas

### **Experiência do Cidadão**
- **Jornada Integrada**: Ver todas as interações do cidadão
- **Proatividade**: Antecipar necessidades baseado em padrões
- **Eficiência**: Otimizar canais mais utilizados
- **Satisfação**: Medir resolutividade por tipo

### **Inteligência Urbana**
- **Demanda Real**: O que os cariocas mais precisam
- **Eficiência Operacional**: Onde investir recursos
- **Prevenção**: Antecipar problemas antes que virem solicitações
- **Inovação**: Novos serviços baseados em padrões de uso

---

**🏛️ Esta taxonomia converte milhões de eventos em insights estratégicos sobre como Rio de Janeiro serve seus cidadãos!**