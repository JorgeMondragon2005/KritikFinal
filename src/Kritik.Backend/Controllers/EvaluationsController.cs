using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EvaluationsController : ControllerBase
{
    private readonly EvaluationService _evaluationService;

    public EvaluationsController(EvaluationService evaluationService)
    {
        _evaluationService = evaluationService;
    }

    [HttpGet]
    public async Task<List<Evaluation>> Get() =>
        await _evaluationService.GetAsync();

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<Evaluation>> Get(string id)
    {
        var evaluation = await _evaluationService.GetAsync(id);

        if (evaluation is null)
        {
            return NotFound();
        }

        return evaluation;
    }

    [HttpGet("project/{projectId:length(24)}")]
    public async Task<ActionResult<Evaluation>> GetByProject(string projectId)
    {
        var evaluation = await _evaluationService.GetByProjectIdAsync(projectId);

        if (evaluation is null)
        {
            return NotFound();
        }

        return evaluation;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Evaluation newEvaluation)
    {
        // 1. Validate Model State (Attributes like Range)
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        // 2. Validate References (Project and Evaluator must exist)
        // In a real app we'd check _projectService.GetAsync(newEvaluation.ProjectId) etc.
        // For MVP we assume the IDs come from valid selection in Frontend.

        // 3. Prevent Duplicate Evaluation (One per Evaluator per Project)
        var existing = await _evaluationService.GetAsync();
        var duplicate = existing.FirstOrDefault(e => e.ProjectId == newEvaluation.ProjectId && e.EvaluatorId == newEvaluation.EvaluatorId);
        
        if (duplicate != null)
        {
             return Conflict("This project has already been evaluated by this user.");
        }

        await _evaluationService.CreateAsync(newEvaluation);

        return CreatedAtAction(nameof(Get), new { id = newEvaluation.Id }, newEvaluation);
    }

    [HttpPost("Sync")]
    public async Task<IActionResult> Sync(List<Evaluation> evaluations)
    {
        var addedCount = 0;
        var errors = new List<string>();

        foreach (var eval in evaluations)
        {
            // Simple validation for batch
            // Check duplications
            var existing = await _evaluationService.GetAsync();
             var duplicate = existing.FirstOrDefault(e => e.ProjectId == eval.ProjectId && e.EvaluatorId == eval.EvaluatorId);
            
            if (duplicate == null)
            {
                 await _evaluationService.CreateAsync(eval);
                 addedCount++;
            }
            else
            {
                errors.Add($"Duplicate evaluation for Project {eval.ProjectId} by Evaluator {eval.EvaluatorId}");
            }
        }

        return Ok(new { Message = $"Synced {addedCount} evaluations.", Errors = errors });
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, Evaluation updatedEvaluation)
    {
        var evaluation = await _evaluationService.GetAsync(id);

        if (evaluation is null)
        {
            return NotFound();
        }

        updatedEvaluation.Id = evaluation.Id;

        await _evaluationService.UpdateAsync(id, updatedEvaluation);

        return NoContent();
    }

    [HttpDelete("{id:length(24)}")]
    public async Task<IActionResult> Delete(string id)
    {
        var evaluation = await _evaluationService.GetAsync(id);

        if (evaluation is null)
        {
            return NotFound();
        }

        await _evaluationService.RemoveAsync(id);

        return NoContent();
    }
}
