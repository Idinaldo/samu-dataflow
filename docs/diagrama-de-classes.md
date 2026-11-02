# Diagrama de classes

Versão completa do diagrama apresentado no SR1, com atributos e métodos. Validada com o professor.

O diagrama fica em Mermaid (texto), não em imagem: o GitHub desenha sozinho e qualquer mudança aparece no histórico de commits.

## Parte 1: entrada, domínio e pipeline

```mermaid
classDiagram
    direction LR

    class IFonteDeOcorrencias {
        <<interface>>
        +LerOcorrencias() List~Ocorrencia~
    }
    class FonteCsv {
        -string caminhoArquivo
        +LerOcorrencias() List~Ocorrencia~
    }
    class FonteOracle {
        -string stringConexao
        -DateTime ultimaExtracao
        +LerOcorrencias() List~Ocorrencia~
    }

    class Ocorrencia {
        +Guid Id
        +DateTime DataHora
        +Endereco Endereco
        +string OrigemChamado
        +string Tipo
        +string Subtipo
        +Sexo Sexo
        +int? Idade
        +string? MotivoFinalizacao
        +int? CodigoDesfecho
        +string Desfecho
        +List~string~ Sinalizacoes
        +string Hash
    }
    class Endereco {
        +string Municipio
        +string Bairro
        +Padronizar()
    }
    class Sexo {
        <<enumeration>>
        NAO_INFORMADO
        MASCULINO
        FEMININO
    }

    class PipelineETL {
        -IFonteDeOcorrencias fonte
        -Transformador transformador
        -Carregador carregador
        +Executar() ExecucaoETL
    }
    class Transformador {
        +Transformar(List~Ocorrencia~ lista, ExecucaoETL execucao) List~Ocorrencia~
        -AplicarRegra(string id, Ocorrencia o)
    }
    class Carregador {
        -string urlApi
        -string apiKey
        +Enviar(List~Ocorrencia~ lista)
    }

    IFonteDeOcorrencias <|.. FonteCsv
    IFonteDeOcorrencias <|.. FonteOracle
    IFonteDeOcorrencias ..> Ocorrencia : retorna
    Ocorrencia *-- Endereco
    Ocorrencia --> Sexo
    PipelineETL --> IFonteDeOcorrencias : usa
    PipelineETL *-- Transformador
    PipelineETL *-- Carregador
```

## Parte 2: API, auditoria e exceções

```mermaid
classDiagram
    direction LR

    class Carregador
    class PipelineETL

    class OcorrenciasController {
        -IRepositorioOcorrencias repositorio
        +Receber(List~Ocorrencia~ lista)
        +Listar(filtro) List~Ocorrencia~
        -ValidarApiKey() bool
    }
    class IRepositorioOcorrencias {
        <<interface>>
        +SalvarLote(List~Ocorrencia~ lista)
        +ExisteHash(string hash) bool
        +Listar(filtro) List~Ocorrencia~
    }
    class RepositorioPostgres {
        -string stringConexao
        +SalvarLote(List~Ocorrencia~ lista)
        +ExisteHash(string hash) bool
        +Listar(filtro) List~Ocorrencia~
    }

    class ExecucaoETL {
        +Guid Id
        +DateTime Inicio
        +DateTime? Fim
        +int TotalLidos
        +int TotalCarregados
        +string Status
        +List~Rejeicao~ Rejeicoes
        +Finalizar()
    }
    class Rejeicao {
        +int Linha
        +string Regra
        +string Motivo
    }
    class RelatorioQualidade {
        +Dictionary~string,int~ PorRegra
        +Gerar(ExecucaoETL execucao) string
    }

    class Exception
    class PipelineException {
        +string Etapa
    }
    class ExtracaoException
    class ValidacaoException
    class CargaException

    Carregador ..> OcorrenciasController : HTTP POST
    PipelineETL ..> ExecucaoETL : gera
    OcorrenciasController --> IRepositorioOcorrencias : usa
    IRepositorioOcorrencias <|.. RepositorioPostgres
    ExecucaoETL "1" o-- "*" Rejeicao
    RelatorioQualidade ..> ExecucaoETL : lê
    Exception <|-- PipelineException
    PipelineException <|-- ExtracaoException
    PipelineException <|-- ValidacaoException
    PipelineException <|-- CargaException
```

## Como ler

| Símbolo | Nome | Significado | Exemplo |
|---|---|---|---|
| `..▷` | Implementação | Cumpre o contrato de uma interface | FonteCsv implementa IFonteDeOcorrencias |
| `—▷` | Herança | É um tipo de outra classe | CargaException é uma PipelineException |
| `—◆` | Composição | A parte não existe sem o todo | Endereco só existe dentro de uma Ocorrencia |
| `—◇` | Agregação | O todo tem partes que fazem sentido sozinhas | ExecucaoETL tem várias Rejeicao |
| `—>` | Associação | Guarda ou usa a outra de forma fixa | OcorrenciasController usa o repositório |
| `..>` | Dependência | Usa a outra só na hora | RelatorioQualidade lê ExecucaoETL |
| `+` / `-` | Público / privado | Quem pode ver | `apiKey` é privado |

## Fluxo de uma execução

1. O Airflow dispara o `PipelineETL.Executar()`. Nasce uma `ExecucaoETL` com status "rodando".
2. A fonte lê (`FonteCsv` em teste, `FonteOracle` em produção). O pipeline não sabe qual.
3. O `Transformador` aplica as regras R01 a R16. O que é recusado vira `Rejeicao`.
4. O `Carregador` manda as ocorrências tratadas por HTTP POST, com a API key, pro `OcorrenciasController`.
5. O controller confere a chave e chama o `RepositorioPostgres`, que descarta duplicatas (`ExisteHash`) e grava em lote.
6. A execução chama `Finalizar()` e o `RelatorioQualidade` gera o JSON que o Airflow mostra.
7. Se algo quebrar, sai uma `PipelineException` (ou filha) dizendo a etapa, e a execução fica com status "falha".

Registro com dado errado **não** gera exceção: isso é das regras (corrige, sinaliza ou rejeita). Exceção é só quando a execução inteira não consegue seguir.
