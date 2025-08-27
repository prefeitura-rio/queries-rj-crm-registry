# Mapeamento de Fontes: Divisões Administrativas

## Visão Geral

Este documento detalha como os dados das tabelas existentes em `rj-escritorio-dev.dados_mestres` devem ser mapeados para a estrutura unificada de `divisoes_administrativas`.

## 1. Tabela: `bairro`

### Campos de Origem → Destino

```sql
-- BAIRRO: Mapeamento para tipo_divisao = 'BAIRRO'
SELECT 
    CONCAT('bairro_', id_bairro) as id_divisao,
    'BAIRRO' as tipo_divisao,
    id_bairro as codigo_original,
    nome as nome,
    NULL as nome_abreviado,
    'IPP' as orgao_responsavel,
    ['gestao_territorial', 'servicos_locais'] as competencias,
    NULL as data_criacao,
    NULL as legislacao_base,
    area as area_m2,
    perimetro as perimetro_m,
    ST_Y(ST_CENTROID(geometry)) as centroide_latitude,
    ST_X(ST_CENTROID(geometry)) as centroide_longitude,
    geometry,
    geometry_wkt,
    NULL as densidade_populacional,
    NULL as uso_solo_predominante,
    [] as restricoes_urbanisticas,
    [] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'codigo_bairro', id_bairro,
        'caracteristicas_urbanas', NULL
    ) as atributos_especificos,
    JSON_OBJECT(
        'tabela_origem', 'bairro',
        'id_area_planejamento', id_area_planejamento,
        'nome_regiao_planejamento', nome_regiao_planejamento,
        'id_regiao_administrativa', id_regiao_administrativa,
        'nome_regiao_administrativa', nome_regiao_administrativa,
        'subprefeitura', subprefeitura
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.bairro' as fonte_dados,
    '1.0' as versao_schema
FROM `rj-escritorio-dev.dados_mestres.bairro`
```

### Divisões Derivadas dos Dados de Bairro

A partir dos dados de `bairro`, também criamos outras divisões administrativas:

```sql
-- MUNICIPIO
SELECT 
    'municipio_rio_de_janeiro' as id_divisao,
    'MUNICIPIO' as tipo_divisao,
    '33001' as codigo_original, -- Código IBGE do Rio de Janeiro
    'Rio de Janeiro' as nome,
    'RJ' as nome_abreviado,
    'PCRJ' as orgao_responsavel,
    ['administracao_municipal'] as competencias,
    -- ... outros campos
```

```sql
-- AREA_PLANEJAMENTO
SELECT DISTINCT
    CONCAT('ap_', id_area_planejamento) as id_divisao,
    'AREA_PLANEJAMENTO' as tipo_divisao,
    id_area_planejamento as codigo_original,
    CONCAT('AP', id_area_planejamento, ' - ', 
           FIRST_VALUE(nome_regiao_planejamento) OVER (
               PARTITION BY id_area_planejamento ORDER BY nome_regiao_planejamento)) as nome,
    CONCAT('AP', id_area_planejamento) as nome_abreviado,
    'IPP' as orgao_responsavel,
    -- ... outros campos
FROM `rj-escritorio-dev.dados_mestres.bairro`
```

## 2. Tabela: `subprefeitura`

```sql
-- SUBPREFEITURA
SELECT 
    CONCAT('subpref_', REPLACE(LOWER(subprefeitura), ' ', '_')) as id_divisao,
    'SUBPREFEITURA' as tipo_divisao,
    subprefeitura as codigo_original,
    subprefeitura as nome,
    NULL as nome_abreviado,
    'SUBGAB' as orgao_responsavel,
    ['administracao_regional', 'servicos_publicos_locais'] as competencias,
    NULL as data_criacao,
    NULL as legislacao_base,
    area as area_m2,
    perimetro as perimetro_m,
    ST_Y(ST_CENTROID(geometria)) as centroide_latitude,
    ST_X(ST_CENTROID(geometria)) as centroide_longitude,
    geometria as geometry,
    geometry_wkt,
    NULL as densidade_populacional,
    NULL as uso_solo_predominante,
    [] as restricoes_urbanisticas,
    [] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'endereco_sede', NULL,
        'telefone_contato', NULL,
        'email_contato', NULL,
        'horario_funcionamento', NULL
    ) as atributos_especificos,
    JSON_OBJECT(
        'tabela_origem', 'subprefeitura'
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.subprefeitura' as fonte_dados,
    '1.0' as versao_schema
FROM `rj-escritorio-dev.dados_mestres.subprefeitura`
```

## 3. Tabela: `cres`

```sql
-- CRE (Coordenadorias Regionais de Educação)
SELECT 
    CONCAT('cre_', id) as id_divisao,
    'CRE' as tipo_divisao,
    id as codigo_original,
    nome as nome,
    CONCAT('CRE ', id) as nome_abreviado,
    'SME' as orgao_responsavel,
    ['coordenacao_educacional', 'gestao_escolar'] as competencias,
    NULL as data_criacao,
    NULL as legislacao_base,
    ST_AREA(geometry) as area_m2,
    ST_PERIMETER(geometry) as perimetro_m,
    ST_Y(ST_CENTROID(geometry)) as centroide_latitude,
    ST_X(ST_CENTROID(geometry)) as centroide_longitude,
    geometry,
    geometry_wkt,
    NULL as densidade_populacional,
    'educacional' as uso_solo_predominante,
    [] as restricoes_urbanisticas,
    [] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'numero_escolas', NULL,
        'numero_alunos', NULL,
        'coordenador_regional', NULL
    ) as atributos_especificos,
    JSON_OBJECT(
        'tabela_origem', 'cres'
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.cres' as fonte_dados,
    '1.0' as versao_schema
FROM `rj-escritorio-dev.dados_mestres.cres`
```

