# AI Procedures Documentation

This directory contains machine-readable procedures designed specifically for AI systems to perform data integration tasks systematically and consistently.

## 🎯 Purpose

These procedures are optimized for **AI consumption**, not human readability. They provide:
- **Executable commands** with specific parameters
- **Decision matrices** with numerical thresholds
- **Template-driven code generation** for consistency
- **Validation criteria** with boolean/numeric success conditions

## 📁 Directory Structure

```
docs/ai-procedures/
├── data-integration/           # Core integration procedures
│   └── phone-data-integration.yaml
├── data-quality/              # Quality validation rules
│   └── phone-validation-rules.yaml
├── investigation/             # Database discovery procedures
│   └── database-schema-discovery.yaml
├── templates/                 # Reusable code templates
│   └── dbt-integration-template.yaml
└── README.md                  # This file
```

## 🤖 AI Usage Instructions

### For Phone Data Integration

1. **Start with discovery**:
   ```yaml
   procedure: investigation/database-schema-discovery.yaml
   target: identify phone data sources
   ```

2. **Analyze integration feasibility**:
   ```yaml
   procedure: data-integration/phone-data-integration.yaml
   section: investigation_steps
   ```

3. **Implement using templates**:
   ```yaml
   procedure: templates/dbt-integration-template.yaml
   pattern: select appropriate template based on source structure
   ```

4. **Validate quality**:
   ```yaml
   procedure: data-quality/phone-validation-rules.yaml
   section: quality_expectations
   ```

### Decision Framework

Each procedure includes `ai_metadata` sections with:
- **decision_points**: Algorithmic decision trees
- **automation_level**: How much can be automated
- **human_review_required**: When to escalate

## 📋 Core Procedures

### 1. Phone Data Integration (`data-integration/phone-data-integration.yaml`)

**Purpose**: End-to-end procedure for integrating phone data from any source system.

**Key Sections**:
- `investigation_steps`: Systematic source analysis
- `decision_matrix`: Quality and integration approach decisions
- `implementation_template`: dbt code generation
- `validation_checklist`: Success criteria
- `quality_analysis`: Expected outcomes

**AI Usage**: Follow step-by-step investigation → decision → implementation → validation flow.

### 2. Phone Validation Rules (`data-quality/phone-validation-rules.yaml`)

**Purpose**: Comprehensive quality classification system (VALIDO/SUSPEITO/INVALIDO).

**Key Sections**:
- `format_validation`: Brazilian phone format rules
- `frequency_validation`: Ownership frequency thresholds
- `suspicious_patterns`: Pattern detection logic
- `quality_expectations`: Expected quality by source type

**AI Usage**: Apply validation rules consistently across all phone integrations.

### 3. Database Schema Discovery (`investigation/database-schema-discovery.yaml`)

**Purpose**: Systematic database exploration to identify integration opportunities.

**Key Sections**:
- `database_exploration`: General discovery framework
- `phone_data_discovery`: Phone-specific search patterns
- `person_id_discovery`: Identifier column discovery
- `integration_readiness`: Feasibility assessment

**AI Usage**: Use for initial exploration of unknown data sources.

### 4. dbt Integration Templates (`templates/dbt-integration-template.yaml`)

**Purpose**: Reusable code templates for consistent dbt model implementation.

**Key Sections**:
- `integration_templates`: Code generation patterns
- `id_processing_patterns`: Standardization logic
- `union_integration`: UNION ALL patterns
- `test_configuration`: Test updates required

**AI Usage**: Select appropriate template and substitute variables for code generation.

## 🔧 Template Usage

### Variable Substitution Pattern

Templates use `{variable_name}` placeholders:

```yaml
# Template
concat('55', {{ padronize_telefone('{phone_field}') }})

# Substitution
phone_field: "e.celular"

# Result
concat('55', {{ padronize_telefone('e.celular') }})
```

### Common Variables

- `{source_name}`: System identifier (e.g., 'ergon', 'sms')
- `{id_processing}`: ID standardization logic
- `{origem_tipo}`: ID type ('CPF', 'CNPJ', 'CNS')
- `{context}`: Business context ('PESSOAL', 'FUNCIONAL', etc.)
- `{phone_field}`: Source phone column name

