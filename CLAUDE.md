# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dbt project for the Rio de Janeiro City Hall's CRM Registry data warehouse. The project follows a medallion architecture pattern (raw → intermediate → core/marts) and uses BigQuery as the data warehouse platform.

## Common Commands

### Environment Setup
```bash
# Install dependencies
uv sync

# Activate virtual environment (if using uv)
source .venv/bin/activate
```

### dbt Operations
```bash
# Run all models
dbt run

# Run specific model and its dependencies
dbt run --select +model_name

# Run models downstream from a specific model
dbt run --select model_name+

# Run tests
dbt test

# Run tests for a specific model
dbt test --select model_name

# Compile models (useful for debugging)
dbt compile

# Generate documentation
dbt docs generate
dbt docs serve

# Clean target directory
dbt clean

# Debug connection
dbt debug
```

### SQL Formatting
```bash
# Format SQL files using sqlfmt
sqlfmt models/ macros/

# Format with jinja support
sqlfmt --jinja models/ macros/
```

## Project Architecture

### Directory Structure
- `models/raw/` - Raw data models that reference source tables
- `models/intermediate/` - Intermediate models for data transformations (materialized as ephemeral)
- `models/core/` - Core business entities (dimensions and facts, materialized as tables)
- `models/marts/` - Business-specific data marts
- `macros/` - Reusable SQL functions and utilities
- `data-tests/` - Custom data quality tests
- `seeds/` - Static reference data (CSV files)

### Model Naming Conventions
- Raw models: `raw_{source_system}_{table_name}`
- Intermediate models: `int_{business_domain}_{purpose}`
- Dimension tables: `dim_{entity_name}`
- Fact tables: `fct_{process_name}`
- Marts: `mart_{business_area}_{purpose}`

### Column Naming Standards
Follow the pattern: `[id_][<entidade>_]<dimensão>[_<unidade>]`

Key suffixes:
- `_nome` - Names or descriptions
- `_data` - Date values
- `_datahora` - Timestamp values
- `_valor` - Monetary/numeric values
- `_quantidade` - Counts or quantities
- `_indicador` - Boolean flags
- `_tipo` - Categorical types
- `_sigla` - Acronyms or codes

### Data Sources
Main source systems include:
- `bcadastro` - Citizen registry data
- `rj-sms` - Health department data (SMS)
- `rj-smas` - Social assistance data (SMAS)
- `wetalkie` - Communication platform data
- `secretaria_*` - Various city department data

## Key Macros

The project includes several custom macros in the `macros/` directory:
- `validate_cpf(cpf_column)` - CPF validation using Brazilian rules
- `calculate_age()` - Age calculation utilities
- `clean_name_string()` - Name standardization
- `padronize_cep()` - CEP (postal code) standardization
- `padronize_telefone()` - Phone number standardization
- `remove_accents_upper()` - Text normalization

## Testing Standards

### Test Naming Convention
All tests follow: `{layer}_{dataset}_{table}__{column}__{test_name}`

Example:
```yaml
data_tests:
  - unique:
      name: dim_pessoa_fisica__cpf__unique
  - not_null:
      name: dim_pessoa_fisica__cpf__not_null
```

### Required Tests
Every model should have:
1. Primary key tests (unique + not_null)
2. Foreign key relationship tests where applicable
3. Business logic validation tests

## Configuration Details

- **Profile**: `crm` (defined in profiles.yml)
- **Target Environments**: dev, staging, prod
- **Data Warehouse**: BigQuery
- **Default Materialization**: 
  - Raw: table
  - Intermediate: ephemeral
  - Core: table
- **Partitioning**: Models use integer partitioning on CPF for performance

## Development Guidelines

1. **SQL Style**: Use CTEs with descriptive Portuguese names, 2-4 space indentation
2. **Comments**: Write comments in Brazilian Portuguese only
3. **Sources**: Use `{{ source() }}` for raw tables, `{{ ref() }}` for models
4. **Configuration**: Always include config blocks with alias and schema
5. **Documentation**: Each model should have a corresponding YAML file with column descriptions
6. **BigQuery Specific**: Use BigQuery-compatible functions only, consider JSON handling patterns

## Person Data Model (Core Entity)

The central entity is `dim_pessoa_fisica` which consolidates citizen data from multiple sources:
- Personal information (name, birth date, documents)
- Address and geolocation data
- Health system records (SMS)
- Social assistance records (SMAS)
- Municipal registry (Bcadastro)

This model is partitioned by CPF for optimal query performance and follows strict data quality standards with comprehensive testing.