namespace Pulso192.Models;

// Ocorrência depois de tratada pelo motor (o "T" do ETL), pronta pra ir pro PostgreSQL.
// Campos seguem o dicionário da US03 (docs/regras-de-qualidade.md) e o diagrama
// de classes (docs/diagrama-de-classes.md).
// Propriedades públicas: com campos privados o JSON da API saía como {}.
public class Ocorrencia
{
    // A base do SAMU não tem ID, então a gente gera
    public Guid Id { get; set; } = Guid.NewGuid();

    // R03: data + hora_minuto viram um campo só
    public DateTime DataHora { get; set; }

    // Só município e bairro, sem a rua (LGPD). R07, R08
    public Endereco Endereco { get; set; } = new();

    // R06: fora da lista vira "NAO INFORMADO"
    public string OrigemChamado { get; set; } = string.Empty;

    // R01: "TESTE" aqui ou no subtipo rejeita o registro
    public string Tipo { get; set; } = string.Empty;

    // R10: vazio vira "NAO INFORMADO"
    public string Subtipo { get; set; } = string.Empty;

    // R05: vazio vira NAO_INFORMADO
    public Sexo Sexo { get; set; } = Sexo.NAO_INFORMADO;

    // R04: fora de 0 a 110 vira null
    public int? Idade { get; set; }

    // 99,9% vazia na base. R16
    public string? MotivoFinalizacao { get; set; }

    // R13: "1. OCORRÊNCIA..." vira código 1 + texto.
    // null quando é "SEM DESFECHO" (115 registros, sem número)
    public int? CodigoDesfecho { get; set; }
    public string Desfecho { get; set; } = string.Empty;

    // Marcações das regras: "idade_invalida", "trote", etc.
    // O registro carrega, o analista decide se usa. R04, R06, R07, R08, R11, R12, R14, R15, R16
    public List<string> Sinalizacoes { get; set; } = new();

    // "Impressão digital" do registro pra achar duplicata. R02
    public string Hash { get; set; } = string.Empty;
}
