using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Pulso192.Domain;

namespace Pulso192.Pipeline;

public sealed class Transformador
{
    private static readonly Dictionary<string, string> OrigensPermitidas = new(StringComparer.Ordinal)
    {
        ["RESIDENCIAL"] = "RESIDENCIAL",
        ["VIA PUBLICA"] = "VIA PÚBLICA",
        ["UNIDADE DE SAUDE"] = "UNIDADE DE SAÚDE",
        ["ESTAB PR"] = "ESTAB PR",
        ["ESTAB PU"] = "ESTAB PU",
        ["ILPS"] = "ILPS",
        ["ANI/ALI"] = "ANI/ALI"
    };

    public IReadOnlyList<Ocorrencia> Transformar(
        IReadOnlyList<RegistroBruto> registros,
        ExecucaoETL execucao)
    {
        ArgumentNullException.ThrowIfNull(registros);
        ArgumentNullException.ThrowIfNull(execucao);

        var ocorrencias = new List<Ocorrencia>();
        var hashesVistos = new HashSet<string>(StringComparer.Ordinal);
        var duplicatasPossiveis = registros
            .Where(registro => !string.IsNullOrEmpty(registro.ChavePossivelDuplicata))
            .GroupBy(registro => registro.ChavePossivelDuplicata, StringComparer.Ordinal)
            .Where(grupo => grupo.Count() > 1)
            .Select(grupo => grupo.Key)
            .ToHashSet(StringComparer.Ordinal);

        foreach (var registro in registros)
        {
            if (string.IsNullOrWhiteSpace(registro.HashCompleto))
                throw new ValidacaoException("A origem não forneceu o identificador de integridade da linha.");

            if (ContemTeste(registro.Tipo) || ContemTeste(registro.Subtipo))
            {
                execucao.Rejeicoes.Add(new Rejeicao(registro.Linha, "R01", "Registro de teste."));
                continue;
            }

            if (!hashesVistos.Add(registro.HashCompleto))
            {
                execucao.Rejeicoes.Add(new Rejeicao(registro.Linha, "R02", "Duplicata exata."));
                continue;
            }

            if (registro.DataHora == default)
            {
                execucao.Rejeicoes.Add(new Rejeicao(registro.Linha, "R03", "Data e hora inválidas."));
                continue;
            }

            var ocorrencia = CriarOcorrencia(registro);
            AplicarRegras(ocorrencia, registro, duplicatasPossiveis);
            ocorrencias.Add(ocorrencia);
        }

        return ocorrencias;
    }

    private static Ocorrencia CriarOcorrencia(RegistroBruto registro)
    {
        var endereco = new Endereco
        {
            Municipio = registro.Municipio ?? string.Empty,
            Bairro = registro.Bairro ?? string.Empty
        };
        endereco.Padronizar();

        var (codigoDesfecho, desfecho) = SepararDesfecho(registro.Finalizacao);

        return new Ocorrencia
        {
            DataHora = DateTime.SpecifyKind(registro.DataHora, DateTimeKind.Unspecified),
            Endereco = endereco,
            OrigemChamado = NormalizarOrigem(registro.OrigemChamado),
            Tipo = ExtrairCodigo(registro.Tipo),
            Subtipo = ExtrairCodigo(registro.Subtipo),
            Sexo = NormalizarSexo(registro.Sexo),
            Idade = ParsearIdade(registro.Idade),
            MotivoFinalizacao = registro.MotivoFinalizacao,
            CodigoDesfecho = codigoDesfecho,
            Desfecho = desfecho,
            Hash = registro.HashCompleto
        };
    }

