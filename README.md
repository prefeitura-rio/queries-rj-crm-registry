# Queries RJ CRM Registry

Sistema de dados mestres para o CRM da Prefeitura do Rio de Janeiro, construído com dbt e BigQuery.

## Visão Geral

Este projeto implementa um data warehouse seguindo a arquitetura medallion (raw → intermediate → core/marts) para consolidar dados de cidadãos e entidades do município do Rio de Janeiro. O sistema integra dados de múltiplas secretarias e sistemas municipais para criar uma visão unificada dos dados mestres.

## Arquitetura

### Camadas de Dados

- **Raw (`models/raw/`)**: Dados brutos das fontes originais
- **Intermediate (`models/intermediate/`)**: Transformações e limpezas intermediárias
- **Core (`models/core/`)**: Entidades de negócio principais (dimensões e fatos)
- **Marts (`models/marts/`)**: Dados organizados por área de negócio

### Principais Entidades

- **`dim_pessoa_fisica`**: Dados consolidados de pessoas físicas
- **`dim_pessoa_juridica`**: Dados de pessoas jurídicas
- **`dim_endereco_geolocalizado`**: Informações de endereços com geolocalização
- **WhatsApp**: Modelos para gestão de comunicação via WhatsApp

## Configuração do Ambiente

### Pré-requisitos

- Python 3.12+
- Acesso ao BigQuery
- Credenciais de serviço configuradas

### Instalação

```bash
# Clone o repositório
git clone <repository-url>
cd queries-rj-crm-registry

# Instale as dependências
uv sync

# Ative o ambiente virtual
source .venv/bin/activate
```

### Configuração do dbt

Configure suas credenciais do BigQuery no arquivo `profiles.yml` ou através de variáveis de ambiente:

```bash
export DBT_USER="seu_usuario"
```

## Uso

### Comandos Básicos

```bash
# Executar todos os modelos
dbt run

# Executar testes
dbt test

# Gerar documentação
dbt docs generate
dbt docs serve

# Formatar código SQL
sqlfmt models/ macros/
```

### Desenvolvimento

```bash
# Executar modelo específico com dependências
dbt run --select +nome_do_modelo

# Executar modelo e dependentes
dbt run --select nome_do_modelo+

# Testar modelo específico
dbt test --select nome_do_modelo

# Compilar sem executar (útil para debug)
dbt compile
```

## Fontes de Dados

### Principais Sistemas

- **Bcadastro**: Cadastro de cidadãos
- **SMS (rj-sms)**: Dados da Secretaria Municipal de Saúde
- **SMAS (rj-smas)**: Dados da Secretaria Municipal de Assistência Social
- **Wetalkie**: Plataforma de comunicação
- **Dados Mestres**: Tabelas de referência
- **Diversas Secretarias**: Transportes, Fazenda, Governo e Integridade

### Integração de Dados

O sistema integra dados usando:
- CPF como chave principal para pessoas físicas
- CNPJ para pessoas jurídicas
- Validação através de macros específicas (`validate_cpf`, `validade_cns`)
- Padronização de dados (CEP, telefone, nomes)

## Convenções

### Nomenclatura de Modelos

- Raw: `raw_{sistema_origem}_{tabela}`
- Intermediate: `int_{dominio}_{proposito}`
- Dimensões: `dim_{entidade}`
- Fatos: `fct_{processo}`
- Marts: `mart_{area_negocio}_{proposito}`

### Nomenclatura de Colunas

Padrão: `[id_][<entidade>_]<dimensão>[_<unidade>]`

Sufixos importantes:
- `_nome`: Nomes ou descrições
- `_data`: Valores de data
- `_datahora`: Timestamps
- `_valor`: Valores monetários/numéricos
- `_quantidade`: Contagens
- `_indicador`: Flags booleanos

### Testes

Convenção de nomenclatura: `{camada}_{dataset}_{tabela}__{coluna}__{teste}`

Exemplo:
```yaml
data_tests:
  - unique:
      name: dim_pessoa_fisica__cpf__unique
```

## Macros Utilitárias

O projeto inclui macros personalizadas:

- `validate_cpf()`: Validação de CPF seguindo regras brasileiras
- `calculate_age()`: Cálculo de idade
- `clean_name_string()`: Padronização de nomes
- `padronize_cep()`: Padronização de CEP
- `padronize_telefone()`: Padronização de telefone
- `remove_accents_upper()`: Normalização de texto

## Estrutura do Projeto

```
queries-rj-crm-registry/
├── analyses/           # Análises ad-hoc
├── data-tests/         # Testes customizados
├── macros/            # Macros e funções reutilizáveis
├── models/
│   ├── raw/           # Dados brutos por sistema origem
│   ├── intermediate/  # Transformações intermediárias
│   ├── core/          # Entidades core (dimensões/fatos)
│   └── marts/         # Marts por área de negócio
├── seeds/             # Dados de referência (CSV)
└── snapshots/         # Snapshots para SCD
```

## Qualidade dos Dados

### Testes Obrigatórios

Todo modelo deve ter:
1. Testes de chave primária (unique + not_null)
2. Testes de chave estrangeira quando aplicável
3. Testes de regras de negócio específicas

### Validações Específicas

- Validação de CPF/CNPJ através de macros
- Testes de formato para CEP, telefone, email
- Validação de intervalos de datas e valores
- Verificação de integridade referencial

## Ambientes

- **dev**: Desenvolvimento local/individual
- **staging**: Testes e validação
- **prod**: Produção

Cada ambiente usa projetos BigQuery separados configurados no `profiles.yml`.

## Contribuição

1. Siga as convenções de nomenclatura estabelecidas
2. Inclua testes para novos modelos
3. Documente colunas nos arquivos YAML
4. Use comentários em português brasileiro
5. Execute `sqlfmt` antes de commitar
6. Mantenha a documentação atualizada

## Suporte

Para dúvidas técnicas ou problemas com o projeto, consulte:
- A documentação do dbt: `dbt docs serve`
- O arquivo CLAUDE.md para diretrizes específicas
- As regras do Cursor em `.cursor/rules/`