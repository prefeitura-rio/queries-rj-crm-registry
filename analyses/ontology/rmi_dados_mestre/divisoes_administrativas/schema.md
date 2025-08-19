# Schema: Divisões Administrativas do Rio de Janeiro

## Visão Geral

Esta tabela unifica todas as divisões administrativas, políticas, educacionais e de planejamento urbano do município do Rio de Janeiro, excluindo dados no nível de logradouro. Cada divisão é tratada como uma entidade independente, reconhecendo que as estruturas administrativas mudam frequentemente por questões políticas.

## Estrutura do Schema

### Campos de Identificação
- `id_divisao` (STRING, PRIMARY KEY): Identificador único da divisão administrativa
- `tipo_divisao` (STRING, NOT NULL): Tipo da divisão administrativa
- `codigo_original` (STRING): Código original da fonte de dados
- `nome` (STRING, NOT NULL): Nome oficial da divisão
- `nome_abreviado` (STRING): Nome abreviado ou sigla

### Campos Administrativos
- `orgao_responsavel` (STRING): Órgão municipal responsável pela divisão
- `competencias` (ARRAY<STRING>): Lista de competências/responsabilidades
- `data_criacao` (DATE): Data de criação/instituição da divisão
- `legislacao_base` (STRING): Legislação que instituiu a divisão

### Campos Geográficos
- `area_m2` (FLOAT): Área em metros quadrados
- `perimetro_m` (FLOAT): Perímetro em metros
- `centroide_latitude` (FLOAT): Latitude do centroide
- `centroide_longitude` (FLOAT): Longitude do centroide
- `geometry` (GEOGRAPHY): Geometria completa da divisão
- `geometry_wkt` (STRING): Geometria em formato WKT

### Campos Específicos por Tipo
- `atributos_especificos` (JSON): Campos específicos para cada tipo de divisão
- `metadados_fonte` (JSON): Metadados da fonte original dos dados

### Campos de Controle
- `ativo` (BOOLEAN, DEFAULT TRUE): Indica se a divisão está ativa
- `data_atualizacao` (TIMESTAMP): Data da última atualização
- `fonte_dados` (STRING): Fonte original dos dados
- `versao_schema` (STRING): Versão do schema utilizada

## Tipos de Divisão

### 1. MUNICIPIO
- **Descrição**: Município do Rio de Janeiro
- **Quantidade**: 1
- **Responsável**: Prefeitura Municipal

### 2. AREA_PLANEJAMENTO  
- **Descrição**: Áreas de Planejamento (AP1, AP2, AP3, AP4, AP5)
- **Quantidade**: 5
- **Responsável**: IPP/SMU
- **Atributos Específicos**:
  - `caracteristicas_socioeconomicas` (STRING)
  - `diretrizes_planejamento` (ARRAY<STRING>)

### 3. REGIAO_PLANEJAMENTO
- **Descrição**: Regiões de Planejamento
- **Quantidade**: ~8
- **Responsável**: IPP/SMU
- **Atributos Específicos**:
  - `vocacao_territorial` (STRING)
  - `projetos_estrategicos` (ARRAY<STRING>)

### 4. SUBPREFEITURA
- **Descrição**: Subprefeituras para descentralização administrativa
- **Quantidade**: 9
- **Responsável**: SUBGAB
- **Atributos Específicos**:
  - `endereco_sede` (STRING)
  - `telefone_contato` (STRING)
  - `email_contato` (STRING)
  - `horario_funcionamento` (STRING)

### 5. REGIAO_ADMINISTRATIVA
- **Descrição**: Regiões Administrativas (RAs)
- **Quantidade**: ~33
- **Responsável**: IPP
- **Atributos Específicos**:
  - `codigo_ra` (STRING)
  - `decreto_criacao` (STRING)

### 6. BAIRRO
- **Descrição**: Bairros oficiais do município
- **Quantidade**: 165
- **Responsável**: IPP
- **Atributos Específicos**:
  - `codigo_bairro` (STRING)
  - `caracteristicas_urbanas` (STRING)

### 7. CRE
- **Descrição**: Coordenadorias Regionais de Educação
- **Quantidade**: 11
- **Responsável**: SME
- **Atributos Específicos**:
  - `numero_escolas` (INTEGER)
  - `numero_alunos` (INTEGER)
  - `coordenador_regional` (STRING)

### 8. AEIS
- **Descrição**: Áreas de Especial Interesse Social
- **Quantidade**: 996
- **Responsável**: SMU
- **Atributos Específicos**:
  - `tipologia_aeis` (STRING): Tipo da AEIS (1, 2, 3)
  - `situacao_regularizacao` (STRING)
  - `projeto_urbanizacao` (STRING)
  - `legislacao_especifica` (STRING)

### 9. ZONA_PLANEJAMENTO_URBANO
- **Descrição**: Zonas do Plano Diretor
- **Quantidade**: Variável
- **Responsável**: SMU
- **Atributos Específicos**:
  - `categoria_zona` (STRING)
  - `parametros_urbanisticos` (JSON)
  - `atividades_permitidas` (ARRAY<STRING>)

### 10. SETOR_CENSITARIO
- **Descrição**: Setores Censitários do IBGE (quando aplicável)
- **Quantidade**: Variável
- **Responsável**: IBGE
- **Atributos Específicos**:
  - `codigo_ibge` (STRING)
  - `tipo_setor` (STRING)
  - `situacao_setor` (STRING)

## Índices Recomendados


## Particionamento

```sql
-- Particionamento por tipo de divisão para otimizar consultas
PARTITION BY tipo_divisao
CLUSTER BY area_m2 DESC, ativo
```

## Relacionamentos Geográficos

Como as divisões são independentes mas podem ter sobreposições geográficas, as relações entre elas são estabelecidas através de:

### 1. **Spatial Joins**
```sql
-- Encontrar quais AEIS estão em determinado bairro
SELECT a.nome as aeis, b.nome as bairro
FROM divisoes_administrativas a
JOIN divisoes_administrativas b ON ST_INTERSECTS(a.geometry, b.geometry)
WHERE a.tipo_divisao = 'AEIS' AND b.tipo_divisao = 'BAIRRO';
```

### 2. **Contenção Geográfica**
```sql
-- Verificar quais divisões contêm um ponto específico
SELECT tipo_divisao, nome
FROM divisoes_administrativas
WHERE ST_CONTAINS(geometry, ST_GEOGPOINT(-43.1729, -22.9068))
ORDER BY area_m2;
```

## Regras de Negócio

1. **Identificadores Únicos**: Cada divisão deve ter um id_divisao único
2. **Códigos Únicos por Tipo**: Códigos originais devem ser únicos dentro do mesmo tipo_divisao
3. **Geometrias Válidas**: Geometrias devem ser válidas e representar adequadamente a divisão
4. **Consistência Temporal**: Data de atualização deve refletir mudanças na fonte
5. **Flexibilidade Política**: Sistema deve suportar mudanças administrativas sem quebrar referências

## Fontes de Dados

- **dados_mestres.bairro**: Bairros e hierarquia administrativa
- **dados_mestres.subprefeitura**: Subprefeituras
- **dados_mestres.cres**: Coordenadorias Regionais de Educação
- **dados_mestres.aeis**: Áreas de Especial Interesse Social
- **dados_mestres.zoneamento_urbano**: Zoneamento urbano
- **dados_mestres.zoneamento_setores**: Setores de zoneamento