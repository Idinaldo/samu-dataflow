namespace Pulso192.Domain;

public class PipelineException : Exception
{
    public string Etapa { get; }

    public PipelineException(string etapa, string message, Exception? innerException = null)
        : base(message, innerException)
    {
        Etapa = etapa;
    }
}

public sealed class ExtracaoException(string message, Exception? innerException = null)
    : PipelineException("extracao", message, innerException);

public sealed class ValidacaoException(string message, Exception? innerException = null)
    : PipelineException("transformacao", message, innerException);

public sealed class CargaException(string message, Exception? innerException = null)
    : PipelineException("carga", message, innerException);