    private static void AplicarRegras(
        Ocorrencia ocorrencia,
        RegistroBruto registro,
        HashSet<string> duplicatasPossiveis)
    {
        if (registro.Idade is not null && ParsearIdade(registro.Idade) is int idade && idade is < 0 or > 110)
        {
            ocorrencia.Idade = null;
            ocorrencia.Sinalizacoes.Add("idade_invalida");
        }

        if (!OrigensPermitidas.TryGetValue(NormalizarTexto(registro.OrigemChamado), out var origem))
        {
            ocorrencia.OrigemChamado = "NAO INFORMADO";
            ocorrencia.Sinalizacoes.Add("origem_chamado_invalida");
        }
        else
        {
            ocorrencia.OrigemChamado = origem;
        }

        if (!string.Equals(ocorrencia.Endereco.Municipio, "RECIFE", StringComparison.Ordinal))
            ocorrencia.Sinalizacoes.Add("local_invalido");

        if (string.IsNullOrWhiteSpace(registro.Bairro))
            ocorrencia.Sinalizacoes.Add("bairro_invalido");

        if (string.IsNullOrWhiteSpace(registro.Subtipo))
            ocorrencia.Subtipo = "NAO INFORMADO";

        var desfechoNormalizado = NormalizarTexto(ocorrencia.Desfecho);
        if (ocorrencia.CodigoDesfecho == 2 || desfechoNormalizado.Contains("TROTE", StringComparison.Ordinal))
            ocorrencia.Sinalizacoes.Add("trote");

        if (ocorrencia.CodigoDesfecho == 3 ||
            desfechoNormalizado.Contains("SOLICITACAO DUPLICADA", StringComparison.Ordinal))
            ocorrencia.Sinalizacoes.Add("duplicata_operacional");

        if (duplicatasPossiveis.Contains(registro.ChavePossivelDuplicata))
            ocorrencia.Sinalizacoes.Add("possivel_duplicata");

        if (NormalizarTexto(ocorrencia.Tipo) == "OBSTETRICA" && ocorrencia.Sexo == Sexo.MASCULINO)
            ocorrencia.Sinalizacoes.Add("incoerencia_tipo_sexo");

        if (NormalizarTexto(ocorrencia.MotivoFinalizacao) == "CANCELADA" &&
            desfechoNormalizado.Contains("CONCLUIDA COM EXITO", StringComparison.Ordinal))
            ocorrencia.Sinalizacoes.Add("incoerencia_finalizacao_desfecho");
    }

    private static bool ContemTeste(string? valor) =>
        valor?.Contains("TESTE", StringComparison.OrdinalIgnoreCase) == true;

    private static string ExtrairCodigo(string? valor)
    {
        if (string.IsNullOrWhiteSpace(valor))
            return string.Empty;

        var separador = valor.IndexOf('/');
        var codigo = separador >= 0 ? valor[..separador] : valor;
        return codigo.Trim().ToUpperInvariant();
    }

    private static (int? Codigo, string Texto) SepararDesfecho(string? finalizacao)
    {
        if (string.IsNullOrWhiteSpace(finalizacao))
            return (null, string.Empty);

        var correspondencia = Regex.Match(
            finalizacao,
            @"/\s*(?<codigo>\d+)\.\s*(?<texto>.*)$",
            RegexOptions.CultureInvariant);

        if (!correspondencia.Success)
            return (null, finalizacao.Trim());

        var codigo = int.TryParse(
            correspondencia.Groups["codigo"].Value,
            NumberStyles.None,
            CultureInfo.InvariantCulture,
            out var resultado)
            ? resultado
            : (int?)null;

        return (codigo, correspondencia.Groups["texto"].Value.Trim());
    }

    private static int? ParsearIdade(string? valor)
    {
        if (string.IsNullOrWhiteSpace(valor))
            return null;

        var anos = Regex.Match(valor, @"(?<valor>-?\d+)\s*Anos?", RegexOptions.IgnoreCase);
        var meses = Regex.Match(valor, @"(?<valor>-?\d+)\s*M[eê]ses?", RegexOptions.IgnoreCase);
        var dias = Regex.Match(valor, @"(?<valor>-?\d+)\s*Dias?", RegexOptions.IgnoreCase);

        if (anos.Success || meses.Success || dias.Success)
        {
            var idadeAnos = LerInteiro(anos) + LerInteiro(meses) / 12;
            return idadeAnos + (LerInteiro(dias) / 365);
        }

        var numero = Regex.Match(valor, @"-?\d+");
        return numero.Success && int.TryParse(numero.Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var idade)
            ? idade
            : null;
    }

    private static int LerInteiro(Match correspondencia) =>
        correspondencia.Success &&
        int.TryParse(correspondencia.Groups["valor"].Value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var valor)
            ? valor
            : 0;

    private static Sexo NormalizarSexo(string? valor) =>
        NormalizarTexto(valor) switch
        {
            "MASCULINO" => Sexo.MASCULINO,
            "FEMININO" => Sexo.FEMININO,
            _ => Sexo.NAO_INFORMADO
        };

    private static string NormalizarOrigem(string? valor) =>
        OrigensPermitidas.TryGetValue(NormalizarTexto(valor), out var origem)
            ? origem
            : "NAO INFORMADO";

    private static string NormalizarTexto(string? valor)
    {
        if (string.IsNullOrWhiteSpace(valor))
            return string.Empty;

        var decomposicao = valor.Normalize(NormalizationForm.FormD);
        var semAcentos = new StringBuilder(decomposicao.Length);

        foreach (var caractere in decomposicao)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(caractere) != UnicodeCategory.NonSpacingMark)
                semAcentos.Append(caractere);
        }

        return Regex.Replace(semAcentos.ToString(), @"\s+", " ").Trim().ToUpperInvariant();
    }
}
