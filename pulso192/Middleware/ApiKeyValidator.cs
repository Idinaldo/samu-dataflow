using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Pulso192.Configuration;

namespace Pulso192.Middleware;

public sealed class ApiKeyValidator(IOptions<Pulso192Options> options)
{
    public bool IsValid(string? apiKey)
    {
        if (string.IsNullOrEmpty(apiKey))
            return false;

        var chaveEsperada = Encoding.UTF8.GetBytes(options.Value.ApiKey);
        var chaveRecebida = Encoding.UTF8.GetBytes(apiKey);

        return chaveEsperada.Length == chaveRecebida.Length &&
            CryptographicOperations.FixedTimeEquals(chaveEsperada, chaveRecebida);
    }
}
