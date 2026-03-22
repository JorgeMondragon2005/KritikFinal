using System.Text.Json;
using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AIController : ControllerBase
{
    private readonly AIService _aiService;

    public AIController(AIService aiService)
    {
        _aiService = aiService;
    }

    [HttpPost("mentor/review")]
    public async Task<IActionResult> ReviewProject([FromBody] Project project)
    {
        try
        {
            var prompt = $@"
Actúa como un mentor escolar experto en revisión de proyectos tecnológicos y científicos.
El estudiante está a punto de entregar el siguiente proyecto: 
- Título: {project.Title}
- Categoría: {project.Category}
- Tecnologías: {string.Join(", ", project.Technologies ?? new List<string>())}
- Descripción: {project.Description}

Por favor revísalo y devuélveme un párrafo amigable (máximo 4 oraciones) dándole un consejo técnico o sugerencia de mejora sobre qué podría agregarle a su documentación o enfoque para asegurar una mejor nota antes de enviarlo. 
No seas destructivo, sé motivador pero muy agudo en detectar qué le falta. Solo devuelve la sugerencia, sin saludos ni introducciones largas.
";
            var result = await _aiService.GenerateContentAsync(prompt);
            return Ok(new { Suggestion = result });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "Error consultando a la IA", Details = ex.Message });
        }
    }

    [HttpPost("evaluation/suggest")]
    public async Task<IActionResult> SuggestEvaluation([FromBody] EvaluationSuggestionRequest request)
    {
        try
        {
            var prompt = $@"
Actúa como un evaluador/sinodal estricto pero justo. Tienes el siguiente proyecto de un grupo de estudiantes:
- Título: {request.Project.Title}
- Descripción: {request.Project.Description}

La rúbrica para evaluarlos es:
{JsonSerializer.Serialize(request.Rubric.Items)}

Por cada criterio en la rúbrica, analízalo con respecto al proyecto y genérale un comentario global constructivo de retroalimentación. NO le asignes puntuaciones numéricas a los alumnos.
Devuelve tu respuesta ÚNICAMENTE como un JSON válido en el siguiente formato (no incluyas formato Markdown ```json, solo las llaves):
{{
  ""feedback"": ""Tu retroalimentación general detallada aquí evaluando los puntos de la rúbrica""
}}
";
            var resultText = await _aiService.GenerateContentAsync(prompt);
            
            // Clean up Markdown backticks if Gemini includes them
            resultText = resultText.Replace("```json", "", StringComparison.OrdinalIgnoreCase)
                                   .Replace("```", "")
                                   .Trim();
            
            try 
            {
                using var doc = JsonDocument.Parse(resultText);
                return Content(resultText, "application/json");
            }
            catch (JsonException)
            {
                // Fallback if parsing fails
                return Ok(new { scores = new Dictionary<string, int>(), feedback = resultText });
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "Error generando la evaluación con IA", Details = ex.Message });
        }
    }

    [HttpPost("matchmaking")]
    public async Task<IActionResult> GetMatchmaking([FromBody] MatchmakingRequest request)
    {
        try
        {
            var prompt = $@"
Tengo el siguiente perfil de usuario intentando buscar proyectos afines a sus intereses:
Usuario: {request.UserId}
Rol: {request.UserRole}

Tengo esta lista de proyectos registrados:
{JsonSerializer.Serialize(request.Projects.Select(p => new { p.Id, p.Title, p.Category, p.Technologies }))}

Como un Matchmaker experto, analiza el rol del usuario (si es estudiante buscará compañeros interesantes, si es maestro buscará proyectos técnicos de alto nivel), y escoge los 3 proyectos más relevantes para esta persona.
Devuelve tu respuesta ÚNICAMENTE como un array JSON válido de los 'Id' de esos 3 proyectos. No incluyas explicación ni Markdown ```json.
Ejemplo de salida: [""id_1"", ""id_2"", ""id_3""]
";
            var resultText = await _aiService.GenerateContentAsync(prompt);
            
            resultText = resultText.Replace("```json", "", StringComparison.OrdinalIgnoreCase)
                                   .Replace("```", "")
                                   .Trim();
            
            try 
            {
                using var doc = JsonDocument.Parse(resultText);
                return Content(resultText, "application/json");
            }
            catch (JsonException)
            {
                return Ok(new List<string>()); // Empty list on fail
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "Error en Matchmaking con IA", Details = ex.Message });
        }
    }

    [HttpPost("grammar/fix")]
    public async Task<IActionResult> FixGrammar([FromBody] GrammarRequest request)
    {
        try
        {
            var prompt = $@"
Actúa como un corrector ortográfico y de estilo impecable.
Corrige el siguiente texto eliminando faltas de ortografía, mejorando la sintaxis y haciéndolo sonar más profesional, PERO conservando su significado, intención y longitud original.
No añadas saludos ni explicaciones, SOLO devuelve el texto corregido.

Texto original:
""{request.Text}""
";
            var resultText = await _aiService.GenerateContentAsync(prompt);
            return Ok(new { correctedText = resultText.Trim() });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Error = "Error corrigiendo texto con IA", Details = ex.Message });
        }
    }
}

public class EvaluationSuggestionRequest
{
    public Project Project { get; set; } = new();
    public Rubric Rubric { get; set; } = new();
}

public class MatchmakingRequest
{
    public string UserId { get; set; } = string.Empty;
    public string UserRole { get; set; } = string.Empty;
    public List<Project> Projects { get; set; } = new();
}

public class GrammarRequest
{
    public string Text { get; set; } = string.Empty;
}

