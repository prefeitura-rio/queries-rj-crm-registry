# Análise de Qualidade de Telefone para WhatsApp

Documentação técnica da classificação bidimensional de telefones para envio de mensagens via WhatsApp.

## Contexto e Necessidade

A Prefeitura do Rio de Janeiro utiliza WhatsApp para comunicação com cidadãos. O sistema classifica telefones em **duas dimensões independentes** para otimizar a probabilidade de sucesso na entrega:

1. **Qualidade do Número**: Características técnicas do número em si
2. **Confiança na Propriedade**: Indicações de que a pessoa é realmente dona do número

## Sistema de Classificação Bidimensional

### Qualidade do Numero

Formato correto de celular: [Construir uma macro para essas regras]
  - Se for brasileiro: 
    - Formato celular brasileiro válido (55 + DDD + 9XXXXXXXX)
    - DD válido
    - 9 dígitos no padrão atual 
    - Iniciado com digito 9
  - Se for internacional: 
    - DDI Válido
    - Formato de celular válido [ver regras]

#### VALIDO
**Definição**: Número tecnicamente correto e funcional para WhatsApp.

**Características**:
- Formato Correto de Celular 
AND
- Baixa frequência de uso (≤ 5 pessoas - indica número real)


#### SUSPEITO  
**Definição**: Número com formato válido mas características questionáveis.

**Características**:
- Formato tecnicamente correto 
AND (
- Frequência moderada a alta (6-15 pessoas - indica numero compartilhado) 
OR
- Padrões numéricos aceitáveis mas não ideais
  - Repetição de dígito >5 em seguida
  - Repetição de dois ou tres digitos (212121 ou 123123123)
)


#### INVALIDO
**Definição**: Número tecnicamente incorreto ou claramente falso.

**Características**:
- Formato inválido (DDI/DDD errados, comprimento incorreto)
OR
- Padrões óbvios de número falso 
  - todos os numeros repetidos
  - sequencia numerica completa (123456789)
OR
- Frequência extremamente alta (> 15 pessoas)
OR
- Sequências numéricas conhecidas como dummy
OR 
- Numero governamental vindo da tabela de estabelecimentos [OPCIONAL]


### Confiança na Propriedade

#### CONFIRMADA
**Definição**: **Confirmação direta no app oficial** da prefeitura pela própria pessoa.

**Características**:
- Pessoa validou o número no aplicativo da prefeitura no ultimos 12 meses [12 é uma variável a ser definida com mais precisao no futuro]


#### MUITO_PROVAVEL
**Definição**: **Interação recente confirmada** via WhatsApp - pessoa respondeu.

**Características**:
- **Pessoa respondeu** mensagem WhatsApp nos últimos 6 meses
AND
- Resposta não é automática / pedido de optout / negativa


#### PROVAVEL  
**Definição**: **Atualização recente** em sistemas de alta confiança.

**Características**:
- Fonte oficial de alta confiança (hci, cadrio, bilhetagem_jae) 
AND
- Atualização do cadastro nos **últimos 6 meses**

#### POUCO_PROVAVEL
**Definição**: **Atualização moderadamente recente** em qualquer sistema oficial.

**Características**:
- Fonte de qualquer sistema 
AND
- Atualização do cadastro nos **últimos 2 anos** ou não existe

#### IMPROVAVEL
**Definição**: **Poucas ou nenhuma evidência** de que a pessoa é dona do número.

**Características**:
- **Falha confirmada** em tentativas anteriores de contato [pedido de optout / negativa]
OR
- Dados muito antigos (> 2 anos sem atualização)


## Matriz de Combinações e Estratégias

### Combinações Possíveis (qualidade_numero × confianca_propriedade)

| Qualidade → <br> Confiança ↓ | VALIDO | SUSPEITO | INVALIDO |
|---|---|---|---|
| **CONFIRMADA** | 🟢 **ENVIAR** <br> (95-98% sucesso) | 🟡 **TESTAR** <br> (75-90% sucesso) | 🔴 **NÃO ENVIAR** <br> (0-5% sucesso) |
| **MUITO_PROVAVEL** | 🟢 **ENVIAR** <br> (85-95% sucesso) | 🟡 **TESTAR** <br> (65-80% sucesso) | 🔴 **NÃO ENVIAR** <br> (0-10% sucesso) |
| **PROVAVEL** | 🟡 **TESTAR** <br> (75-90% sucesso) | 🟠 **EVITAR** <br> (50-70% sucesso) | 🔴 **NÃO ENVIAR** <br> (0-10% sucesso) |
| **POUCO_PROVAVEL** | 🟠 **EVITAR** <br> (50-70% sucesso) | 🟠 **EVITAR** <br> (30-50% sucesso) | 🔴 **NÃO ENVIAR** <br> (0-10% sucesso) |
| **IMPROVAVEL** | 🔴 **EVITAR** <br> (10-30% sucesso) | 🔴 **EVITAR** <br> (5-20% sucesso) | 🔴 **NÃO ENVIAR** <br> (0-5% sucesso) |

