using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Npgsql;
using Oracle.ManagedDataAccess.Client;
using Pulso192.Domain;

namespace Pulso192.Middleware;

public sealed class ApiExceptionHandler(
    ILogger<ApiExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        if (exception is OperationCanceledException && httpContext.RequestAborted.IsCancellationRequested)
            return false;

        var (statusCode, title, detail) = exception switch
        {
            ArgumentException => (
                StatusCodes.Status400BadRequest,
                "Solicitação inválida",
                "Revise os parâmetros enviados."),
            ExtracaoException => (
                StatusCodes.Status503ServiceUnavailable,
                "Origem indisponível",
                "Não foi possível ler os dados da origem."),
            CargaException => (
                StatusCodes.Status503ServiceUnavailable,
                "Destino indisponível",
                "Não foi possível concluir a operação no banco de destino."),
            ValidacaoException => (
                StatusCodes.Status500InternalServerError,
                "Falha na validação do pipeline",
                "A execução não pôde ser concluída."),
            PipelineException => (
                StatusCodes.Status500InternalServerError,
                "Falha no pipeline",
                "A execução não pôde ser concluída."),
            OperationCanceledException => (
                StatusCodes.Status504GatewayTimeout,
                "Tempo esgotado",
                "Um serviço necessário excedeu o tempo limite."),
            _ => (
                StatusCodes.Status500InternalServerError,
                "Erro interno",
                "Ocorreu um erro interno ao processar a solicitação.")
        };

        if (exception is PipelineException pipelineException)
        {
            var diagnostico = pipelineException.InnerException switch
            {
                OracleException oracleException => $"Oracle {oracleException.Number}",
                PostgresException postgresException => $"PostgreSQL {postgresException.SqlState}",
                HttpRequestException httpException => $"HTTP {(int?)httpException.StatusCode}",
                Exception innerException => innerException.GetType().Name,
                _ => pipelineException.GetType().Name
            };
            logger.LogError(
                "Pipeline falhou na etapa {Etapa} ({Diagnostico}).",
                pipelineException.Etapa,
                diagnostico);
        }
        else
            logger.LogError("Falha na API do tipo {TipoErro}.", exception.GetType().Name);

        httpContext.Response.StatusCode = statusCode;
        await httpContext.Response.WriteAsJsonAsync(new ProblemDetails
        {
            Status = statusCode,
            Title = title,
            Detail = detail,
            Instance = httpContext.Request.Path
        }, cancellationToken);

        return true;
    }
}
