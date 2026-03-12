using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly UserService _userService;

    public UsersController(UserService userService)
    {
        _userService = userService;
    }

    [HttpGet("{id:length(24)}")]
    public async Task<ActionResult<User>> Get(string id)
    {
        var user = await _userService.GetAsync(id);
        if (user == null) return NotFound();
        return user;
    }

    [HttpPut("{id:length(24)}")]
    public async Task<IActionResult> Update(string id, User updatedUser)
    {
        var user = await _userService.GetAsync(id);
        if (user == null) return NotFound();

        // Update profile fields only
        user.FullName = updatedUser.FullName;
        user.Telefono = updatedUser.Telefono;
        user.Bio = updatedUser.Bio;
        user.FotoPerfil = updatedUser.FotoPerfil;

        await _userService.UpdateAsync(id, user);
        return NoContent();
    }
}
