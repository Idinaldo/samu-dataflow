namespace Pulso192.Models;

public class Ocorrencia
{
    private DateTime dataHora;
    // TODO: verificar viabilidade de valueObject "Endereco"
    private string municipio;
    private string bairro;
    private string logradouro;
    private string origemChamado;
    // TODO: verificar viabilidade de enum
    private string tipo;
    // TODO: verificar viabilidade de enum
    private string subtipo;
    // TODO: validar enum
    private Sex sexo;
    private int idade;
    // TODO: conversar com CIE para entender a diferença entre esses campos
    // NOTE: citar taxa de 0.06% de aparição de motivoFinalizacao
    private string motivoFinalizacao;
    private string motivoDesfecho;
}

internal enum Sex
{
    FEMININO,
    MASCULINO
}