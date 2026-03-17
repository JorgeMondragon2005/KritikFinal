using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

public class UserUpdateDto
{
    public string FullName { get; set; } = null!;
    public string? Telefono { get; set; }
    public string? Bio { get; set; }
    public string? FotoPerfil { get; set; }
    public string? PortadaUrl { get; set; }
}

public class RoleUpdateDto
{
    public string Role { get; set; } = null!;
}

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserService _userService;

    public UsersController(UserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    public async Task<ActionResult<List<User>>> GetAll()
    {
        var users = await _userService.GetAllAsync();
        return users;
    }

    [HttpGet("evaluators")]
    public async Task<ActionResult<List<User>>> GetEvaluators()
    {
        var evaluators = await _userService.GetByRoleAsync("Evaluator");
        return evaluators;
    }

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<User>> Get(string id)
    {
        var user = await _userService.GetAsync(id);
        if (user == null) return NotFound();
        return user;
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, UserUpdateDto updatedUser)
    {
        var user = await _userService.GetAsync(id);
        if (user == null) return NotFound();

        // Update profile fields only
        user.FullName = updatedUser.FullName;
        user.Telefono = updatedUser.Telefono;
        user.Bio = updatedUser.Bio;
        user.FotoPerfil = updatedUser.FotoPerfil;
        user.PortadaUrl = updatedUser.PortadaUrl;

        await _userService.UpdateAsync(id, user);
        return NoContent();
    }

    [HttpPut("{id:length(24)}/role")]
    public async Task<IActionResult> UpdateRole(string id, RoleUpdateDto roleUpdate)
    {
        var user = await _userService.GetAsync(id);
        if (user == null) return NotFound();

        user.Role = roleUpdate.Role;
        await _userService.UpdateAsync(id, user);
        return NoContent();
    }
}
