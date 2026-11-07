using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;

namespace Pulso192.Models;

// Onde aconteceu. Só município e bairro, sem a rua: 7.759 registros têm número
// da casa, o que junto com hora, idade e tipo identifica o paciente (LGPD).
// "CENTRO" aparece em 42 municípios, por isso bairro anda junto com município.
public class Endereco
{
    public string Municipio { get; set; } = string.Empty;
    public string Bairro { get; set; } = string.Empty;

    // R08: "BOA VISTA(CENTRO)" vira "BOA VISTA (CENTRO)", "BR - 408" vira "BR 408"
    public void Padronizar()
    {
        Municipio = Limpar(Municipio);
        Bairro = Limpar(Bairro);
    }

    private static string Limpar(string texto)
    {
        if (string.IsNullOrWhiteSpace(texto)) return string.Empty;

        // tira acento
        var semAcento = new StringBuilder();
        foreach (var c in texto.Normalize(NormalizationForm.FormD))
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                semAcento.Append(c);
        }
        var t = semAcento.ToString().Normalize(NormalizationForm.FormC).ToUpperInvariant();

        t = Regex.Replace(t, @"\s*\(\s*", " (");   // espaço antes do parêntese
        t = Regex.Replace(t, @"\s*\)", ")");
        t = Regex.Replace(t, @"\)(?=\S)", ") ");     // espaço depois do parêntese
        t = Regex.Replace(t, @"\s*-\s*", " ");     // "BR - 408" -> "BR 408"
        t = Regex.Replace(t, @"\b(BR|PE)(\d)", "$1 $2"); // "BR408" -> "BR 408"
        t = Regex.Replace(t, @"\s+", " ");         // espaços repetidos
        return t.Trim();
    }
}
