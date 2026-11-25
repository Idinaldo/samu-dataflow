namespace Pulso192.Pipeline;

public sealed record RegistroBruto(
    int Linha,
    DateTime DataHora,
    string? Idade,
    string? Sexo,
    string? OrigemChamado,
    string? Municipio,
    string? Bairro,
    string? Tipo,
    string? Subtipo,
    string? Finalizacao,
    string? MotivoFinalizacao,
    string HashCompleto,
    string ChavePossivelDuplicata);
