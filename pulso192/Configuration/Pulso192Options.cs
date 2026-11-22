namespace Pulso192.Configuration;

public sealed class Pulso192Options
{
    public const string SectionName = "Pulso192";

    public string ApiKey { get; set; } = string.Empty;
    public string OracleSchema { get; set; } = "SYSTEM";
    public string OracleTable { get; set; } = "SAMU_OCORRENCIA_BRONZE";
}
