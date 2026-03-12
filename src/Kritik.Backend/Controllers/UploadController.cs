using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UploadController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;

    public UploadController(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    [HttpPost]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded.");

        // Create uploads folder if it doesn't exist
        var uploadsPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
        if (!Directory.Exists(uploadsPath))
            Directory.CreateDirectory(uploadsPath);

        // Generate unique filename and ensure extension exists
        var ext = Path.GetExtension(file.FileName);
        if (string.IsNullOrEmpty(ext))
        {
            var contentType = file.ContentType.ToLower();
            if (contentType.Contains("video/mp4")) ext = ".mp4";
            else if (contentType.Contains("video/quicktime")) ext = ".mov";
            else if (contentType.Contains("video")) ext = ".mp4";
            else if (contentType.Contains("image/jpeg")) ext = ".jpg";
            else if (contentType.Contains("image/png")) ext = ".png";
            else if (contentType.Contains("pdf")) ext = ".pdf";
        }
        var fileName = $"{Guid.NewGuid()}{ext}";
        var filePath = Path.Combine(uploadsPath, fileName);

        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream);
        }

        // Return relative URL
        var url = $"/uploads/{fileName}";
        return Ok(new { url });
    }
}
