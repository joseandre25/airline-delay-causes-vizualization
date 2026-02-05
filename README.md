# Airline Delay Causes Visualization

Projeto acadêmico de Data Warehouse e Analytics usando o dataset Airline On-Time Statistics and Delay Causes (BTS/Kaggle) em CSV, seguindo arquitetura em medalhão (Bronze → Silver → Gold) e entrega final em dashboard no Power BI.

## Visão Geral

Este projeto implementa um pipeline de dados completo que transforma dados brutos de atrasos de voos em um Data Warehouse estruturado, seguindo a arquitetura de medalhão:

- **RAW (Bronze)**: Dados brutos do CSV original
- **SILVER**: Dados limpos, padronizados e validados
- **GOLD (DW)**: Modelagem dimensional (Star Schema) pronta para análise

## Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- Docker e Docker Compose
- Python 3.8 ou superior
- Jupyter Notebook ou JupyterLab
- Power BI Desktop (para visualização final)

## Estrutura do Projeto

```
airline-delay-causes-vizualization/
├── Data Layer/
│   ├── raw/                    # Camada RAW (Bronze)
│   │   ├── data_raw.csv        # Dataset original
│   │   ├── analytcs.ipynb      # Análises exploratórias
│   │   └── dicionario_de_dados.pdf
│   ├── silver/                 # Camada SILVER
│   │   ├── ddl.sql             # DDL da tabela Silver
│   │   ├── analytcs.ipynb      # Análises dos dados limpos
│   │   └── mer_der_dld.pdf
│   └── gold/                   # Camada GOLD (Data Warehouse)
│       ├── ddl.sql             # DDL do Star Schema
│       ├── consultas.sql       # Consultas de exemplo
│       ├── mer_der_dld.pdf
│       └── mnemonicos.pdf
├── Transformer/
│   ├── etl_raw_to_silver.ipynb # ETL: RAW → SILVER
│   └── etl_silver_to_gold.ipynb # ETL: SILVER → GOLD
├── docker-compose.yml          # Configuração do PostgreSQL
├── requirements.txt            # Dependências Python
└── README.md
```

## Guia de Instalação e Execução

### Passo 1: Subir o Banco de Dados PostgreSQL

O projeto utiliza PostgreSQL como banco de dados. Vamos subir o container Docker:

```bash
# Na raiz do projeto, execute:
docker-compose up -d
```

Isso irá:
- Criar um container PostgreSQL 15
- Expor a porta 5432
- Criar o banco de dados `airline_delay_causes`
- Configurar usuário `postgres` com senha `postgres`

**Verificar se o container está rodando:**

```bash
docker ps
```

Você deve ver o container `airline_delay_causes_postgres` em execução.

**Parar o container (quando necessário):**

```bash
docker-compose down
```

**Parar e remover volumes (limpar dados):**

```bash
docker-compose down -v
```

### Passo 2: Instalar Dependências Python

Instale as bibliotecas necessárias para executar os notebooks:

```bash
pip install -r requirements.txt
```

As dependências incluem:
- pandas: Manipulação de dados
- numpy: Operações numéricas
- sqlalchemy: Conexão com PostgreSQL
- psycopg2-binary: Driver PostgreSQL para Python
- matplotlib e seaborn: Visualizações

### Passo 3: Executar ETL RAW → SILVER

Este notebook transforma os dados brutos do CSV em dados limpos e padronizados.

1. **Abra o Jupyter Notebook:**

```bash
jupyter notebook
```

Ou se preferir JupyterLab:

```bash
jupyter lab
```

2. **Navegue até o notebook:**

```
Transformer/etl_raw_to_silver.ipynb
```

3. **Execute as células sequencialmente:**

O notebook está organizado em etapas:

- **Extract**: Carrega o CSV `Data Layer/raw/data_raw.csv`
- **Transform**: Aplica limpezas, padronizações e validações
- **Load**: Cria o schema `silver` e a tabela `silver.silver_airline_on_time` no PostgreSQL

**Importante:** Execute todas as células na ordem. O notebook:
- Cria o schema `silver` automaticamente
- Aplica o DDL da tabela Silver
- Carrega os dados transformados
- Cria índices para otimização

**Verificar dados carregados:**

Após executar o notebook, você pode verificar no PostgreSQL:

```bash
docker exec -it airline_delay_causes_postgres psql -U postgres -d airline_delay_causes -c "SELECT COUNT(*) FROM silver.silver_airline_on_time;"
```

### Passo 4: Executar ETL SILVER → GOLD

Este notebook transforma os dados da camada Silver em um Data Warehouse dimensional (Star Schema).

1. **Abra o notebook:**

```
Transformer/etl_silver_to_gold.ipynb
```

2. **Execute as células sequencialmente:**

O notebook realiza:

- **DDL**: Cria o schema `dw` e as tabelas do Star Schema:
  - `dim_tmp`: Dimensão de Tempo
  - `dim_cia`: Dimensão de Companhia Aérea
  - `dim_apt`: Dimensão de Aeroporto
  - `fat_atr`: Tabela Fato de Atrasos
- **Extract**: Lê dados da tabela `silver.silver_airline_on_time`
- **Transform**: Aplica a modelagem dimensional
- **Load**: Carrega dados nas dimensões e fato

**Verificar dados carregados:**

```bash
docker exec -it airline_delay_causes_postgres psql -U postgres -d airline_delay_causes -c "SELECT COUNT(*) FROM dw.fat_atr;"
```

### Passo 5: Conectar Power BI ao Data Warehouse

Agora que os dados estão na camada Gold, você pode criar visualizações no Power BI.

1. **Abra o Power BI Desktop**

