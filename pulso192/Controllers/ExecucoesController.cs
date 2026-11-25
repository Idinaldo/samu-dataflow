using Microsoft.AspNetCore.Mvc;
using Pulso192.Contracts;
using Pulso192.Domain;
using Pulso192.Middleware;
using Pulso192.Pipeline;

namespace Pulso192.Controllers;

[ApiController]
[Route("execucoes")]
[ServiceFilter(typeof(ApiKeyAuthorizationFilter))]
public sealed class ExecucoesController(PipelineETL pipeline) : ControllerBase
{
    [HttpPost]
    [ProducesResponseType<ExecucaoResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<ExecucaoResponse>> Executar(CancellationToken cancellationToken)
    {
        var execucao = await pipeline.ExecutarAsync(cancellationToken);
        var relatorio = new RelatorioQualidade().Criar(execucao);

        return Ok(new ExecucaoResponse(
            execucao.Id,
            ParaUtc(execucao.Inicio),
            execucao.Fim is null ? null : ParaUtc(execucao.Fim.Value),
            execucao.Status,
            relatorio.TotalLidos,
            relatorio.TotalCarregados,
            relatorio.TotalRejeitados,
            relatorio.PorRegra,
            relatorio.Rejeicoes
                .Select(rejeicao => new RejeicaoResponse(rejeicao.Linha, rejeicao.Regra))
                .ToArray()));
    }

    private static DateTimeOffset ParaUtc(DateTime valor) =>
        new(DateTime.SpecifyKind(valor, DateTimeKind.Utc));
}
