using Pulso192.Domain;
using Pulso192.Pipeline;

namespace Pulso192.Tests;

// T06: testes das regras R01 a R04 do Transformador (docs/regras-de-qualidade.md)
public class TransformadorR01aR04Tests
{
    private static readonly DateTime DataValida = new(2026, 1, 10, 8, 30, 0);

    private static RegistroBruto Registro(
        int linha = 1,
        string? tipo = "CLINICO",
        string? subtipo = "DOR TORACICA",
        string? idade = "30 Anos",
        bool dataInvalida = false,
        string? hash = null) =>
        new(
            Linha: linha,
            DataHora: dataInvalida ? default : DataValida,
            Idade: idade,
            Sexo: "MASCULINO",
            OrigemChamado: "RESIDENCIAL",
            Municipio: "RECIFE",
            Bairro: "BOA VISTA",
            Tipo: tipo,
            Subtipo: subtipo,
            Finalizacao: "ENCERRAMENTO / 1. OCORRENCIA CONCLUIDA COM EXITO",
            MotivoFinalizacao: null,
            HashCompleto: hash ?? $"hash-{linha}",
            ChavePossivelDuplicata: $"chave-{linha}");

    private static (IReadOnlyList<Ocorrencia> Ocorrencias, ExecucaoETL Execucao) Rodar(params RegistroBruto[] registros)
    {
        var execucao = new ExecucaoETL();
        var ocorrencias = new Transformador().Transformar(registros, execucao);
        return (ocorrencias, execucao);
    }

    // R01: registro de teste
    [Theory]
    [InlineData("TESTE", "DOR")]
    [InlineData("CLINICO", "teste de sistema")]
    public void R01_RejeitaRegistroDeTeste(string tipo, string subtipo)
    {
        var (ocorrencias, execucao) = Rodar(Registro(tipo: tipo, subtipo: subtipo));

        Assert.Empty(ocorrencias);
        var rejeicao = Assert.Single(execucao.Rejeicoes);
        Assert.Equal("R01", rejeicao.Regra);
        Assert.Equal(1, rejeicao.Linha);
    }

    [Fact]
    public void R01_NaoRejeitaRegistroNormal()
    {
        var (ocorrencias, execucao) = Rodar(Registro());

        Assert.Single(ocorrencias);
        Assert.Empty(execucao.Rejeicoes);
    }

    // R02: duplicata exata
    [Fact]
    public void R02_RejeitaSegundaCopiaComMesmoHash()
    {
        var (ocorrencias, execucao) = Rodar(
            Registro(linha: 1, hash: "igual"),
            Registro(linha: 2, hash: "igual"));

        Assert.Single(ocorrencias);
        var rejeicao = Assert.Single(execucao.Rejeicoes);
        Assert.Equal("R02", rejeicao.Regra);
        Assert.Equal(2, rejeicao.Linha);
    }

    [Fact]
    public void R02_MantemRegistrosComHashDiferente()
    {
        var (ocorrencias, execucao) = Rodar(Registro(linha: 1), Registro(linha: 2));

        Assert.Equal(2, ocorrencias.Count);
        Assert.Empty(execucao.Rejeicoes);
    }

    // R03: data + hora
    [Fact]
    public void R03_RejeitaDataHoraInvalida()
    {
        var (ocorrencias, execucao) = Rodar(Registro(dataInvalida: true));

        Assert.Empty(ocorrencias);
        Assert.Equal("R03", Assert.Single(execucao.Rejeicoes).Regra);
    }

    [Fact]
    public void R03_PreservaDataHoraValida()
    {
        var (ocorrencias, _) = Rodar(Registro());

        Assert.Equal(DataValida, Assert.Single(ocorrencias).DataHora);
    }

    // R04: idade fora de 0 a 110
    [Theory]
    [InlineData("-1")]
    [InlineData("111")]
    [InlineData("150 Anos")]
    public void R04_IdadeForaDaFaixaViraNulaESinaliza(string idade)
    {
        var ocorrencia = Assert.Single(Rodar(Registro(idade: idade)).Ocorrencias);

        Assert.Null(ocorrencia.Idade);
        Assert.Contains("idade_invalida", ocorrencia.Sinalizacoes);
    }

    [Theory]
    [InlineData("0", 0)]
    [InlineData("110", 110)]
    [InlineData("45 Anos", 45)]
    [InlineData("8 Meses", 0)]
    public void R04_IdadeDentroDaFaixaEhMantida(string idade, int esperado)
    {
        var ocorrencia = Assert.Single(Rodar(Registro(idade: idade)).Ocorrencias);

        Assert.Equal(esperado, ocorrencia.Idade);
        Assert.DoesNotContain("idade_invalida", ocorrencia.Sinalizacoes);
    }

    [Fact]
    public void R04_IdadeVaziaFicaNulaSemSinalizar()
    {
        var ocorrencia = Assert.Single(Rodar(Registro(idade: null)).Ocorrencias);

        Assert.Null(ocorrencia.Idade);
        Assert.DoesNotContain("idade_invalida", ocorrencia.Sinalizacoes);
    }

    // Integridade: sem hash a linha não entra
    [Fact]
    public void Transformar_SemHash_LancaExcecao()
    {
        Assert.ThrowsAny<Exception>(() => Rodar(Registro(hash: " ")));
    }
}
