using Npgsql;
using NpgsqlTypes;
using Pulso192.Domain;

namespace Pulso192.Infrastructure;

public sealed class RepositorioPostgres(IConfiguration configuration)
{
    private const string InserirSql = """
        INSERT INTO ocorrencias (
            id, data_hora, municipio, bairro, origem_chamado, tipo, subtipo,
            sexo, idade, motivo_finalizacao, codigo_desfecho, desfecho,
            sinalizacoes, hash)
        VALUES (
            @id, @data_hora, @municipio, @bairro, @origem_chamado, @tipo, @subtipo,
            @sexo, @idade, @motivo_finalizacao, @codigo_desfecho, @desfecho,
            @sinalizacoes, @hash)
        ON CONFLICT (hash) DO NOTHING
        RETURNING hash
        """;

    public async Task<LotePersistenciaResultado> SalvarLoteAsync(
        IReadOnlyList<Ocorrencia> ocorrencias,
        CancellationToken cancellationToken)
    {
        var connectionString = ObterConnectionString();
        var hashesDuplicados = new HashSet<string>(StringComparer.Ordinal);
        var inseridos = 0;

        try
        {
            await using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync(cancellationToken);
            await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

            foreach (var ocorrencia in ocorrencias)
            {
                await using var command = new NpgsqlCommand(InserirSql, connection, transaction);
                AdicionarParametros(command, ocorrencia);

                await using var reader = await command.ExecuteReaderAsync(cancellationToken);
                if (await reader.ReadAsync(cancellationToken))
                    inseridos++;
                else
                    hashesDuplicados.Add(ocorrencia.Hash);
            }

            await transaction.CommitAsync(cancellationToken);
            return new LotePersistenciaResultado(inseridos, hashesDuplicados);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (NpgsqlException exception)
        {
            throw new CargaException("Não foi possível persistir o lote no PostgreSQL.", exception);
        }
    }

    public async Task<(IReadOnlyList<Ocorrencia> Itens, int Total)> ListarAsync(
        int pagina,
        int tamanhoPagina,
        string? municipio,
        string? bairro,
        CancellationToken cancellationToken)
    {
        const string filtro = """
            WHERE (@municipio IS NULL OR municipio = @municipio)
              AND (@bairro IS NULL OR bairro = @bairro)
            """;

        try
        {
            await using var connection = new NpgsqlConnection(ObterConnectionString());
            await connection.OpenAsync(cancellationToken);

            await using var countCommand = new NpgsqlCommand($"SELECT COUNT(*) FROM ocorrencias {filtro}", connection);
            AdicionarFiltros(countCommand, municipio, bairro);
            var total = Convert.ToInt32(await countCommand.ExecuteScalarAsync(cancellationToken));

            const string listarSql = """
                SELECT id, data_hora, municipio, bairro, origem_chamado, tipo, subtipo,
                       sexo, idade, motivo_finalizacao, codigo_desfecho, desfecho, sinalizacoes
                  FROM ocorrencias
                
                """ + filtro + """
                 ORDER BY data_hora DESC, id
                 LIMIT @limite OFFSET @offset
                """;

            await using var listCommand = new NpgsqlCommand(listarSql, connection);
            AdicionarFiltros(listCommand, municipio, bairro);
            listCommand.Parameters.AddWithValue("limite", tamanhoPagina);
            listCommand.Parameters.AddWithValue("offset", (long)(pagina - 1) * tamanhoPagina);

            var itens = new List<Ocorrencia>();
            await using var reader = await listCommand.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
                itens.Add(MapearOcorrencia(reader));

            return (itens, total);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (NpgsqlException exception)
        {
            throw new CargaException("Não foi possível consultar as ocorrências no PostgreSQL.", exception);
        }
    }

    private string ObterConnectionString()
    {
        var connectionString = configuration.GetConnectionString("Postgres");
        return !string.IsNullOrWhiteSpace(connectionString)
            ? connectionString
            : throw new CargaException("A conexão com o banco PostgreSQL não está configurada.");
    }

    private static void AdicionarParametros(NpgsqlCommand command, Ocorrencia ocorrencia)
    {
        var horarioRecife = DateTime.SpecifyKind(ocorrencia.DataHora, DateTimeKind.Unspecified);
        var horarioUtc = new DateTimeOffset(horarioRecife, TimeSpan.FromHours(-3)).UtcDateTime;

        command.Parameters.AddWithValue("id", NpgsqlDbType.Uuid, ocorrencia.Id);
        command.Parameters.AddWithValue("data_hora", NpgsqlDbType.TimestampTz, horarioUtc);
        command.Parameters.AddWithValue("municipio", NpgsqlDbType.Text, ocorrencia.Endereco.Municipio);
        command.Parameters.AddWithValue("bairro", NpgsqlDbType.Text, ocorrencia.Endereco.Bairro);
        command.Parameters.AddWithValue("origem_chamado", NpgsqlDbType.Text, ocorrencia.OrigemChamado);
        command.Parameters.AddWithValue("tipo", NpgsqlDbType.Text, ocorrencia.Tipo);
        command.Parameters.AddWithValue("subtipo", NpgsqlDbType.Text, ocorrencia.Subtipo);
        command.Parameters.AddWithValue("sexo", NpgsqlDbType.Text, ocorrencia.Sexo.ToString());
        command.Parameters.AddWithValue("idade", NpgsqlDbType.Integer, (object?)ocorrencia.Idade ?? DBNull.Value);
        command.Parameters.AddWithValue("motivo_finalizacao", NpgsqlDbType.Text, (object?)ocorrencia.MotivoFinalizacao ?? DBNull.Value);
        command.Parameters.AddWithValue("codigo_desfecho", NpgsqlDbType.Integer, (object?)ocorrencia.CodigoDesfecho ?? DBNull.Value);
        command.Parameters.AddWithValue("desfecho", NpgsqlDbType.Text, ocorrencia.Desfecho);
        command.Parameters.AddWithValue("sinalizacoes", NpgsqlDbType.Array | NpgsqlDbType.Text, ocorrencia.Sinalizacoes.ToArray());
        command.Parameters.AddWithValue("hash", NpgsqlDbType.Varchar, ocorrencia.Hash);
    }

    private static void AdicionarFiltros(NpgsqlCommand command, string? municipio, string? bairro)
    {
        command.Parameters.Add("municipio", NpgsqlDbType.Text).Value = (object?)municipio ?? DBNull.Value;
        command.Parameters.Add("bairro", NpgsqlDbType.Text).Value = (object?)bairro ?? DBNull.Value;
    }

    private static Ocorrencia MapearOcorrencia(NpgsqlDataReader reader)
    {
        var horaUtc = reader.GetDateTime(1);
        var horaRecife = DateTime.SpecifyKind(horaUtc.AddHours(-3), DateTimeKind.Unspecified);

        return new Ocorrencia
        {
            Id = reader.GetGuid(0),
            DataHora = horaRecife,
            Endereco = new Endereco
            {
                Municipio = reader.GetString(2),
                Bairro = reader.GetString(3)
            },
            OrigemChamado = reader.GetString(4),
            Tipo = reader.GetString(5),
            Subtipo = reader.GetString(6),
            Sexo = Enum.Parse<Sexo>(reader.GetString(7), ignoreCase: false),
            Idade = reader.IsDBNull(8) ? null : reader.GetInt32(8),
            MotivoFinalizacao = reader.IsDBNull(9) ? null : reader.GetString(9),
            CodigoDesfecho = reader.IsDBNull(10) ? null : reader.GetInt32(10),
            Desfecho = reader.GetString(11),
            Sinalizacoes = reader.GetFieldValue<string[]>(12).ToList(),
            Hash = string.Empty
        };
    }
}

public sealed record LotePersistenciaResultado(int Inseridos, IReadOnlySet<string> HashesDuplicados);
