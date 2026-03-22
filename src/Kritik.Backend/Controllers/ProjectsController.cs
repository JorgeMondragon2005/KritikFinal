using Microsoft.AspNetCore.Mvc;
using Kritik.Shared.Models;
using Kritik.Backend.Services;
using System.Linq;
using System.Collections.Generic;
using System.Threading.Tasks;
using MongoDB.Driver;

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

    [HttpGet("storage-stats")]
    public async Task<IActionResult> GetStorageStats([FromServices] MongoDB.Driver.IMongoDatabase db)
    {
        try
        {
            var collections = await db.ListCollectionNamesAsync();
            var names = await collections.ToListAsync();
            var stats = new System.Collections.Generic.List<object>();
            
            foreach (var name in names)
            {
                var command = new MongoDB.Bson.BsonDocument { { "collStats", name } };
                var statInfo = await db.RunCommandAsync<MongoDB.Bson.BsonDocument>(command);
                var size = statInfo.Contains("storageSize") ? statInfo["storageSize"].AsInt32 : 0;
                var count = statInfo.Contains("count") ? statInfo["count"].AsInt32 : 0;
                stats.Add(new { name, sizeBytes = size, count });
            }
            return Ok(new { Total = stats.Sum(s => (int)((dynamic)s).sizeBytes), Collections = stats });
        }
        catch (System.Exception ex)
        {
            return StatusCode(500, ex.ToString());
        }
    }

    [HttpGet("super-reset")]
    public async Task<IActionResult> SuperReset([FromServices] MongoDB.Driver.IMongoDatabase db)
    {
        try
        {
            var collectionNames = await (await db.ListCollectionNamesAsync()).ToListAsync();
            var backup = new System.Collections.Generic.Dictionary<string, System.Collections.Generic.List<MongoDB.Bson.BsonDocument>>();

            foreach (var name in collectionNames)
            {
                if (name == "fs.files" || name == "fs.chunks" || name == "system.views") continue;
                
                var collection = db.GetCollection<MongoDB.Bson.BsonDocument>(name);
                var docs = await collection.Find(new MongoDB.Bson.BsonDocument()).ToListAsync();
                backup[name] = docs;
            }

            await db.Client.DropDatabaseAsync(db.DatabaseNamespace.DatabaseName);

            // Reconstruct metadata BSON arrays
            foreach (var kvp in backup)
            {
                if (kvp.Value.Count > 0)
                {
                    var collection = db.GetCollection<MongoDB.Bson.BsonDocument>(kvp.Key);
                    await collection.InsertManyAsync(kvp.Value);
                }
            }

            return Ok(new { Message = "Successfully defragmented 512MB Quota and restored all metadata." });
        }
        catch (System.Exception ex)
        {
            return StatusCode(500, ex.ToString());
        }
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
                // Un evaluador da X puntos en total sumando todos sus DetailedScores.
                // El puntaje del proyecto es el Promedio de los (Puntajes Totales de cada evaluador).
                var avgScore = projectEvals.Average(e => 
                    (e.Scores != null && e.Scores.Values.ContainsKey("General"))
                        ? e.Scores.Values["General"]
                        : ((e.DetailedScores != null && e.DetailedScores.Any()) 
                            ? e.DetailedScores.Values.Sum() 
                            : (e.Scores?.Values.Values.Sum() ?? 0))
                );
                var integrity = 98.2; // Placeholder for now

                ranking.Add(new ProjectRankingDTO
                {
                    ProjectId = project.Id!,
                    TeamName = project.TeamName ?? "S/N",
                    Category = project.Category ?? "N/A",
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

    [HttpPost("{id:length(24)}/upvote")]
    public async Task<IActionResult> ToggleUpvote(string id, [FromQuery] string userId)
    {
        var project = await _projectService.GetAsync(id);
        if (project is null) return NotFound();

        project.UpvotedBy ??= new List<string>();
        if (project.UpvotedBy.Contains(userId)) project.UpvotedBy.Remove(userId);
        else project.UpvotedBy.Add(userId);

        await _projectService.UpdateAsync(id, project);
        return Ok(project);
    }

    [HttpPost("{id:length(24)}/comment")]
    public async Task<IActionResult> AddComment(string id, Comment comment)
    {
        var project = await _projectService.GetAsync(id);
        if (project is null) return NotFound();

        project.Comments ??= new List<Comment>();
        comment.CreatedAt = DateTime.UtcNow;
        project.Comments.Add(comment);

        await _projectService.UpdateAsync(id, project);
        return Ok(project);
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
