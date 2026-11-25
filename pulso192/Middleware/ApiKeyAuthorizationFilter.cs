using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Pulso192.Middleware;

public sealed class ApiKeyAuthorizationFilter(ApiKeyValidator apiKeyValidator) : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(
        ActionExecutingContext context,
        ActionExecutionDelegate next)
    {
        var apiKey = context.HttpContext.Request.Headers["X-API-Key"].FirstOrDefault();

        if (!apiKeyValidator.IsValid(apiKey))
        {
            context.Result = new UnauthorizedObjectResult(new ProblemDetails
            {
                Status = StatusCodes.Status401Unauthorized,
                Title = "Não autorizado",
                Detail = "A chave de API é inválida ou não foi informada."
            });
            return;
        }

        await next();
    }
}
