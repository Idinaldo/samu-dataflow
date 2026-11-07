# esse Dockerfile está cheio de comentários para que colaboradores 
# iniciantes/sem conhecimento prévio possam entender melhor o que está acontecendo.
# Ass: Idinaldo Oliveira

# Pega o SDK do .NET para podermos construir a imagem.
# "AS build" define um alias, um apelido para esse momento do Dockerfile 
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

# define o diretório onde iremos trabalhar dentro do container docker
WORKDIR /src

# copia o .csproj para /src
COPY ["pulso192.csproj", "./"]

# baixa as dependências do projeto
RUN dotnet restore

#-----------------------------------
# NOTA: fizemos isso primeiro porque economiza recurso computacional.
# Se as dependências não mudarem, o docker conseguem manter o cache e não buscar elas de novo.
#-----------------------------------

# copia tudo da pasta atual (pulso192) para o ambiente de build (/src)
COPY . .

# Compila o projeto (dotnet publish)
RUN dotnet publish \
# utiliza a flag -c (configuration) para Release, otimizando-a para produção
-c Release \
# define o diretório de output da compilação
-o /app/publish \
# desativa a criação de um executável baseado no sistema operacional de host. aqui quem manda é o docker.
/p:UseAppHost=false

# pega uma imagem do ambiente de runtime, sem os itens desnecessários do SDK
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS prod

# define o diretório de trabalho atual como /app, onde só teremos coisas já prontas pra rodar a aplicação
WORKDIR /app

# copia tudo de /app/publish (onde só tem o output da compilação)
# lá do primeiro momento, do workdir que batizamos de build, para esse atual (/app)
COPY --from=build /app/publish .

# roda a aplicação de fato
ENTRYPOINT ["dotnet", "pulso192.dll"]

# PARA BUILDAR ESSE DOCKERFILE (PARA TESTE):
# docker build pulso192:test .

# PARA RODAR A IMAGEM GERADA (PARA TESTE):
# docker run -d -p 8080:8080 --name pulso192-api pulso192:test

# EXPLICANDO OS COMANDOS ANTERIORES
# o comando acima roda a imagem buildada pelo docker build
# o "-d" faz com que a aplicação rode em segundo plano fazendo com que seu terminal não seja travado
# o "-p 8080:8080" mapeia a porta 8080 do container com a porta 8080 da sua máquina
# o "--name pulso192-api" apenas define um nome
# o "pulso192:test" é apenas o nome:versão da imagem gerada pelo docker build