# Pulso 192

Backend para tratamento dos dados de ocorrências do SAMU Recife, feito para o **CIE (Centro de Inteligência Epidemiológica do Recife)**, da SESAU/COP.

Projeto 2 de Segurança da Informação da CESAR School, 2026.2. [Site do projeto](https://sites.google.com/cesar.school/samu-dataflow-projeto-2-ciber/).

## O que faz

O Pulso 192 lê a camada bronze no Oracle, aplica as regras de qualidade e grava os registros aceitos diretamente no PostgreSQL. A API dispara o pipeline e permite consultar os resultados; ela não faz uma chamada HTTP para si mesma durante a carga.

```mermaid
flowchart LR
    O[(Oracle)] -->|extrai| E[Pipeline ETL em C#]
    E -->|valida e transforma| E
    E -->|grava diretamente| P[(PostgreSQL)]
    C[Cliente ou Airflow] -->|POST /execucoes| E
    C -->|GET /ocorrencias| P
```

O pipeline registra as rejeições e os totais de cada execução. A persistência usa uma transação e uma chave hash única para não inserir duplicatas em execuções repetidas. Regras em [docs/regras-de-qualidade.md](docs/regras-de-qualidade.md); classes e fluxo em [docs/diagrama-de-classes.md](docs/diagrama-de-classes.md).

## Estrutura

```
pulso192/              API ASP.NET Core e pipeline ETL
  Configuration/       opções de conexão e configuração
  Contracts/           respostas públicas da API
  Controllers/          endpoints /execucoes e /ocorrencias
  Domain/               ocorrência, execução, rejeições e relatório
  Infrastructure/       repositório PostgreSQL e inicialização do schema
  Middleware/           API key e tratamento de erros
  Pipeline/             fonte Oracle, regras e orquestração do ETL
  Database/             schema do PostgreSQL e seed fictício do Oracle
docs/                   regras de qualidade e diagrama de classes
docker-compose.yml      API, PostgreSQL e Oracle de demonstração
.env.example            modelo de variáveis para execução local
```

## Como rodar localmente

### Pré-requisitos

- Docker Desktop com Docker Compose
- Acesso à imagem Oracle Free no Oracle Container Registry

Copie `.env.example` para `.env` na raiz do repositório e ajuste os valores se necessário. Os valores do exemplo são somente para uso local; não use credenciais de exemplo em ambientes reais.

Suba a API e os bancos:

```powershell
docker compose up -d --build
```

Para iniciar novamente sem rebuild:

```powershell
docker compose up -d
```

O `docker-compose.yml` **não publica nenhuma porta** no host: os bancos e a API ficam acessíveis só dentro da rede do Compose. Para chamar a API de fora (REST Client, curl, navegador), suba com o arquivo que publica a API em `http://localhost:8080` (porta configurável por `API_HOST_PORT` no `.env`); PostgreSQL e Oracle continuam sem porta exposta:

```powershell
docker compose -f docker-prod-compose.yml up -d --build
```

O Oracle verifica a tabela de demonstração no schema `SYSTEM` ao iniciar: se ela não existir com as 36 colunas e 10 registros esperados, executa o script em `pulso192/Database/Oracle/setup`; caso já esteja pronta, não a recria. Aguarde o Oracle ficar `healthy` (`docker compose ps`) antes de disparar o pipeline.

Os endpoints protegidos exigem o header `X-API-Key`. O valor padrão local é `local-only-development-key`; se alterar `API_KEY` no `.env`, atualize também a variável `@apiKey` no arquivo [pulso192.http](pulso192/pulso192.http).

### Testando a API

Abra [pulso192/pulso192.http](pulso192/pulso192.http) no VS Code com a extensão **REST Client** e clique em *Send Request* sobre cada requisição. **Rode primeiro o `POST /execucoes`**, senão o banco fica vazio.

Comportamento observado com o seed de demonstração (10 registros, todos em `RECIFE`):

- `POST /execucoes` na primeira vez: `totalLidos` 10, `totalCarregados` 10, `totalRejeitados` 0.
- `POST /execucoes` de novo (idempotência): os 10 registros voltam rejeitados pela regra `R02` (duplicata) e nada é inserido.
- `GET /ocorrencias`: 10 itens; `?pagina=2&tamanhoPagina=10` devolve `itens` vazio e `total` 10. `pagina` deve ser ≥ 1 e `tamanhoPagina` entre 1 e 100, senão a resposta é 400.
- Filtros `municipio` e `bairro`: **não diferenciam maiúsculas de minúsculas** (`Recife`, `recife` e `RECIFE` dão o mesmo resultado), mas **diferenciam acentos**. Os dados são gravados sem acento (`GRACAS`, `TORROES`), então `bairro=gracas` acha e `bairro=Graças` não.
- O exemplo `bairro=BOA VIAGEM` retorna 0 itens: esse bairro não existe no seed. Use, por exemplo, `GRACAS` ou `IBURA`.
- Sem o header `X-API-Key` (ou com chave errada): 401.
