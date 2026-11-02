# Decisões do projeto

Por que o Pulso 192 é do jeito que é. Antes de mudar alguma coisa listada aqui, fala com o time: provavelmente já foi discutido com o professor ou com o CIE.

Quando surgir decisão nova, adiciona uma linha no fim com data, o que foi decidido e por quê.

## Por onde começar

1. Este arquivo (o porquê)
2. [regras-de-qualidade.md](regras-de-qualidade.md) (o que o motor faz com cada coluna)
3. [diagrama-de-classes.md](diagrama-de-classes.md) (como o código se organiza)
4. O [README](../README.md) (como rodar)

## Escopo

**D01. O produto é o motor de tratamento, não a extração** (set/2026, professor)
A nota é sobre tratar os dados (o "T" do ETL). Puxar dados direto do sistema do SAMU (Hexagon) é o "sonho do cliente", mas fica fora: é sistema de emergência em produção, mexer nele é arriscado, e o próprio CIE já faz isso do jeito deles. PDF também fica fora.

**D02. A fonte é um banco Oracle preparado pelo CIE, no modelo ETL** (26/09/2026, professor e CIE)
Antes a ideia era tratar planilhas xlsx exportadas. O CIE vai montar um Oracle, a gente extrai dele, trata e carrega num banco final. O escopo continua o mesmo (motor de tratamento), só mudou de onde o dado vem.

**D03. Enquanto o Oracle do CIE não chega, usamos um Oracle local com o CSV de dados abertos** (out/2026)
O CSV (113.016 registros, jan a jul/2026) que o Gabriel mandou é carregado num Oracle Free no Docker. Ele é um dublê do banco real, não uma entrada do sistema. Risco: o banco real pode ter várias tabelas em vez de uma só, e aí a `FonteOracle` muda.

**D04. Fora do escopo: dashboard, telas e usuários** (25/09/2026, triagem do slide 5 do CIE)
O slide do CIE mostrava um MVP maior. Ficou dentro: tratamento, PostgreSQL, Docker, relatório de qualidade e histórico de execuções em JSON pro Airflow. Ficou fora: coleta automática, dashboard e segmentação por usuário.

**D05. O dado não permite calcular tempo de resposta** (set/2026, análise da base)
A base não tem horários de cada etapa do atendimento nem ID da ocorrência. Qualquer promessa de indicador de tempo de resposta precisa de outro dado do CIE.

## Arquitetura

**D06. C#/ASP.NET, PostgreSQL, Docker e Airflow** (cliente e disciplina)
C# é exigência da disciplina. PostgreSQL, Docker (gerenciado pelo Portainer) e Airflow foram confirmados com o CIE. O PostgreSQL ainda é "premissa a confirmar" com o cliente, por isso o repositório tem interface (D10).

**D07. Sem login de usuário, a API é protegida por API key** (set/2026)
Quem chama a API é o Airflow, não uma pessoa. Por isso não existe classe `Usuario`, `User` ou `Role`.

**D08. Diagrama de classes completo, com ETL e API separados** (validado com o professor)
Existiam duas versões: uma simples (9 classes, um programa só) e a completa apresentada no SR1. Ficou a completa. O `PipelineETL` roda o ETL e o `Carregador` manda os dados por HTTP POST pra API, que grava pelo repositório.

**D09. Interface `IFonteDeOcorrencias`: isolar o que a gente não controla**
A gente não sabe como o banco do CIE vai ser nem quando chega. Com a interface, o sistema funciona com qualquer fonte (`FonteCsv` em teste, `FonteOracle` em produção) e trocar uma pela outra não quebra o resto.

**D10. Interface `IRepositorioOcorrencias`**
Mesma lógica da D09, do lado da saída. Se o CIE trocar o PostgreSQL por outro banco, só nasce outra classe.

**D11. Exceção é só pra quando a execução inteira para**
Registro com dado errado não gera exceção: as regras corrigem, sinalizam ou rejeitam e a execução segue. As exceções (`ExtracaoException`, `ValidacaoException`, `CargaException`, filhas de `PipelineException`) dizem em qual etapa a execução quebrou.

**D12. Sem Dockerfile: a imagem da API sai do `dotnet publish`** (out/2026, Saulo)
O SDK do .NET gera a imagem direto. O Compose só usa a imagem pronta (ver README).

## Dados e LGPD

**D13. Rejeitar pouco: corrigir e sinalizar primeiro** (US03, 19/10/2026)
Registro com idade impossível ainda tem data, local e tipo que servem pra análise. Só R01 (teste) e R02 (duplicata exata) rejeitam. O resto corrige o valor ou marca uma sinalização, e o analista decide se usa.

**D14. Endereço guardado só como município e bairro** (SR1)
7.759 registros têm número da casa. Junto com hora exata, idade, sexo e tipo clínico, isso identifica o paciente. Por isso a classe `Endereco` não tem rua.

**D15. Logs e relatórios não copiam valores dos registros**
A `Rejeicao` guarda linha, regra e motivo, nunca o conteúdo. Assim o log não vaza dado pessoal.

**D16. Tipos da `Ocorrencia`** (US03)
`Idade` é `int?` (idade impossível vira nula sem perder o registro). `Sexo` é enum com `NAO_INFORMADO` (2.112 vazios). `CodigoDesfecho` é `int?` porque "SEM DESFECHO" não tem número. A base não tem ID, então o `Id` é gerado por nós e o `Hash` serve pra achar duplicata.

## Processo

**D17. Todo PR é revisado por outra pessoa antes do merge** (25/10/2026)
Ninguém faz merge do próprio PR. Antes de começar, atualizar a `main` pra não subir commit em cima de versão velha.

**D18. Diagrama em Mermaid dentro do repositório** (nov/2026)
O PNG antigo (com User/Role) saiu. Texto no repo mostra o que mudou em cada commit e o GitHub desenha sozinho.

**D19. Nome do produto: Pulso 192** (out/2026)
Antes era SAMU DataFlow. O repositório e o site ainda usam o nome antigo no endereço.

## Em aberto

- Esquema real do Oracle do CIE (uma tabela ou várias?). Depende do Gabriel.
- `Rejeicao` ligada à `ExecucaoETL` por agregação ou composição. Perguntar ao professor.
- **Proposta D20, aguardando o professor:** a fonte devolve um `RegistroBruto` (número da linha + as 12 colunas como texto) em vez de `Ocorrencia` pronta. Motivo: várias regras precisam do dado cru (R02 compara as 12 colunas, R03 valida data inválida, R04 pega idade que nem é número, R14 usa o endereço) e a `Rejeicao` precisa do número da linha. O `Transformador` converte `RegistroBruto` em `Ocorrencia` e a rua é descartada ali, então ela só existe em memória durante a execução (D14 continua valendo).
- **Tabela de execuções:** o requisito 4 pede histórico, mas nenhuma classe grava a `ExecucaoETL`. Definir junto com o schema do Postgres.

---

Os textos desta pasta foram escritos com apoio de IA e revisados pelo time.
