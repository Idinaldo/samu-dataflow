namespace Pulso192.Models;

// Lista fechada de valores. R05
// Atenção: pra API aceitar e devolver o texto ("FEMININO") e não o número,
// registrar JsonStringEnumConverter no Program.cs quando o POST existir
public enum Sexo
{
    NAO_INFORMADO,
    MASCULINO,
    FEMININO
}
