{% macro validate_phone_quality(numero_completo, freq_usage) %}
  {% set config = var('phone_validation') %}
  case
    when {{ is_format_valid(numero_completo) }} 
         and {{ freq_usage }} <= {{ config.freq_valid_max }} 
    then 'VALIDO'
    
    when {{ is_format_valid(numero_completo) }} 
         and (
           {{ freq_usage }} between {{ config.freq_suspicious_min }} and {{ config.freq_suspicious_max }}
           or {{ has_suspicious_patterns(numero_completo) }}
         )
    then 'SUSPEITO'
    
    when not {{ is_format_valid(numero_completo) }}
         or {{ freq_usage }} >= {{ config.freq_invalid_min }}
         or {{ has_dummy_patterns(numero_completo) }}
    then 'INVALIDO'
    
    else 'SUSPEITO'
  end
{% endmacro %}