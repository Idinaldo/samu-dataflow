using Microsoft.AspNetCore.Mvc;
using Pulso192.Models;

namespace Pulso192.Controllers;

[ApiController]
[Route("[controller]")]
public class HelloApp : ControllerBase
{
    [HttpGet("/")]
    public string Get()
    {
        return "Hello, Pulso192";
    }

    [HttpGet("/ocorrencias")]
    public List<Ocorrencia> getOcorrencias()
    {
        return new List<Ocorrencia>();
    }
}