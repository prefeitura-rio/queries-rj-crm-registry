# Schema - RMI Dados Mestres: Telefones

## Visão Geral
Este schema define a estrutura para o registro mestre de telefones (RMI - Registro Mestre de Informações) no contexto do CRM Registry da Prefeitura do Rio de Janeiro. O objetivo é consolidar e padronizar informações telefônicas de diferentes sistemas municipais.

## Campos do Schema

### Identificação do Telefone
- **telefone_numero_completo** `STRING`: Número completo formatado com DDI e DDD (ex: "+5521987654321")
- **telefone_ddi** `STRING`: Código do país para Discagem Direta Internacional (ex: "55" para Brasil)
- **telefone_ddd** `STRING`: Código de área para Discagem Direta à Distância, aplicável apenas para números brasileiros (ex: "21")
- **telefone_numero** `STRING`: Número do telefone sem DDI/DDD (ex: "987654321")

### Classificação e Qualidade
- **telefone_tipo** `STRING`: Classificação do tipo de telefone
  - Valores aceitos: `['CELULAR', 'FIXO', 'VOIP', 'OUTROS']`
  - Default: `'OUTROS'` para números não classificados
- **telefone_nacionalidade** `STRING`: País de origem do número telefônico (ex: "Brasil", "Argentina")
- **telefone_qualidade** `STRING`: Avaliação técnica da validade do número
  - Valores aceitos: `['VALIDO', 'SUSPEITO', 'INVALIDO']`
  - `VALIDO`: Número validado e funcional
  - `SUSPEITO`: Número com padrão válido mas não confirmado
  - `INVALIDO`: Número com padrão inválido ou reconhecidamente inativo

### Metadados de Origem
- **telefone_aparicoes** `ARRAY<STRUCT>`: Lista de aparições do telefone em diferentes sistemas
  - **sistema_nome** `STRING`: Nome do sistema de origem do dado
  - **proprietario_id** `STRING`: CPF ou CNPJ do proprietário do telefone
  - **proprietario_tipo** `STRING`: Tipo do proprietário (`['CPF', 'CNPJ']`)
  - **registro_data_atualizacao** `DATETIME`: Data da última atualização do registro no sistema de origem

### Estatísticas de Consolidação
- **telefone_aparicoes_quantidade** `INT64`: Número total de aparições do telefone em todos os sistemas
- **telefone_proprietarios_quantidade** `INT64`: Número de proprietários únicos associados ao telefone
- **telefone_sistemas_quantidade** `INT64`: Número de sistemas diferentes onde o telefone aparece

### Auditoria e Controle
- **rmi_data_criacao** `DATETIME`: Data de criação do registro no RMI
- **rmi_data_atualizacao** `DATETIME`: Data da última atualização do registro no RMI
- **rmi_versao** `STRING`: Versão do schema utilizada
- **rmi_hash_validacao** `STRING`: Hash para controle de integridade dos dados

