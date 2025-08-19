# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a dbt project for the Rio de Janeiro City Hall's CRM Registry data warehouse. The project follows a medallion architecture pattern (raw → intermediate → core/marts) and uses BigQuery as the data warehouse platform.

## Common Commands

### Environment Setup
```bash
# Install dependencies
uv sync

# Load environment variables from ~/.zshrc
source ~/.zshrc

# Activate virtual environment (if using uv)
source .venv/bin/activate
```

### dbt Operations
```bash
# Load environment variables and run all models
source ~/.zshrc && source .venv/bin/activate && dbt run

# Run specific model and its dependencies
source ~/.zshrc && source .venv/bin/activate && dbt run --select +model_name

# Run models downstream from a specific model
source ~/.zshrc && source .venv/bin/activate && dbt run --select model_name+

# Run tests
source ~/.zshrc && source .venv/bin/activate && dbt test

# Run tests for a specific model
source ~/.zshrc && source .venv/bin/activate && dbt test --select model_name

# Compile models (useful for debugging)
source ~/.zshrc && source .venv/bin/activate && dbt compile

# Generate documentation
source ~/.zshrc && source .venv/bin/activate && dbt docs generate
source ~/.zshrc && source .venv/bin/activate && dbt docs serve

# Clean target directory
source ~/.zshrc && source .venv/bin/activate && dbt clean

# Debug connection
source ~/.zshrc && source .venv/bin/activate && dbt debug
```

### SQL Formatting
```bash
# Format SQL files using sqlfmt
source ~/.zshrc && source .venv/bin/activate && sqlfmt models/ macros/

# Format with jinja support
source ~/.zshrc && source .venv/bin/activate && sqlfmt --jinja models/ macros/
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

## Using the Ontology for Intermediate (`int_`) Table Creation

When creating new intermediate (`int_`) models for the facts layer, follow the **Ontology of Citizen-Government Interactions** documented in the `analyses/ontology/rmi_eventos/interacoes_pessoa_fisica_prefeitura/` folder. This ontology standardizes how different source systems are transformed into the unified fact table.

### Key References:
- **Ontology Overview**: `analyses/ontology/rmi_eventos/interacoes_pessoa_fisica_prefeitura/README.md` - Complete schema and concepts
- **Schema Definition**: `analyses/ontology/rmi_eventos/interacoes_pessoa_fisica_prefeitura/fact_schema.md` - 21-field structure specification
- **Implementation Examples**: 
  - `models/intermediate/facts/int_interacoes_1746.sql` - 1746 system mapping
  - `models/intermediate/facts/int_interacoes_sms.sql` - Health system mapping

Use the Profiling Scripts to understand the data.

### Essential Pattern:
All `int_` models must output the standardized 21-field schema covering identification, origin, classification (tipo/categoria/subcategoria), channel, temporal, location, result, and flexible data fields. Use the existing models as templates and refer to the ontology documentation for the latest field definitions and mapping rules.

## Data Profiling and Test Troubleshooting Pipeline

The project includes data profiling scripts in `analyses/profile/` to help diagnose and solve test failures systematically.

### Profiling Scripts
- `analyses/profile/scripts/get_schema.sh <table_name>` - Extract table schema and column metadata
- `analyses/profile/scripts/get_column_details.sh <table_name> <column_name>` - Analyze column distribution and statistics

### Test Troubleshooting Workflow

When encountering test failures, follow this systematic approach:

1. **Run the failing model tests**:
   ```bash
   source ~/.zshrc && source .venv/bin/activate && dbt test --select model_name
   ```

2. **Profile the table schema**:
   ```bash
   cd analyses/profile/scripts && ./get_schema.sh your_schema.your_table_name
   ```
   This generates `analyses/profile/results/your_table_name/schema.csv` with column metadata.

3. **Analyze categorical columns with issues**:
   ```bash
   cd analyses/profile/scripts && ./get_column_details.sh your_schema.your_table_name column_name
   ```
   This generates:
   - `analyses/profile/results/your_table_name/column_name_stats.csv` - Statistical summary
   - `analyses/profile/results/your_table_name/column_name_categories.csv` - Value frequencies

4. **Common test failure patterns and solutions**:

   **Accepted Values Test Failures**:
   - Use `get_column_details.sh` to see actual values vs expected
   - Update `.yml` accepted values based on real data distribution
   - Consider if new categories indicate data quality issues or legitimate new values

   **Uniqueness Test Failures**:
   - Check for duplicate generation logic (e.g., UUID conflicts)
   - Analyze duplicate patterns in the categories file
   - Fix source data joins or key generation logic

   **Regex/Pattern Test Failures**:
   - Use column details to see actual data patterns
   - Simplify complex regex tests if data is too varied
   - Consider data cleaning in the model vs strict validation

   **Business Logic Test Failures**:
   - Profile related columns to understand data relationships
   - Check if business rules need updating based on real data patterns
   - Consider temporal changes in data patterns

5. **Iterative improvement**:
   - Make model or test adjustments based on profiling insights
   - Re-run tests to validate fixes
   - Use profiling to track categorization coverage improvements (e.g., reducing "OUTROS" categories)

### Example: Categorical Coverage Optimization

For models with categorical mappings (like interaction types), use this approach:
1. Profile the problematic category column
2. Identify high-frequency unmapped values in "OUTROS" categories  
3. Add specific mapping rules to reduce uncategorized data
4. Target <1% for "OUTROS" categories through iterative refinement
5. Validate with fresh profiling after each iteration

This data-driven approach ensures test fixes are based on actual data patterns rather than assumptions.