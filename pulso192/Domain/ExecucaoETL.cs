namespace Pulso192.Domain;

public sealed class ExecucaoETL
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime Inicio { get; set; } = DateTime.UtcNow;
    public DateTime? Fim { get; private set; }
    public int TotalLidos { get; set; }
    public int TotalCarregados { get; set; }
    public string Status { get; set; } = "rodando";
    public List<Rejeicao> Rejeicoes { get; set; } = [];

    public void Finalizar()
    {
        if (Fim.HasValue)
            return;

        Fim = DateTime.UtcNow;
        Status = "concluida";
    }

    public void Falhar()
    {
        if (Fim.HasValue)
            return;

        Fim = DateTime.UtcNow;
        Status = "falha";
    }
}

public sealed record Rejeicao(int Linha, string Regra, string Motivo);
