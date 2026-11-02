# Pulso192 DataFlow

## Sobre

O Centro de Inteligência Epidemiológica (CIE) do Recife apresentou-nos a seguinte dor através da cadeira <strong>Projeto 2</strong>: analisamos um grande volume de dados manualmente.

A partir dessa dor, começamos a trabalhar em uma solução para automatizar e estruturar esse processo. Este repositório é um dos meios utilizados para disponibilizar os produtos da nossa solução, concentrando principalmente sua parte técnica.

<strong>Mais detalhes sobre o problema estão disponíveis no [nosso site](https://sites.google.com/cesar.school/samu-dataflow-projeto-2-ciber/).</strong>

## Requisitos

### Funcionais

O sistema deve ser capaz de:

1. Importar arquivos .xlsx
2. Validar dados
3. Tratar de registros inválidos ou duplicados
4. Gerar logs de seu funcionamento
5. Persistir dados tratados
6. Expor dados tratados

### Não Funcionais

Algumas condições que afetam o design do sistema foram impostas, entre elas:

- Utilização de C#
- PostgreSQL como banco de dados
- Integração com Airflow
- Utilização de Docker

## Estrutura do repositório

- `pulso192/`: API ASP.NET Core em C#.
- `docker-compose.yml`: serviços da API e do PostgreSQL.
- `.env.example`: exemplo das variáveis necessárias para o Compose.

### ATENÇÃO

O Docker Compose **não constrói a imagem da API**: ele espera encontrar localmente a imagem `pulso192` com a tag configurada no `.env`. Por isso, siga os passos abaixo na ordem. Este fluxo usa os recursos de publicação de contêiner do SDK do .NET e não precisa de um `Dockerfile`.

### Passo 1: confira os pré-requisitos

Instale o SDK do .NET compatível com o projeto, o Docker e o Docker Compose. Deixe o Docker em execução; no Windows, configure o Docker Desktop para usar **contêineres Linux**. Execute os comandos a partir da raiz do repositório.

### Passo 2: publique a imagem da API

Escolha o comando conforme a arquitetura do computador onde a imagem será executada:

- Linux x64, Windows x64 com Docker Desktop em modo de contêineres Linux ou macOS com processador Intel (x64):

  ```bash
  dotnet publish pulso192/pulso192.csproj --os linux --arch x64 -t:PublishContainer -p:ContainerRepository=pulso192 -p:ContainerImageTag=latest-linux-x64
  ```

- Linux/Windows ARM64 ou macOS com Apple Silicon (ARM64):

  ```bash
  dotnet publish pulso192/pulso192.csproj --os linux --arch arm64 -t:PublishContainer -p:ContainerRepository=pulso192 -p:ContainerImageTag=latest-linux-arm64
  ```

Os comandos criam imagens Linux; `--arch` indica a arquitetura da imagem, não o sistema operacional do computador. A publicação cria a imagem localmente como `pulso192` com a tag definida por `ContainerImageTag`.

### Passo 3: crie e configure o `.env`

Na raiz do repositório, faça uma cópia de `.env.example` com o comando adequado ao terminal:

- Linux, macOS ou Git Bash:

  ```bash
  cp .env.example .env
  ```

- Windows PowerShell:

  ```powershell
  Copy-Item .env.example .env
  ```

- Prompt de Comando do Windows (CMD):

  ```cmd
  copy .env.example .env
  ```

`cp` não é nativo do CMD; nele, use `copy`. Depois, abra o `.env` e ajuste os valores **antes** de iniciar o Compose:

- `POSTGRES_DB`, `POSTGRES_USER` e `POSTGRES_PASSWORD`: banco e credenciais locais do PostgreSQL.
- `POSTGRES_HOST_PORT`: porta do PostgreSQL no computador (5433 por padrão).
- `API_HOST_PORT`: porta da API no computador (8001 por padrão).
- `API_IMAGE_TAG`: tag da imagem publicada no passo anterior. Use `latest-linux-x64` para x64 ou `latest-linux-arm64` para ARM64.
- `ASPNETCORE_ENVIRONMENT`, `API_KEY` e `ORACLE_CONNECTION_STRING`: configurações adicionais da API.

O nome da imagem (`pulso192`) já está definido no `docker-compose.yml`; `API_IMAGE_TAG` escolhe somente a tag. Por exemplo, `API_IMAGE_TAG=latest-linux-arm64` usa a imagem `pulso192:latest-linux-arm64`. A tag deve corresponder à imagem publicada no passo 2.

O `.env` é local e não deve ser enviado ao Git, pois pode conter credenciais. O `.env.example` é apenas um modelo: substitua os valores de exemplo, especialmente senhas e chaves.

### Passo 4: inicie os serviços

Na raiz do repositório, execute:

```bash
docker compose up -d
```

O Compose inicia o PostgreSQL e, quando o banco estiver saudável, a API. Consulte o estado com `docker compose ps` e acompanhe os logs com `docker compose logs -f`.

O PostgreSQL fica acessível no computador pela porta `POSTGRES_HOST_PORT` (5433 por padrão), e a API pela porta `API_HOST_PORT` (8001 por padrão). Entre os contêineres, a API acessa o banco pelo serviço `db` na porta interna `5432`.

### Passo 5: pare os serviços

Para parar e remover os contêineres e a rede, mantendo os dados do PostgreSQL no volume:

```bash
docker compose down
```

## Diagrama de Classes

![diagrama de classes](./diagrama-de-classes.png)
