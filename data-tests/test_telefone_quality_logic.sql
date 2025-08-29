-- Testa a lógica de classificação de qualidade de telefones
-- Verifica se a frequência de uso está alinhada com a classificação de qualidade

select 
  telefone_numero_completo,
  telefone_qualidade,
  telefone_proprietarios_quantidade,
  case 
    when telefone_proprietarios_quantidade <= 5 and telefone_qualidade != 'VALIDO' 
         and telefone_qualidade != 'SUSPEITO' then 'ERRO: Baixa frequência deveria ser VALIDO ou SUSPEITO'
    when telefone_proprietarios_quantidade > 15 and telefone_qualidade != 'INVALIDO' 
         then 'ERRO: Alta frequência deveria ser INVALIDO'
    else null
  end as erro_classificacao
from {{ ref('dim_telefone') }}
where case 
    when telefone_proprietarios_quantidade <= 5 and telefone_qualidade != 'VALIDO' 
         and telefone_qualidade != 'SUSPEITO' then true
    when telefone_proprietarios_quantidade > 15 and telefone_qualidade != 'INVALIDO' 
         then true
    else false
  end