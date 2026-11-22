# Diagrama de classes

```mermaid
classDiagram
    direction LR

    class ExecucoesController {
        -PipelineETL pipeline
        +Executar(CancellationToken) Task~ExecucaoResponse~
    }
    class OcorrenciasController {
        -RepositorioPostgres repositorio
        +Listar(filtros, CancellationToken) Task~PaginaOcorrenciasResponse~
    }
    class PipelineETL {
        -FonteOracle fonte
        -Transformador transformador
        -RepositorioPostgres repositorio
        +ExecutarAsync(CancellationToken) Task~ExecucaoETL~
    }
    class FonteOracle {
        +LerOcorrenciasAsync(CancellationToken) Task~IReadOnlyList~RegistroBruto~~
    }
    class Transformador {
        +Transformar(IReadOnlyList~RegistroBruto~, ExecucaoETL) IReadOnlyList~Ocorrencia~
    }
    class RepositorioPostgres {
        +SalvarLoteAsync(IReadOnlyList~Ocorrencia~, CancellationToken) Task~LotePersistenciaResultado~
        +ListarAsync(filtros, CancellationToken)
    }
    class LotePersistenciaResultado {
        +int Inseridos
        +IReadOnlySet~string~ HashesDuplicados
    }
    class RegistroBruto
    class Ocorrencia
    class Endereco
    class ExecucaoETL
    class Rejeicao
    class PaginaOcorrenciasResponse
    class ExecucaoResponse
    class ApiKeyAuthorizationFilter
    class ApiExceptionHandler

    ExecucoesController --> PipelineETL : inicia POST /execucoes
    OcorrenciasController --> RepositorioPostgres : consulta GET /ocorrencias
    PipelineETL --> FonteOracle : extrai
    PipelineETL --> Transformador : valida e transforma
    PipelineETL --> RepositorioPostgres : grava diretamente
    RepositorioPostgres ..> LotePersistenciaResultado : retorna inserções e duplicatas
    FonteOracle ..> RegistroBruto : lê
    Transformador ..> Ocorrencia : produz
    Transformador ..> ExecucaoETL : registra rejeições
    Ocorrencia *-- Endereco
    ExecucaoETL "1" o-- "*" Rejeicao
    ExecucoesController ..> ExecucaoResponse : retorna resumo
    OcorrenciasController ..> PaginaOcorrenciasResponse : retorna página
    ExecucoesController ..> ApiKeyAuthorizationFilter : protegido
    OcorrenciasController ..> ApiKeyAuthorizationFilter : protegido
    ApiExceptionHandler ..> PipelineException : converte exceções em Problem Details
```

## Fluxo de uma execução

1. `POST /execucoes` passa pelo filtro de API key e chama `PipelineETL`.
2. `FonteOracle` lê as linhas da tabela de origem e o pipeline contabiliza os registros.
3. `Transformador` aplica as regras de qualidade, produz ocorrências válidas e registra as rejeições.
4. `RepositorioPostgres` grava as ocorrências em uma transação. A restrição única do hash impede a duplicação; hashes já existentes são associados às linhas de origem e contabilizados como rejeições R02.
5. O pipeline finaliza e devolve o resumo da execução. `GET /ocorrencias` consulta diretamente o mesmo repositório PostgreSQL.
6. Erros que impedem a execução são convertidos em respostas HTTP pelo `ApiExceptionHandler`.