2. **Conecte ao PostgreSQL:**

   - Clique em "Obter Dados" > "Banco de dados" > "PostgreSQL database"
   - **Servidor**: `localhost`
   - **Banco de dados**: `airline_delay_causes`
   - **Modo de conectividade**: Import (recomendado) ou DirectQuery
   - Clique em "OK"

3. **Autenticação:**

   - Selecione "Database"
   - **Usuário**: `postgres`
   - **Senha**: `postgres`
   - Clique em "Conectar"

4. **Selecionar tabelas:**

   No navegador, expanda o schema `dw` e selecione as tabelas:
   - `dim_tmp` (Tempo)
   - `dim_cia` (Companhia Aérea)
   - `dim_apt` (Aeroporto)
   - `fat_atr` (Fato de Atrasos)

5. **Criar relacionamentos:**

   O Power BI pode detectar automaticamente os relacionamentos baseados nas chaves estrangeiras. Verifique:
   - `fat_atr.srk_tmp` → `dim_tmp.srk_tmp`
   - `fat_atr.srk_cia` → `dim_cia.srk_cia`
   - `fat_atr.srk_apt` → `dim_apt.srk_apt`

6. **Criar visualizações:**

   Agora você pode criar dashboards com métricas como:
   - Total de atrasos por companhia aérea
   - Atrasos por aeroporto
   - Tendências temporais de atrasos
   - Causas de atrasos (carrier, weather, NAS, security, late aircraft)
   - Taxa de cancelamentos e desvios

## Consultas SQL de Exemplo

O arquivo `Data Layer/gold/consultas.sql` contém consultas SQL úteis para análise. Você pode executá-las diretamente no PostgreSQL:

```bash
docker exec -i airline_delay_causes_postgres psql -U postgres -d airline_delay_causes < "Data Layer/gold/consultas.sql"
```

Ou conecte-se interativamente:

```bash
docker exec -it airline_delay_causes_postgres psql -U postgres -d airline_delay_causes
```

## Variáveis de Ambiente (Opcional)

Por padrão, o projeto usa as seguintes configurações:

- `POSTGRES_DB=airline_delay_causes`
- `POSTGRES_USER=postgres`
- `POSTGRES_PASSWORD=postgres`
- `POSTGRES_HOST=localhost`
- `POSTGRES_PORT=5432`

Se precisar alterar, você pode:

1. **Criar um arquivo `.env` na raiz do projeto:**

```
POSTGRES_DB=airline_delay_causes
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
```

2. **Atualizar o `docker-compose.yml` para usar variáveis de ambiente:**

O arquivo já está configurado para ler do `.env` ou usar valores padrão.

3. **Nos notebooks Jupyter:**

Os notebooks já leem variáveis de ambiente usando `os.getenv()`, então você pode exportar antes de executar:

```bash
export POSTGRES_PASSWORD=minha_senha
jupyter notebook
```

## Troubleshooting

### Erro: "Connection refused" ao conectar ao PostgreSQL

**Causa:** O container Docker não está rodando.

**Solução:**

```bash
docker-compose up -d
docker ps  # Verificar se está rodando
```

### Erro: "ModuleNotFoundError" ao executar notebook

**Causa:** Dependências Python não instaladas.

**Solução:**

```bash
pip install -r requirements.txt
```

### Erro: "FileNotFoundError: data_raw.csv"

**Causa:** O arquivo CSV não está no caminho esperado.

**Solução:** Verifique se o arquivo `Data Layer/raw/data_raw.csv` existe. Os notebooks esperam ser executados a partir da pasta `Transformer/`.

### Erro: "relation already exists" no ETL Silver → Gold

**Causa:** O DDL tenta criar tabelas que já existem.

**Solução:** Isso é normal. O DDL usa `DROP TABLE IF EXISTS` antes de criar. Se o erro persistir, você pode limpar o schema:

```bash
docker exec -it airline_delay_causes_postgres psql -U postgres -d airline_delay_causes -c "DROP SCHEMA IF EXISTS dw CASCADE; CREATE SCHEMA dw;"
```

### Power BI não consegue conectar ao PostgreSQL

**Causa:** Firewall ou configuração de rede.

**Solução:**

1. Verifique se o PostgreSQL está acessível:
   ```bash
   docker exec -it airline_delay_causes_postgres psql -U postgres -d airline_delay_causes -c "SELECT 1;"
   ```

2. No Power BI, tente usar `127.0.0.1` ao invés de `localhost`

3. Verifique se a porta 5432 não está bloqueada pelo firewall

## Arquitetura de Dados

### Camada RAW (Bronze)

- **Fonte**: CSV original do dataset BTS/Kaggle
- **Características**: Dados brutos, sem tratamento
- **Localização**: `Data Layer/raw/data_raw.csv`

### Camada SILVER

- **Fonte**: Processamento do RAW via ETL
- **Características**: 
  - Dados limpos e padronizados
  - Validações aplicadas
  - Flags de qualidade (ex: outliers)
  - Tipos de dados corretos
- **Tabela**: `silver.silver_airline_on_time`
- **Chave Primária**: (year, month, carrier, airport)

### Camada GOLD (Data Warehouse)

- **Fonte**: Processamento do SILVER via ETL
- **Modelagem**: Star Schema (1 fato, 3 dimensões)
- **Dimensões**:
  - `dim_tmp`: Tempo (ano, mês, trimestre)
  - `dim_cia`: Companhia Aérea (código, nome)
  - `dim_apt`: Aeroporto (código, nome)
- **Fato**:
  - `fat_atr`: Atrasos, cancelamentos, desvios e suas causas