## 📊 Quality Standards

### Expected Outcomes by Source Type

**Government Registries (BCadastro)**:
- VALIDO: >95%
- INVALIDO: <3%
- Reasoning: High-quality official data

**Administrative Systems (ERGON)**:
- VALIDO: 60-70%
- INVALIDO: 25-35%
- Reasoning: Format limitations (missing DDDs)

**Health Systems (SMS)**:
- VALIDO: >90%
- INVALIDO: <8%
- Reasoning: Validated patient data

## ⚠️ Critical Decision Rules

### Data Integrity Priority

**Rule**: Never assume missing data (e.g., don't add fictional DDDs)
**Implementation**: Maintain original data format even if it results in higher INVALIDO percentages
**Reasoning**: Data integrity > artificial metric improvement

### Format Validation

**Rule**: Accept 12-14 digit Brazilian phones (landlines + mobile)
**Implementation**: `length({phone}) in (12, 13, 14)`
**Reasoning**: Include valid landlines (12 digits)

### Frequency-Based Quality

**Rule**: High-frequency phones (16+ owners) are likely service numbers
**Implementation**: Mark as INVALIDO regardless of format
**Reasoning**: Practical usability for contact purposes

## 🔄 Validation Workflow

1. **Compilation Check**: `dbt compile --select {model}`
2. **Record Count Validation**: Verify reasonable record volumes
3. **Test Execution**: Run dbt tests with >90% pass rate
4. **Quality Analysis**: Check VALIDO/INVALIDO distribution
5. **Business Logic Validation**: Verify consistency rules

## 🚨 Error Handling

### Common Issues and Solutions

**UNION Type Mismatch**:
- Symptom: "Column X has incompatible types"
- Solution: Add explicit casting `cast({column} as string)`

**Source Not Found**:
- Symptom: "Table X not found"
- Solution: Verify source configuration in `_raw_*.yml`

**High INVALIDO Rate**:
- Investigation: Check length distribution and format patterns
- Solution: Assess if source limitation vs. validation issue

## 🔍 Debugging Procedures

### Investigation Queries

**Length Distribution Analysis**:
```sql
SELECT LENGTH(telefone_numero_completo) as length,
       COUNT(*) as count,
       MIN(telefone_numero_completo) as example
FROM {table} GROUP BY LENGTH(telefone_numero_completo)
ORDER BY count DESC
```

**Quality Distribution Check**:
```sql
SELECT telefone_qualidade, COUNT(*) as count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percent
FROM {rmi_table} GROUP BY telefone_qualidade
ORDER BY count DESC
```

## 📈 Success Metrics

### Integration Success Criteria

- ✅ Model compiles without errors
- ✅ Tests pass with >90% success rate
- ✅ Quality distribution within expected ranges
- ✅ Business logic consistency maintained
- ✅ Data lineage properly tracked

### Quality Success Criteria

- ✅ VALIDO percentage appropriate for source type
- ✅ INVALIDO reasons documented and understood
- ✅ No data corruption introduced
- ✅ Consistent schema compliance
- ✅ Performance within acceptable limits

## 📝 Documentation Requirements

For each integration, document:
1. **Source Analysis**: Data structure and quality findings
2. **Integration Approach**: Template used and customizations
3. **Quality Results**: VALIDO/INVALIDO distribution with explanations
4. **Limitations**: Known data quality issues
5. **Business Impact**: Usability assessment for contact purposes

## 🔄 Version Control

**Current Version**: 1.0.0
**Based On**: ERGON telefones integration case study
**Last Updated**: 2025-01-08

**Update Protocol**: When procedures are modified based on new integration experiences, increment version and document changes in procedure files.

## 🎯 AI Optimization Notes

These procedures are designed for:
- **Systematic execution** by AI systems
- **Consistent decision-making** across integrations
- **Reproducible results** with minimal human intervention
- **Quality preservation** through automated validation
- **Scalable patterns** for future data sources

The procedures encode institutional knowledge from successful integrations, enabling AI systems to replicate expert-level data integration practices autonomously.