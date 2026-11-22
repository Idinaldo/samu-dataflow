using Pulso192.Domain;

namespace Pulso192.Contracts;

/// <summary>Ocorrência disponibilizada pela API sem identificadores diretos.</summary>
public sealed record OcorrenciaResponse(
    Guid Id,
    DateTimeOffset DataHora,
    string Municipio,
    string Bairro,
    string OrigemChamado,
    string Tipo,
    string Subtipo,
    Sexo Sexo,
    int? Idade,
    string? MotivoFinalizacao,
    int? CodigoDesfecho,
    string Desfecho,
    IReadOnlyList<string> Sinalizacoes);

/// <summary>Uma página de ocorrências filtradas.</summary>
public sealed record PaginaOcorrenciasResponse(
    IReadOnlyList<OcorrenciaResponse> Itens,
    int Pagina,
    int TamanhoPagina,
    int Total);

/// <summary>Resumo público de uma execução do pipeline ETL.</summary>
public sealed record ExecucaoResponse(
    Guid Id,
    DateTimeOffset Inicio,
    DateTimeOffset? Fim,
    string Status,
    int TotalLidos,
    int TotalCarregados,
    int TotalRejeitados,
    IReadOnlyDictionary<string, int> PorRegra,
    IReadOnlyList<RejeicaoResponse> Rejeicoes);

/// <summary>Identifica uma linha rejeitada sem reproduzir valores do registro.</summary>
public sealed record RejeicaoResponse(int Linha, string Regra);
