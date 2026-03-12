using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CriteriaController : ControllerBase
{
    private readonly CriteriaService _criteriaService;

    public CriteriaController(CriteriaService criteriaService)
    {
        _criteriaService = criteriaService;
    }

    [HttpGet]
    public async Task<List<Criterion>> Get() =>
        await _criteriaService.GetAsync();

    [HttpPost]
    public async Task<IActionResult> Post(Criterion criterion)
    {
        await _criteriaService.CreateAsync(criterion);
        return Ok(criterion);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Put(string id, Criterion criterion)
    {
        await _criteriaService.UpdateAsync(id, criterion);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        await _criteriaService.RemoveAsync(id);
        return NoContent();
    }
}
