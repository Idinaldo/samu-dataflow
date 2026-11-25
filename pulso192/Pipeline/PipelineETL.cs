using Pulso192.Domain;
using Pulso192.Infrastructure;

namespace Pulso192.Pipeline;

public sealed class PipelineETL(
    FonteOracle fonte,
    Transformador transformador,
    RepositorioPostgres repositorio)
{
    public async Task<ExecucaoETL> ExecutarAsync(CancellationToken cancellationToken)
    {
        var execucao = new ExecucaoETL();

        try
        {
            var registros = await fonte.LerOcorrenciasAsync(cancellationToken);
            execucao.TotalLidos = registros.Count;

            var linhasPorHash = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var registro in registros)
                linhasPorHash.TryAdd(registro.HashCompleto, registro.Linha);

            var ocorrencias = transformador.Transformar(registros, execucao);
            if (ocorrencias.Count == 0)
            {
                execucao.Finalizar();
                return execucao;
            }

            var resultadoCarga = await repositorio.SalvarLoteAsync(ocorrencias, cancellationToken);
            if (resultadoCarga.Inseridos + resultadoCarga.HashesDuplicados.Count != ocorrencias.Count)
                throw new CargaException("O PostgreSQL retornou totais inconsistentes para o lote.");

            foreach (var hash in resultadoCarga.HashesDuplicados)
            {
                if (!linhasPorHash.TryGetValue(hash, out var linha))
                    throw new CargaException("Não foi possível associar uma duplicata à linha de origem.");

                execucao.Rejeicoes.Add(new Rejeicao(linha, "R02", "Duplicata exata já carregada."));
            }

            execucao.TotalCarregados = resultadoCarga.Inseridos;
            execucao.Finalizar();
            return execucao;
        }
        catch (OperationCanceledException)
        {
            execucao.Falhar();
            throw;
        }
        catch (PipelineException)
        {
            execucao.Falhar();
            throw;
        }
    }
}
