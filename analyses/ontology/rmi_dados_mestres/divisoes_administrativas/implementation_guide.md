# Guia de Implementação: Divisões Administrativas

## Passos para Implementação

### 1. Preparação do Ambiente

#### 1.1 Criar tabela de destino
```sql
CREATE TABLE `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` (
  -- Campos de Identificação
  id_divisao STRING NOT NULL,
  tipo_divisao STRING NOT NULL,
  codigo_original STRING,
  nome STRING NOT NULL,
  nome_abreviado STRING,
  
  
  -- Campos Administrativos
  orgao_responsavel STRING,
  competencias ARRAY<STRING>,
  data_criacao DATE,
  legislacao_base STRING,
  
  -- Campos Geográficos
  area_m2 FLOAT64,
  perimetro_m FLOAT64,
  centroide_latitude FLOAT64,
  centroide_longitude FLOAT64,
  geometry GEOGRAPHY,
  geometry_wkt STRING,
  
  -- Campos de Planejamento Urbano
  densidade_populacional FLOAT64,
  uso_solo_predominante STRING,
  restricoes_urbanisticas ARRAY<STRING>,
  instrumentos_urbanisticos ARRAY<STRING>,
  
  -- Campos Específicos por Tipo
  atributos_especificos JSON,
  metadados_fonte JSON,
  
  -- Campos de Controle
  ativo BOOL DEFAULT TRUE,
  data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  fonte_dados STRING,
  versao_schema STRING DEFAULT '1.0'
)
PARTITION BY tipo_divisao
CLUSTER BY area_m2 DESC, ativo;
```

#### 1.2 Criar índices
```sql
-- Índice principal
CREATE INDEX idx_divisoes_id 
ON `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`(id_divisao);

-- Índice de busca
CREATE INDEX idx_divisoes_busca 
ON `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`(nome, codigo_original);

-- Índice espacial (implícito no BigQuery para campos GEOGRAPHY)
-- Índice por tipo de divisão
CREATE INDEX idx_divisoes_tipo 
ON `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`(tipo_divisao, ativo);
```

### 2. Migração dos Dados

