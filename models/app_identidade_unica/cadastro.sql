DECLARE cpf_filter1 INT64 DEFAULT ;
DECLARE cpf_filter2 INT64 DEFAULT ;
DECLARE cpf_filter3 INT64 DEFAULT ;

with
    cadastros as (
        select cpf, origens, dados, endereco, contato, saude, assistencia_social
        from `rj-crm-registry.crm_identidade_unica.cadastros`
        where
            cpf_particao is not null
            and cpf_particao in (cpf_filter1, cpf_filter2, cpf_filter3)
    )

select *
from cadastros
