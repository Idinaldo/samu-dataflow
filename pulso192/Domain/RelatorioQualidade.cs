using System.Text.Json;

namespace Pulso192.Domain;

public sealed class RelatorioQualidade
{
    public Dictionary<string, int> PorRegra { get; private set; } = new(StringComparer.Ordinal);

    public RelatorioQualidadeResultado Criar(ExecucaoETL execucao)
    {
        ArgumentNullException.ThrowIfNull(execucao);

        PorRegra = execucao.Rejeicoes
            .GroupBy(rejeicao => rejeicao.Regra, StringComparer.Ordinal)
            .ToDictionary(grupo => grupo.Key, grupo => grupo.Count(), StringComparer.Ordinal);

        return new RelatorioQualidadeResultado(
            execucao.TotalLidos,
            execucao.TotalCarregados,
            execucao.Rejeicoes.Count,
            PorRegra,
            execucao.Rejeicoes
                .Select(rejeicao => new RejeicaoResumo(rejeicao.Linha, rejeicao.Regra))
                .ToArray());
    }

    public string Gerar(ExecucaoETL execucao)
    {
        ArgumentNullException.ThrowIfNull(execucao);

        var resultado = Criar(execucao);
        return JsonSerializer.Serialize(resultado, new JsonSerializerOptions(JsonSerializerDefaults.Web));
    }
}

public sealed record RelatorioQualidadeResultado(
    int TotalLidos,
    int TotalCarregados,
    int TotalRejeitados,
    IReadOnlyDictionary<string, int> PorRegra,
    IReadOnlyList<RejeicaoResumo> Rejeicoes);

public sealed record RejeicaoResumo(int Linha, string Regra);
