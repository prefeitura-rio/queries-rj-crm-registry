

## Telefone Qualidade

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



