using Npgsql;
using Pulso192.Domain;

namespace Pulso192.Infrastructure;

public sealed class PostgresDatabaseInitializer(IConfiguration configuration) : IHostedService
{
    public async Task StartAsync(CancellationToken cancellationToken)
    {
        var connectionString = configuration.GetConnectionString("Postgres");
        if (string.IsNullOrWhiteSpace(connectionString))
            throw new CargaException("A conexão com o banco PostgreSQL não está configurada.");

        var caminhoSchema = Path.Combine(AppContext.BaseDirectory, "Database", "Postgres", "001-schema.sql");
        try
        {
            var schema = await File.ReadAllTextAsync(caminhoSchema, cancellationToken);
            await using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync(cancellationToken);
            await using var command = new NpgsqlCommand(schema, connection);
            await command.ExecuteNonQueryAsync(cancellationToken);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (NpgsqlException exception)
        {
            throw new CargaException("Não foi possível inicializar o banco PostgreSQL.", exception);
        }
    }

    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
