using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly NotificationService _notificationService;

    public NotificationsController(NotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpGet("user/{userId}")]
    public async Task<ActionResult<List<Notification>>> GetUserNotifications(string userId)
    {
        var notifications = await _notificationService.GetByUserIdAsync(userId);
        return Ok(notifications);
    }

    [HttpPost]
    public async Task<IActionResult> Create(Notification notification)
    {
        await _notificationService.CreateAsync(notification);
        return Ok();
    }

    [HttpPut("{id:length(24)}/read")]
    public async Task<IActionResult> MarkAsRead(string id)
    {
        await _notificationService.MarkAsReadAsync(id);
        return Ok();
    }
    
    [HttpPut("user/{userId}/read")]
    public async Task<IActionResult> MarkAllAsRead(string userId)
    {
        await _notificationService.MarkAllAsReadAsync(userId);
        return Ok();
    }
}
