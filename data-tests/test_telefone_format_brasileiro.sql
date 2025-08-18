-- Testa se números brasileiros (DDI 55) têm formato válido
-- Verifica DDD válido e comprimento correto

select 
  telefone_numero_completo,
  telefone_ddi,
  telefone_ddd,
  telefone_numero,
  telefone_tipo,
  case
    when telefone_ddi = '55' and telefone_ddd is null then 'ERRO: Telefone brasileiro sem DDD'
    when telefone_ddi = '55' and cast(telefone_ddd as int64) not in (
      11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 31, 32, 33, 34, 35, 37, 38, 
      41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55, 61, 62, 63, 64, 65, 66, 67, 68, 69, 
      71, 73, 74, 75, 77, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99
    ) then 'ERRO: DDD inválido para Brasil'
    when telefone_ddi = '55' and telefone_tipo = 'CELULAR' 
         and (length(telefone_numero) != 9 or not starts_with(telefone_numero, '9')) 
         then 'ERRO: Celular brasileiro deve ter 9 dígitos começando com 9'
    when telefone_ddi = '55' and telefone_tipo = 'FIXO' 
         and length(telefone_numero) != 8 
         then 'ERRO: Fixo brasileiro deve ter 8 dígitos'
    else null
  end as erro_formato
from {{ ref('int_rmi_telefones_consolidated') }}
where telefone_ddi = '55'
  and (
    telefone_ddd is null 
    or cast(telefone_ddd as int64) not in (
      11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 31, 32, 33, 34, 35, 37, 38, 
      41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55, 61, 62, 63, 64, 65, 66, 67, 68, 69, 
      71, 73, 74, 75, 77, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89, 91, 92, 93, 94, 95, 96, 97, 98, 99
    )
    or (telefone_tipo = 'CELULAR' and (length(telefone_numero) != 9 or not starts_with(telefone_numero, '9')))
    or (telefone_tipo = 'FIXO' and length(telefone_numero) != 8)
  )