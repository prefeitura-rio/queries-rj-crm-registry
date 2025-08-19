# Análise de Qualidade e Confiança de Telefones

Esta análise gera duas tabelas que podem ser usadas para criar um dashboard sobre a qualidade e confiança dos telefones principais dos CPFs cadastrados.

## Modelos de Análise

1.  `matriz_qualidade_confianca`: Contagem de CPFs para cada combinação de `telefone_qualidade` e `confianca_propriedade`.
2.  `matriz_qualidade_confianca_percent`: Mesma matriz, mas com a adição de uma coluna com o percentual do total de CPFs.

## Como Usar

1.  **Execute as análises:**

    ```bash
    dbt run --select +matriz_qualidade_confianca
    ```

2.  **Conecte seu BI Tool:**

    Conecte sua ferramenta de BI (Metabase, Looker, PowerBI, etc.) ao seu data warehouse.

3.  **Crie o Dashboard:**

    *   **Tabela de Contagem:**
        *   Crie uma tabela ou matriz usando o modelo `matriz_qualidade_confianca`.
        *   Use `telefone_qualidade` como linhas.
        *   Use `confianca_propriedade` como colunas.
        *   Use `cpf_count` como valores.

    *   **Tabela de Percentual:**
        *   Crie uma segunda tabela ou matriz usando o modelo `matriz_qualidade_confianca_percent`.
        *   Use `telefone_qualidade` como linhas.
        *   Use `confianca_propriedade` como colunas.
        *   Use `cpf_percent` como valores e formate como porcentagem.

    *   **Gráficos Adicionais:**
        *   Crie um gráfico de barras empilhadas para visualizar a distribuição de `confianca_propriedade` para cada `telefone_qualidade`.
        *   Crie um gráfico de pizza para mostrar a distribuição geral de `telefone_qualidade`.
