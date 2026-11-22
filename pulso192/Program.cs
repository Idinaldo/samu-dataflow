using System.Text.Json.Serialization;
using Pulso192.Configuration;
using Pulso192.Infrastructure;
using Pulso192.Middleware;
using Pulso192.Pipeline;

namespace Pulso192;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        builder.Services.AddControllers()
            .AddJsonOptions(options =>
                options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter()));
        builder.Services.AddOpenApi();
        builder.Services.AddProblemDetails();
        builder.Services.AddExceptionHandler<ApiExceptionHandler>();

        builder.Services.AddOptions<Pulso192Options>()
            .Bind(builder.Configuration.GetSection(Pulso192Options.SectionName))
            .Validate(options => !string.IsNullOrWhiteSpace(options.ApiKey), "A chave da API não foi configurada.")
            .ValidateOnStart();

        builder.Services.AddSingleton<ApiKeyValidator>();
        builder.Services.AddScoped<ApiKeyAuthorizationFilter>();
        builder.Services.AddScoped<RepositorioPostgres>();
        builder.Services.AddScoped<FonteOracle>();
        builder.Services.AddScoped<Transformador>();
        builder.Services.AddScoped<PipelineETL>();
        builder.Services.AddHostedService<PostgresDatabaseInitializer>();

        var app = builder.Build();

        app.UseExceptionHandler();
        app.UseStatusCodePages();

        if (app.Environment.IsDevelopment())
            app.MapOpenApi();

        app.MapControllers();

        app.Run();
    }
}