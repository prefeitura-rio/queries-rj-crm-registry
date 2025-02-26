CREATE OR REPLACE TABLE `rj-crm-registry.dados_mestres.dominio_bcadastro` AS (
select id, {{ proper_br("descricao") }} as descricao, column, 'cpf' as source
from `rj-crm-registry.dados_mestres_staging.dominio_bcadastro_cpf`
union all
select id, {{ proper_br("descricao") }} as descricao, column, 'cnpj' as source
from
    `rj-crm-registry.dados_mestres_staging.dominio_bcadastro_cnpj`
    )
