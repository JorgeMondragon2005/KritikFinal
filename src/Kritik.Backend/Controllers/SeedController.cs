using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;
using BCrypt.Net;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SeedController : ControllerBase
{
    private readonly ProjectService _projectService;
    private readonly UserService _userService;
    private readonly AssignmentService _assignmentService;
    private readonly RubricService _rubricService;

    public SeedController(ProjectService projectService, UserService userService, AssignmentService assignmentService, RubricService rubricService)
    {
        _projectService = projectService;
        _userService = userService;
        _assignmentService = assignmentService;
        _rubricService = rubricService;
    }

    [HttpPost]
    public async Task<IActionResult> Seed()
    {
        var existing = await _projectService.GetAsync();
        if (existing.Count > 0)
        {
            return Ok(new { message = "Database already has data." });
        }

        var projects = new List<Project>
        {
            new()
            {
                TeamName = "Equipo Alpha",
                Category = "IoT",
                Technologies = new() { "Arduino", "C#", "MQTT" },
                Description = "Sistema de riego automatizado con monitoreo remoto.",
                Members = new() { "Juan Pérez", "Maria Lopez" },
                FairLocation = "Stand A-01",
                Videos = new() 
                { 
                    new Video { Title = "Demo Funcionamiento", Url = "https://youtube.com/watch?v=demo1", Description = "Demostración en vivo del sistema." } 
                },
                Documents = new()
                {
                    new Document { Title = "Manual de Usuario", Url = "https://kritik.com/docs/manual.pdf", Type = "PDF" }
                }
            },
            new()
            {
                TeamName = "CodeCrafters",
                Category = "Web",
                Technologies = new() { "React", "Node.js", "MongoDB" },
                Description = "Plataforma de gestión escolar integral.",
                Members = new() { "Carlos Ruiz", "Sofia Dia" },
                FairLocation = "Stand B-05",
                 Videos = new() 
                { 
                    new Video { Title = "Pitch Deck", Url = "https://youtube.com/watch?v=pitch", Description = "Presentación de negocio." } 
                },
                Documents = new()
                {
                    new Document { Title = "Arquitectura", Url = "https://kritik.com/docs/arch.pdf", Type = "PDF" }
                }
            },
             new()
            {
                TeamName = "Innovators",
                Category = "AI",
                Technologies = new() { "Python", "TensorFlow", "FastAPI" },
                Description = "Detección de objetos en tiempo real para seguridad.",
                Members = new() { "Luis Torres", "Ana Silva" },
                FairLocation = "Stand C-10"
            }
        };

        foreach (var p in projects)
        {
            await _projectService.CreateAsync(p);
        }

        // Seed Default User
        var defaultUser = new User
        {
            Email = "evaluador@kritik.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("password123"),
            FullName = "Evaluador Demo",
            Role = "Evaluator",
            IsEmailVerified = true
        };
        
        var existingUser = await _userService.GetByEmailAsync(defaultUser.Email);
        if (existingUser == null)
        {
            await _userService.CreateAsync(defaultUser);
        }
        
        // Seed Default Assignment if none exist
        var existingAssignments = await _assignmentService.GetAsync();
        if (existingAssignments.Count == 0)
        {
            var defaultAssignment = new Assignment
            {
                Title = "Convocatoria Principal 2026",
                Description = "Sube aquí tu proyecto final para la feria de ciencias.",
                TeacherId = "evaluador@kritik.com", // Match the seeded user email/identifier
                DueDate = DateTime.UtcNow.AddMonths(1)
            };
            await _assignmentService.CreateAsync(defaultAssignment);
        }

        // Seed Default Global Rubric
        var existingRubrics = await _rubricService.GetAsync();
        if (existingRubrics.Count == 0)
        {
            var defaultRubric = new Rubric
            {
                Name = "Criterios de Evaluación General",
                IsGlobal = true,
                Items = new List<RubricItem>
                {
                    new RubricItem { Criteria = "Innovación", MaxPoints = 10, Description = "Originalidad y creatividad del proyecto." },
                    new RubricItem { Criteria = "Impacto Social", MaxPoints = 10, Description = "Potencial beneficio para la comunidad." },
                    new RubricItem { Criteria = "Uso de Tecnología", MaxPoints = 10, Description = "Correcta implementación de las herramientas técnicas." },
                    new RubricItem { Criteria = "Presentación", MaxPoints = 10, Description = "Claridad y profesionalismo al exponer." }
                }
            };
            await _rubricService.CreateAsync(defaultRubric);
        }
        
        return Ok(new { message = "Seeded projects, default user, and assignment." });
    }
}
