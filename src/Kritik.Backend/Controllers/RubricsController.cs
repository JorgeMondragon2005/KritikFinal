using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RubricsController : ControllerBase
{
    private readonly RubricService _rubricService;

    public RubricsController(RubricService rubricService)
    {
        _rubricService = rubricService;
    }

    [HttpGet]
    public async Task<List<Rubric>> Get([FromQuery] string? creatorId)
    {
        if (string.IsNullOrEmpty(creatorId))
            return await _rubricService.GetAsync();
        
        return await _rubricService.GetGlobalOrCreatedByAsync(creatorId);
    }

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<Rubric>> GetById(string id)
    {
        var rubric = await _rubricService.GetAsync(id);

        if (rubric is null)
            return NotFound();

        return rubric;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Rubric newRubric)
    {
        await _rubricService.CreateAsync(newRubric);
        return CreatedAtAction(nameof(GetById), new { id = newRubric.Id }, newRubric);
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, Rubric updatedRubric)
    {
        var rubric = await _rubricService.GetAsync(id);

        if (rubric is null)
            return NotFound();

        updatedRubric.Id = rubric.Id;

        await _rubricService.UpdateAsync(id, updatedRubric);

        return NoContent();
    }

    [HttpDelete("{id:length(24)}")]
    public async Task<IActionResult> Delete(string id)
    {
        var rubric = await _rubricService.GetAsync(id);

        if (rubric is null)
            return NotFound();

        await _rubricService.RemoveAsync(id);

        return NoContent();
    }
}