#### 2.1 Script de Migração Principal
```sql
-- Step 1: Insert MUNICIPIO
INSERT INTO `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
SELECT 
    'municipio_rio_de_janeiro' as id_divisao,
    'MUNICIPIO' as tipo_divisao,
    '3304557' as codigo_original,
    'Rio de Janeiro' as nome,
    'RJ' as nome_abreviado,
    'PCRJ' as orgao_responsavel,
    ['administracao_municipal'] as competencias,
    NULL as data_criacao,
    'Lei Orgânica do Município' as legislacao_base,
    1200000000.0 as area_m2, -- Aproximado
    NULL as perimetro_m,
    -22.9068 as centroide_latitude,
    -43.1729 as centroide_longitude,
    NULL as geometry, -- Será adicionado posteriormente
    NULL as geometry_wkt,
    5265.82 as densidade_populacional, -- Censo 2022
    'urbano' as uso_solo_predominante,
    [] as restricoes_urbanisticas,
    [] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'populacao', 6748000,
        'area_km2', 1200,
        'regiao', 'Sudeste',
        'estado', 'Rio de Janeiro'
    ) as atributos_especificos,
    JSON_OBJECT(
        'fonte', 'dados_ibge'
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'dados_ibge' as fonte_dados,
    '1.0' as versao_schema;

-- Step 2: Insert AREA_PLANEJAMENTO (derived from bairro data)
INSERT INTO `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
WITH areas_planejamento AS (
  SELECT DISTINCT
    id_area_planejamento,
    FIRST_VALUE(nome_regiao_planejamento) OVER (
      PARTITION BY id_area_planejamento 
      ORDER BY nome_regiao_planejamento
    ) as primeira_regiao
  FROM `rj-escritorio-dev.dados_mestres.bairro`
)
SELECT 
    CONCAT('ap_', id_area_planejamento) as id_divisao,
    'AREA_PLANEJAMENTO' as tipo_divisao,
    CAST(id_area_planejamento AS STRING) as codigo_original,
    CONCAT('AP', id_area_planejamento) as nome,
    CONCAT('AP', id_area_planejamento) as nome_abreviado,
    'IPP' as orgao_responsavel,
    ['planejamento_territorial'] as competencias,
    NULL as data_criacao,
    'Plano Diretor Municipal' as legislacao_base,
    NULL as area_m2,
    NULL as perimetro_m,
    NULL as centroide_latitude,
    NULL as centroide_longitude,
    NULL as geometry,
    NULL as geometry_wkt,
    NULL as densidade_populacional,
    'misto' as uso_solo_predominante,
    [] as restricoes_urbanisticas,
    ['planejamento_urbano'] as instrumentos_urbanisticos,
    JSON_OBJECT(
        'caracteristicas_socioeconomicas', NULL,
        'diretrizes_planejamento', []
    ) as atributos_especificos,
    JSON_OBJECT(
        'tabela_origem', 'bairro_derived'
    ) as metadados_fonte,
    TRUE as ativo,
    CURRENT_TIMESTAMP() as data_atualizacao,
    'rj-escritorio-dev.dados_mestres.bairro' as fonte_dados,
    '1.0' as versao_schema
FROM areas_planejamento;

-- Continue with other steps...
```

#### 2.2 Script para BAIRROS
```sql
INSERT INTO `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
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
FROM `rj-escritorio-dev.dados_mestres.bairro`;
```

### 3. Validação e Correções

#### 3.1 Scripts de Validação
```sql
-- Validação 1: Completude dos dados
CREATE OR REPLACE TABLE `temp.validacao_completude` AS
SELECT 
    tipo_divisao,
    COUNT(*) as total,
    COUNT(nome) as com_nome,
    COUNT(geometry) as com_geometry,
    COUNT(codigo_original) as com_codigo
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
GROUP BY tipo_divisao
ORDER BY tipo_divisao;

-- Validação 2: Geometrias válidas
SELECT 
    tipo_divisao,
    COUNT(*) as total,
    COUNT(geometry) as com_geometry,
    COUNT(CASE WHEN ST_ISVALID(geometry) THEN 1 END) as geometry_valida
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
WHERE geometry IS NOT NULL
GROUP BY tipo_divisao;

-- Validação 3: Códigos únicos
SELECT 
    tipo_divisao,
    codigo_original,
    COUNT(*) as duplicatas
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
WHERE codigo_original IS NOT NULL
GROUP BY tipo_divisao, codigo_original
HAVING COUNT(*) > 1;
```

#### 3.2 Correções Automáticas
```sql
-- Correção 1: Atualizar geometrias agregadas das áreas de planejamento
UPDATE `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` as ap
SET 
    geometry = (
        SELECT ST_UNION_AGG(b.geometry)
        FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` b
        WHERE b.tipo_divisao = 'BAIRRO'
        AND JSON_EXTRACT_SCALAR(b.metadados_fonte, '$.id_area_planejamento') = 
            REGEXP_EXTRACT(ap.id_divisao, r'ap_(\d+)')
    ),
    area_m2 = (
        SELECT SUM(b.area_m2)
        FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` b
        WHERE b.tipo_divisao = 'BAIRRO'
        AND JSON_EXTRACT_SCALAR(b.metadados_fonte, '$.id_area_planejamento') = 
            REGEXP_EXTRACT(ap.id_divisao, r'ap_(\d+)')
    )
WHERE ap.tipo_divisao = 'AREA_PLANEJAMENTO';

-- Correção 2: Atualizar centroides
UPDATE `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
SET 
    centroide_latitude = ST_Y(ST_CENTROID(geometry)),
    centroide_longitude = ST_X(ST_CENTROID(geometry))
WHERE geometry IS NOT NULL 
AND (centroide_latitude IS NULL OR centroide_longitude IS NULL);

-- Correção 3: Criar tabela de relacionamentos espaciais
CREATE OR REPLACE TABLE `rj-crm-registry.rmi_dados_mestre.divisoes_relacionamentos` AS
SELECT 
    d1.id_divisao as divisao_origem,
    d1.tipo_divisao as tipo_origem,
    d2.id_divisao as divisao_destino, 
    d2.tipo_divisao as tipo_destino,
    'INTERSECTA' as tipo_relacionamento,
    ST_AREA(ST_INTERSECTION(d1.geometry, d2.geometry)) as area_intersecao_m2,
    ST_AREA(ST_INTERSECTION(d1.geometry, d2.geometry)) / ST_AREA(d1.geometry) as percentual_sobreposicao
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` d1
JOIN `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` d2 
  ON ST_INTERSECTS(d1.geometry, d2.geometry)
WHERE d1.id_divisao != d2.id_divisao
AND d1.geometry IS NOT NULL 
AND d2.geometry IS NOT NULL;
```

### 4. Testes de Funcionalidade

#### 4.1 Teste de Relacionamentos Espaciais
```sql
-- Encontrar todas as divisões que intersectam com uma área de planejamento
SELECT 
    d.tipo_divisao,
    d.nome,
    COUNT(*) as quantidade,
    AVG(r.percentual_sobreposicao) as percentual_medio_sobreposicao
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_relacionamentos` r
JOIN `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas` d 
  ON r.divisao_destino = d.id_divisao
WHERE r.divisao_origem = 'ap_1' 
AND r.percentual_sobreposicao > 0.05 -- Pelo menos 5% de sobreposição
GROUP BY d.tipo_divisao, d.nome
ORDER BY d.tipo_divisao;
```

#### 4.2 Teste de Consultas Espaciais
```sql
-- Encontrar divisões que intersectam com um ponto
DECLARE lat FLOAT64 DEFAULT -22.9068;  -- Centro do Rio
DECLARE lng FLOAT64 DEFAULT -43.1729;

SELECT 
    tipo_divisao,
    nome,
    area_m2/1000000 as area_km2
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
WHERE ST_CONTAINS(geometry, ST_GEOGPOINT(lng, lat))
ORDER BY area_m2;
```

### 5. Documentação e Entrega

#### 5.1 Relatório de Implementação
```sql
-- Estatísticas finais da implementação
CREATE OR REPLACE TABLE `rj-crm-registry.reports.divisoes_administrativas_stats` AS
SELECT 
    tipo_divisao,
    COUNT(*) as total_registros,
    COUNT(geometry) as com_geometria,
    ROUND(AVG(area_m2)/1000000, 2) as area_media_km2,
    COUNT(CASE WHEN ativo THEN 1 END) as ativos,
    MIN(data_atualizacao) as primeira_atualizacao,
    MAX(data_atualizacao) as ultima_atualizacao
FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
GROUP BY tipo_divisao
ORDER BY tipo_divisao;
```

#### 5.2 Procedimentos de Manutenção
```sql
-- Procedure para atualização incremental
CREATE OR REPLACE PROCEDURE `rj-crm-registry.procedures.atualizar_divisoes_administrativas`()
BEGIN
    -- 1. Backup da tabela atual
    CREATE OR REPLACE TABLE `rj-crm-registry.backup.divisoes_administrativas_backup`
    AS SELECT * FROM `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`;
    
    -- 2. Identificar mudanças nas fontes
    -- ... código para detectar mudanças
    
    -- 3. Aplicar atualizações
    -- ... código para aplicar mudanças
    
    -- 4. Validar integridade
    -- ... código de validação
    
    -- 5. Log de auditoria
    INSERT INTO `rj-crm-registry.logs.atualizacao_divisoes`
    VALUES (CURRENT_TIMESTAMP(), 'SUCCESS', 'Atualização automática concluída');
    
EXCEPTION WHEN ERROR THEN
    -- Rollback em caso de erro
    CREATE OR REPLACE TABLE `rj-crm-registry.rmi_dados_mestre.divisoes_administrativas`
    AS SELECT * FROM `rj-crm-registry.backup.divisoes_administrativas_backup`;
    
    INSERT INTO `rj-crm-registry.logs.atualizacao_divisoes`
    VALUES (CURRENT_TIMESTAMP(), 'ERROR', @@error.message);
    
    RAISE;
END;
```

### 6. Cronograma de Implementação

| Fase | Duração | Responsável | Entregáveis |
|------|---------|-------------|-------------|
| **Fase 1: Preparação** | 1 semana | DBA/Arquiteto | Estrutura da tabela, índices |
| **Fase 2: Migração** | 2 semanas | Engenheiro de Dados | Scripts de migração, dados carregados |
| **Fase 3: Validação** | 1 semana | Analista de Qualidade | Relatórios de validação, correções |
| **Fase 4: Testes** | 1 semana | Equipe de Desenvolvimento | Casos de uso testados |
| **Fase 5: Documentação** | 1 semana | Documentador Técnico | Guias de uso, procedimentos |
| **Fase 6: Produção** | 1 semana | DevOps | Deploy, monitoramento |

### 7. Riscos e Mitigações

| Risco | Probabilidade | Impacto | Mitigação |
|-------|---------------|---------|-----------|
| Geometrias inválidas | Baixa | Médio | Verificação de geometrias antes da carga |
| Performance de consultas espaciais | Média | Médio | Índices adequados, particionamento |
| Mudanças nas fontes durante migração | Baixa | Alto | Snapshot das fontes, versionamento |
| Relacionamentos espaciais incorretos | Média | Alto | Validação de intersecções, testes de qualidade |

### 8. Métricas de Sucesso

- ✅ 100% dos dados migrados sem perda
- ✅ Todas as validações de integridade passando
- ✅ Consultas espaciais executando em < 2 segundos
- ✅ Cobertura geográfica completa (todas as geometrias válidas)
- ✅ Relacionamentos espaciais corretos (>95% de precisão)
- ✅ Documentação completa e aprovada
- ✅ Testes de aceitação do usuário aprovados