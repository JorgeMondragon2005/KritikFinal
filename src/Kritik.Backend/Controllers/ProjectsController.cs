using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProjectsController : ControllerBase
{
    private readonly ProjectService _projectService;
    private readonly EvaluationService _evaluationService;
    private readonly AssignmentService _assignmentService;

    public ProjectsController(ProjectService projectService, EvaluationService evaluationService, AssignmentService assignmentService)
    {
        _projectService = projectService;
        _evaluationService = evaluationService;
        _assignmentService = assignmentService;
    }

    [HttpGet("rankings")]
    public async Task<List<ProjectRankingDTO>> GetRanking()
    {
        var projects = await _projectService.GetAsync();
        var evaluations = await _evaluationService.GetAsync();

        var ranking = new List<ProjectRankingDTO>();

        foreach (var project in projects)
        {
            var projectEvals = evaluations.Where(e => e.ProjectId == project.Id).ToList();
            if (projectEvals.Any())
            {
                var avgScore = projectEvals.Average(e => e.Scores.Average);
                var integrity = 1.0; // Placeholder for now

                ranking.Add(new ProjectRankingDTO
                {
                    ProjectId = project.Id!,
                    TeamName = project.TeamName,
                    Category = project.Category,
                    AverageScore = Math.Round(avgScore, 1),
                    TotalVotes = projectEvals.Count,
                    IntegrityRate = integrity
                });
            }
        }

        return ranking.OrderByDescending(r => r.AverageScore).ThenByDescending(r => r.TotalVotes).ToList();
    }

    [HttpGet]
    public async Task<List<Project>> Get([FromQuery] string? search, [FromQuery] string? category, [FromQuery] string? technology, [FromQuery] string? studentId, [FromQuery] string? teacherId, [FromQuery] string? assignmentId) =>
        await _projectService.GetAsync(search, category, technology, studentId, teacherId, assignmentId);

    [HttpPost("{id:length(24)}/assign/{teacherId}")]
    public async Task<IActionResult> AssignTeacher(string id, string teacherId)
    {
        var project = await _projectService.GetAsync(id);
        if (project is null) return NotFound();

        project.AssignedTeacherId = teacherId;
        await _projectService.UpdateAsync(id, project);

        return Ok(project);
    }

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<Project>> Get(string id)
    {
        var project = await _projectService.GetAsync(id);

        if (project is null)
        {
            return NotFound();
        }

        return project;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Project newProject)
    {
        if (!string.IsNullOrEmpty(newProject.AssignmentId))
        {
            var assignment = await _assignmentService.GetAsync(newProject.AssignmentId);
            if (assignment != null && assignment.DueDate.HasValue)
            {
                if (DateTime.UtcNow > assignment.DueDate.Value)
                {
                    return BadRequest("La fecha límite para esta entrega ha expirado y ya no se aceptan nuevos proyectos.");
                }
            }
        }
        await _projectService.CreateAsync(newProject);

        return CreatedAtAction(nameof(Get), new { id = newProject.Id }, newProject);
    }

    [HttpPost("batch")]
    public async Task<IActionResult> PostBatch(IEnumerable<Project> projects)
    {
        await _projectService.CreateManyAsync(projects);
        return Ok(new { count = projects.Count() });
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, Project updatedProject)
    {
        var project = await _projectService.GetAsync(id);

        if (project is null)
        {
            return NotFound();
        }

        updatedProject.Id = project.Id;

        await _projectService.UpdateAsync(id, updatedProject);

        return NoContent();
    }

    [HttpDelete("{id:length(24)}")]
    public async Task<IActionResult> Delete(string id)
    {
        var project = await _projectService.GetAsync(id);

        if (project is null)
        {
            return NotFound();
        }

        await _projectService.RemoveAsync(id);

        return NoContent();
    }
}
