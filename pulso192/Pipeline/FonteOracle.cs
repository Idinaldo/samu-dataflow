using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Oracle.ManagedDataAccess.Client;
using Microsoft.Extensions.Options;
using Pulso192.Configuration;
using Pulso192.Domain;

namespace Pulso192.Pipeline;

public sealed class FonteOracle(
    IConfiguration configuration,
    IOptions<Pulso192Options> options)
{
    private const string Consulta = """
        SELECT "OCORRÊNCIA", "DATA/HORA CRIAÇÃO", "PACIENTE", "IDADE", "SEXO",
               "SOLICITANTE", "TELEFONE", "ENDEREÇO", "ORIGEM DA CHAMADA", "BAIRRO",
               "MUNICÍPIO", "PONTO DE REFERÊNCIA", "DATA/HORA REGULAÇÃO",
               "CÓD./DESCRIÇÃO TIPO", "CÓD./DESCRIÇÃO SUBTIPO", "CLASSIFICAÇÃO DE RISCO",
               "QUEIXA", "RECOMENDAÇÕES", "DESPACHO", "FINALIZAÇÃO",
               "DATA/HORA QUADRO CLÍNICO", "PRESSÃO", "PULSO", "TEMPERATURA",
               "F.RESP.", "HGT", "SPO", "GLASGOW", "OBSERVAÇÕES",
               "DATA/HORA AÇÃO MÉDICA", "AÇÃO", "DATA/HORA HOSPITAL DESTINO",
               "MÉDICO", "HOSPITAL", "MOTIVO DE RECUSA", "REGIÃO"
          FROM {0}.{1}
         ORDER BY "DATA/HORA CRIAÇÃO", "OCORRÊNCIA"
        """;

    public async Task<IReadOnlyList<RegistroBruto>> LerOcorrenciasAsync(CancellationToken cancellationToken)
    {
        var connectionString = configuration.GetConnectionString("Oracle");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new ExtracaoException("A conexão com a origem Oracle não está configurada.");

        var schema = options.Value.OracleSchema;
        var table = options.Value.OracleTable;
        if (!IsValidIdentifier(schema) || !IsValidIdentifier(table))
            throw new ExtracaoException("O schema ou a tabela da origem Oracle não está configurado corretamente.");

        try
        {
            await using var connection = new OracleConnection(connectionString);
            await connection.OpenAsync(cancellationToken);

            await using var command = connection.CreateCommand();
            command.CommandText = string.Format(CultureInfo.InvariantCulture, Consulta, schema, table);

            await using var reader = await command.ExecuteReaderAsync(cancellationToken);
            var ocorrencias = new List<RegistroBruto>();
            var linha = 0;

            while (await reader.ReadAsync(cancellationToken))
            {
                linha++;
                var valores = new object[reader.FieldCount];
                reader.GetValues(valores);

                var dataHora = reader.GetDateTime(1);
                var enderecoBruto = TextoOuNulo(reader, 7);

                ocorrencias.Add(new RegistroBruto(
                    linha,
                    dataHora,
                    TextoOuNulo(reader, 3),
                    TextoOuNulo(reader, 4),
                    TextoOuNulo(reader, 8),
                    TextoOuNulo(reader, 10),
                    TextoOuNulo(reader, 9),
                    TextoOuNulo(reader, 13),
                    TextoOuNulo(reader, 14),
                    TextoOuNulo(reader, 19),
                    null,
                    GerarHash(valores),
                    string.IsNullOrWhiteSpace(enderecoBruto)
                        ? string.Empty
                        : GerarHash([dataHora, enderecoBruto])));
            }

            return ocorrencias;
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (OracleException exception)
        {
            throw new ExtracaoException("Não foi possível ler as ocorrências da origem Oracle.", exception);
        }
    }

    private static bool IsValidIdentifier(string value) =>
        !string.IsNullOrWhiteSpace(value)
        && Regex.IsMatch(value, @"\A[A-Za-z][A-Za-z0-9_$#]*\z", RegexOptions.CultureInvariant);

    private static string? TextoOuNulo(OracleDataReader reader, int ordinal) =>
        reader.IsDBNull(ordinal) ? null : reader.GetString(ordinal);

    private static string GerarHash(IEnumerable<object?> valores)
    {
        var conteudo = new StringBuilder();

        foreach (var valor in valores)
        {
            if (valor is null or DBNull)
            {
                conteudo.Append("N;");
                continue;
            }

            var texto = valor switch
            {
                DateTime dataHora => dataHora.ToString("O", CultureInfo.InvariantCulture),
                _ => Convert.ToString(valor, CultureInfo.InvariantCulture) ?? string.Empty
            };

            conteudo.Append(texto.Length)
                .Append(':')
                .Append(texto)
                .Append(';');
        }

        return Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(conteudo.ToString())));
    }
}