### Lógica de Ranqueamento de Telefones

Para determinar qual o telefone principal de uma pessoa, é aplicada uma lógica de ranqueamento que prioriza os números com maior probabilidade de sucesso no contato. A ordenação segue os seguintes critérios, nesta ordem de importância:

1.  **Tipo de Telefone**: Números de celular (`CELULAR`) têm prioridade sobre telefones fixos (`FIXO`).
2.  **Confiança na Propriedade**: A confiança de que o número pertence à pessoa é o segundo critério. A ordem de prioridade é:
    - `CONFIRMADA`
    - `MUITO_PROVAVEL`
    - `PROVAVEL`
    - `POUCO_PROVAVEL`
    - `IMPROVAVEL`
3.  **Data de Atualização**: Como critério de desempate final, o telefone com a data de atualização mais recente (`data_atualizacao`) é considerado o mais relevante.

Essa lógica é implementada no modelo `int_pessoa_fisica_dim_telefone` e garante que o telefone principal selecionado seja sempre o mais promissor para uma comunicação efetiva.

## Resultado Final

- rmi_dados_metres.pessoa_fisica adicionar nos telefones as categorias:
  - confianca_propriedade  -- nível de confiança de que o número pertence ou é usado pela pessoa
  - qualidade_numero       -- avaliação técnica do número: válido, suspeito ou inválido
  - estrategia_envio -- coluna com o resultado da matriz de decisão (ex: 'ENVIAR', 'TESTAR', 'EVITAR', 'NÃO ENVIAR')
  - tipo_telefone -- ['CELULAR', 'FIXO']
- rmi_dados_mestres.telefone
  - origem STRING: sistema ou fonte original do telefone
  - sistema STRING: nome do sistema de origem do dado
  - ddi STRING: código do país (Discagem Direta Internacional)
  - ddd STRING: código de área (Discagem Direta à Distância)
  - numero STRING: número do telefone sem DDI/DDD
  - numero_completo STRING: número completo com DDI e DDD
  - tipo_telefone STRING: tipo do telefone, valores possíveis ['CELULAR', 'FIXO']
  - id_propritario STRING: identificador do proprietário do número, valores possíveis ['cpf', 'cnpj']
  - qualidade_numero STRING: avaliação técnica do número, valores possíveis ['VALIDO', 'SUSPEITO', 'INVALIDO']
  - confianca_propriedade STRING: nível de confiança de que o número pertence ou é usado pela pessoa, valores possíveis ['CONFIRMADA', 'MUITO_PROVAVEL', 'PROVAVEL', 'POUCO_PROVAVEL', 'IMPROVAVEL']
  - estrategia_envio STRING: estratégia recomendada para envio de comunicação, conforme matriz de decisão

Processo:
- qualidade_numero
  - criar macro de qualidade do numero --> retonar VALIDO, SUSPEITO e INVALIDO
    - criar tabela com frequencia de numeros [ephemeral]
    - criar referencia com todos os DDIs e DDDs e regras de validação de numeros brasileiros
    - Criar tabela de estabelecimentos  Numero governamental vindo da tabela de estabelecimentos [OPCIONAL]

- tipo_telefone
  - macro que identifica o tipo de telefone

- confianca_propriedade
  - tabela de validações do app da prefeitura
  - rmi_conversas.chatbot
    - houve_resposta
    - resposta_automatica BOOL
    - pedido_optout BOOL -- pede para SAIR
    - confirmacao_identidade: STRING  // valores possíveis: 'CONFIRMOU', 'NEGOU', 'NEUTRO' — usuário explicitamente confirmou, negou, foi neutro ou não respondeu sobre ser o titular do número
  - rmi_dados_metres.pessoa_fisica
    - fonte do numero
    - data de atualização do cadastro
  - rmi_dados_metres.sistemas
    - nome do sistema
    - orgao que mantém
    - confianca na qualidade