## 4. Tabela: `aeis`

```sql
-- AEIS (Áreas de Especial Interesse Social)
SELECT 
    CONCAT('aeis_', id_aeis) as id_divisao,
    'AEIS' as tipo_divisao,
    id_aeis as codigo_original,
    nome_aeis as nome,
    nome_sigla as nome_abreviado,
    'SMU' as orgao_responsavel,
    ['habitacao_social', 'regularizacao_fundiaria'] as competencias,
    data_cadastro as data_criacao,
    legislacao as legislacao_base,
    SAFE_CAST(area AS FLOAT64) as area_m2,
    SAFE_CAST(comprimento AS FLOAT64) as perimetro_m,
    ST_Y(ST_CENTROID(geometry)) as centroide_latitude,
    ST_X(ST_CENTROID(geometry)) as centroide_longitude,
    geometry,
    geometria_wkt as geometry_wkt,
    NULL as densidade_populacional,
    'habitacao_social' as uso_solo_predominante,
    ARRAY[tipologia] as restricoes_urbanisticas,
    ARRAY['AEIS'] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'tipologia_aeis', tipologia,
        'item', item,
        'nome_setor', nome_setor,
        'nome_ar', nome_ar,
        'planta_cadastral', planta_cadastral,
        'projeto_loteamento', projeto_loteamento,
        'referencia', referencia,
        'limite_pavimentos_permitido', limite_pavimentos_permitido,
        'taxa_ocupacao', taxa_ocupacao,
        'indice_aproveitamento_terreno', indice_aproveitamento_terreno,
        'coeficiente_adensamento', coeficiente_adensamento,
        'afastamento', afastamento,
        'situacao_regularizacao', NULL,
        'projeto_urbanizacao', NULL,
        'legislacao_especifica', legislacao
    ) as atributos_especificos,
    JSON_OBJECT(
        'tabela_origem', 'aeis',
        'nome_regiao_administrativa', nome_regiao_administrativa
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.aeis' as fonte_dados,
    '1.0' as versao_schema
FROM `rj-escritorio-dev.dados_mestres.aeis`
```

## 5. Outras Tabelas de Zoneamento

### `zoneamento_urbano`
```sql
-- Exemplo para zoneamento urbano (estrutura a ser definida)
SELECT 
    CONCAT('zona_', codigo_zona) as id_divisao,
    'ZONA_PLANEJAMENTO_URBANO' as tipo_divisao,
    -- ... mapeamento específico
FROM `rj-escritorio-dev.dados_mestres.zoneamento_urbano`
```

## Consultas de Relacionamento Espacial

### 1. Identificar Sobreposições entre Divisões
```sql
-- Encontrar intersecções entre diferentes tipos de divisão
CREATE OR REPLACE TABLE `temp.divisoes_intersecoes` AS
SELECT 
    d1.id_divisao as divisao_1,
    d1.tipo_divisao as tipo_1,
    d1.nome as nome_1,
    d2.id_divisao as divisao_2,
    d2.tipo_divisao as tipo_2,
    d2.nome as nome_2,
    ST_AREA(ST_INTERSECTION(d1.geometry, d2.geometry)) as area_intersecao_m2,
    ST_AREA(ST_INTERSECTION(d1.geometry, d2.geometry)) / ST_AREA(d1.geometry) as percentual_sobreposicao
FROM divisoes_administrativas d1
JOIN divisoes_administrativas d2 ON ST_INTERSECTS(d1.geometry, d2.geometry)
WHERE d1.id_divisao != d2.id_divisao
AND d1.tipo_divisao != d2.tipo_divisao;
```

### 2. Mapear AEIS por Bairro
```sql
-- Identificar quais AEIS estão em cada bairro
CREATE OR REPLACE TABLE `temp.aeis_por_bairro` AS
SELECT 
    b.id_divisao as id_bairro,
    b.nome as nome_bairro,
    a.id_divisao as id_aeis,
    a.nome as nome_aeis,
    ST_AREA(ST_INTERSECTION(a.geometry, b.geometry)) / ST_AREA(a.geometry) as percentual_aeis_no_bairro
FROM divisoes_administrativas a
JOIN divisoes_administrativas b ON ST_INTERSECTS(a.geometry, b.geometry)
WHERE a.tipo_divisao = 'AEIS' 
AND b.tipo_divisao = 'BAIRRO'
AND ST_AREA(ST_INTERSECTION(a.geometry, b.geometry)) / ST_AREA(a.geometry) > 0.1; -- Pelo menos 10% de sobreposição
```

## Validações Pós-Migração

### 1. Integridade dos Dados
```sql
-- Verificar divisões sem nome ou geometria
SELECT tipo_divisao, COUNT(*) as total,
       COUNT(nome) as com_nome,
       COUNT(geometry) as com_geometria
FROM divisoes_administrativas 
GROUP BY tipo_divisao;
```

### 2. Consistência Geográfica
```sql
-- Verificar geometrias válidas
SELECT tipo_divisao, 
       COUNT(*) as total,
       COUNT(CASE WHEN ST_ISVALID(geometry) THEN 1 END) as geometrias_validas
FROM divisoes_administrativas
WHERE geometry IS NOT NULL
GROUP BY tipo_divisao;
```

### 3. Completude dos Dados
```sql
-- Verificar campos obrigatórios
SELECT 
    tipo_divisao,
    COUNT(*) as total,
    COUNT(nome) as com_nome,
    COUNT(geometry) as com_geometry
FROM divisoes_administrativas
GROUP BY tipo_divisao;
```