using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;
using Pulso192.Contracts;
using Pulso192.Domain;
using Pulso192.Infrastructure;
using Pulso192.Middleware;

namespace Pulso192.Controllers;

[ApiController]
[Route("ocorrencias")]
[ServiceFilter(typeof(ApiKeyAuthorizationFilter))]
public sealed class OcorrenciasController(RepositorioPostgres repositorio) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType<PaginaOcorrenciasResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<PaginaOcorrenciasResponse>> Listar(
        [FromQuery, Range(1, int.MaxValue)] int pagina = 1,
        [FromQuery, Range(1, 100)] int tamanhoPagina = 50,
        [FromQuery, StringLength(100)] string? municipio = null,
        [FromQuery, StringLength(100)] string? bairro = null,
        [FromQuery] DateOnly? dataInicio = null,
        [FromQuery] DateOnly? dataFim = null,
        CancellationToken cancellationToken = default)
    {
        if (dataInicio is not null && dataFim is not null && dataInicio > dataFim)
            return BadRequest("dataInicio não pode ser maior que dataFim.");

        var (itens, total) = await repositorio.ListarAsync(
            pagina,
            tamanhoPagina,
            NormalizarFiltro(municipio),
            NormalizarFiltro(bairro),
            InicioDoDiaRecife(dataInicio),
            InicioDoDiaRecife(dataFim?.AddDays(1)),
            cancellationToken);

        var resposta = new PaginaOcorrenciasResponse(
            itens.Select(MapearResposta).ToArray(),
            pagina,
            tamanhoPagina,
            total);
        return Ok(resposta);
    }

    private static OcorrenciaResponse MapearResposta(Ocorrencia ocorrencia)
    {
        var dataHoraLocal = DateTime.SpecifyKind(ocorrencia.DataHora, DateTimeKind.Unspecified);
        var dataHoraRecife = new DateTimeOffset(dataHoraLocal, TimeSpan.FromHours(-3));

        return new OcorrenciaResponse(
            ocorrencia.Id,
            dataHoraRecife,
            ocorrencia.Endereco.Municipio,
            ocorrencia.Endereco.Bairro,
            ocorrencia.OrigemChamado,
            ocorrencia.Tipo,
            ocorrencia.Subtipo,
            ocorrencia.Sexo,
            ocorrencia.Idade,
            ocorrencia.MotivoFinalizacao,
            ocorrencia.CodigoDesfecho,
            ocorrencia.Desfecho,
            ocorrencia.Sinalizacoes);
    }

    // Datas chegam no horário de Recife (UTC-3); o banco guarda timestamptz em UTC.
    private static DateTime? InicioDoDiaRecife(DateOnly? data) =>
        data is null
            ? null
            : new DateTimeOffset(data.Value.ToDateTime(TimeOnly.MinValue), TimeSpan.FromHours(-3)).UtcDateTime;

    private static string? NormalizarFiltro(string? valor) =>
        string.IsNullOrWhiteSpace(valor) ? null : valor.Trim().ToUpperInvariant();
}