{% macro remove_accents_lower(texto) %}TRIM(LOWER(REGEXP_REPLACE(NORMALIZE({{ texto }}, NFD), r'\pM', ''))){% endmacro %}
