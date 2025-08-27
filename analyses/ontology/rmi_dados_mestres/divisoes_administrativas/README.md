# Ontologia: Divisões Administrativas do Rio de Janeiro

## Objetivo

Esta ontologia define uma estrutura unificada para representar todas as divisões administrativas, políticas, educacionais e de planejamento urbano do município do Rio de Janeiro. O objetivo é consolidar informações que atualmente estão distribuídas em múltiplas tabelas em uma única estrutura flexível e consultável, onde cada divisão é tratada como entidade independente.

## Problema Resolvido

Atualmente, as informações sobre divisões administrativas estão fragmentadas em várias tabelas:
- `bairro` - Informações de bairros com referências administrativas
- `subprefeitura` - Subprefeituras para descentralização
- `cres` - Coordenadorias Regionais de Educação
- `aeis` - Áreas de Especial Interesse Social
- `zoneamento_urbano` e `zoneamento_setores` - Zoneamento urbano

Esta fragmentação dificulta:
- Consultas que cruzam diferentes tipos de divisões
- Análises territoriais integradas  
- Geração de relatórios governamentais unificados
- Identificação de sobreposições geográficas entre divisões

## Benefícios da Unificação

### 1. **Consultas Simplificadas**
```sql
-- Antes: múltiplas JOINs entre tabelas
SELECT b.nome, b.nome_regiao_administrativa, s.subprefeitura
FROM bairro b 
JOIN subprefeitura s ON b.subprefeitura = s.subprefeitura
WHERE b.id_bairro = 'X';

-- Depois: consulta única
SELECT nome, tipo_divisao, orgao_responsavel
FROM divisoes_administrativas 
WHERE id_divisao = 'bairro_X';
```

### 2. **Relacionamentos Geográficos**
```sql
-- Encontrar todas as divisões que intersectam com uma área
SELECT d1.nome as divisao, d2.nome as intersecta_com
FROM divisoes_administrativas d1
JOIN divisoes_administrativas d2 ON ST_INTERSECTS(d1.geometry, d2.geometry)
WHERE d1.id_divisao = 'bairro_copacabana' 
AND d2.tipo_divisao IN ('AEIS', 'CRE', 'ZONA_PLANEJAMENTO_URBANO');
```

### 3. **Análises Territoriais Integradas**
```sql
-- Análise de densidade por tipo de divisão
SELECT tipo_divisao, 
       AVG(densidade_populacional) as densidade_media,
       SUM(area_m2)/1000000 as area_total_km2
FROM divisoes_administrativas 
GROUP BY tipo_divisao;
```

## Estrutura de Divisões

A ontologia trata cada divisão como entidade independente, reconhecendo que estruturas administrativas mudam politicamente:

```
🏛️ Administrativas:
   • MUNICIPIO (1)
   • AREA_PLANEJAMENTO (5) 
   • REGIAO_PLANEJAMENTO (~8)
   • SUBPREFEITURA (9)
   • REGIAO_ADMINISTRATIVA (~33)
   • BAIRRO (165)

🎯 Especializadas:
   • CRE - Coordenadorias de Educação (11)
   • AEIS - Áreas de Interesse Social (996)
   • ZONA_PLANEJAMENTO_URBANO (variável)
   • SETOR_CENSITARIO (variável)
```

As relações entre divisões são estabelecidas via intersecção geográfica, não hierarquia fixa.

## Casos de Uso

### 1. **Gestão Administrativa**
- Localizar a subprefeitura responsável por um endereço
- Gerar relatórios por região administrativa
- Mapear competências por divisão

### 2. **Planejamento Urbano**
- Análise de densidades por área de planejamento
- Identificação de AEIS em diferentes bairros
- Aplicação de instrumentos urbanísticos por zona

### 3. **Educação**
- Mapeamento de escolas por CRE
- Análise de cobertura educacional por bairro
- Planejamento de novas unidades escolares

### 4. **Análise Territorial**
- Estudos socioeconômicos por região
- Análise de demandas por serviços públicos
- Monitoramento de indicadores urbanos

### 5. **Aplicações Cidadãs**
- Localização de serviços públicos próximos
- Informações sobre a região de moradia
- Canais de atendimento por subprefeitura

## Padrões de Modelagem

### 1. **Identificação Única**
Cada divisão possui um `id_divisao` único no formato:
- `municipio_rio_de_janeiro`
- `ap_{numero}_{nome}`
- `bairro_{codigo_original}`
- `cre_{numero}`
- `aeis_{id_original}`

### 2. **Relacionamentos Geográficos**
- Relações estabelecidas via intersecção espacial
- Sem dependência de estrutura hierárquica fixa
- Flexibilidade para mudanças administrativas

### 3. **Atributos Flexíveis**
- `atributos_especificos`: JSON com campos específicos por tipo
- `metadados_fonte`: Preserva informações da fonte original

### 4. **Geometria Padronizada**
- `geometry`: Campo geográfico padrão
- `centroide_*`: Coordenadas do centroide
- `area_m2` e `perimetro_m`: Medidas padronizadas

## Implementação

### Etapa 1: Criação da Estrutura
1. Definir tabela com schema completo
2. Implementar índices e particionamento
3. Definir constraints de integridade

### Etapa 2: Migração de Dados
1. Mapear dados de `bairro` como divisões independentes
2. Incorporar `subprefeitura` como divisões administrativas
3. Adicionar `cres` como divisões educacionais
4. Incluir `aeis` como áreas especiais
5. Integrar dados de zoneamento

### Etapa 3: Validação
1. Verificar integridade geográfica
2. Validar geometrias e intersecções
3. Confirmar completude dos dados
4. Testar consultas de caso de uso

### Etapa 4: Documentação
1. Criar guias de consulta
2. Documentar casos de uso
3. Estabelecer procedimentos de atualização

## Manutenção

### Atualizações Regulares
- Monitorar mudanças nas fontes originais
- Atualizar geometrias quando necessário
- Incorporar novas divisões (ex: novas AEIS)

### Qualidade de Dados
- Validação de geometrias
- Verificação de consistência espacial
- Monitoramento de completude

### Governança
- Definir responsáveis por tipo de divisão
- Estabelecer fluxo de aprovação para mudanças
- Documentar versionamento do schema

## Próximos Passos

1. ✅ Definir ontologia e schema
2. 📝 Implementar modelo de dados
3. 🔄 Migrar dados das fontes existentes
4. 🧪 Testar casos de uso
5. 📚 Documentar procedimentos
6. 🚀 Colocar em produção