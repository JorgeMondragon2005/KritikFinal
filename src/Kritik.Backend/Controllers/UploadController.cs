using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Driver.GridFS;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UploadController : ControllerBase
{
    private readonly IGridFSBucket _gridFS;

    public UploadController(IGridFSBucket gridFS)
    {
        _gridFS = gridFS;
    }

    [HttpPost]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest("No file uploaded.");

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

        var options = new GridFSUploadOptions { Metadata = new BsonDocument("contentType", file.ContentType) };
        var fileId = ObjectId.GenerateNewId();

        using (var stream = file.OpenReadStream())
        {
            await _gridFS.UploadFromStreamAsync(fileId, fileName, stream, options);
        }

        var url = $"/api/upload/{fileId}";
        return Ok(new { url });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetFile(string id)
    {
        if (!ObjectId.TryParse(id, out var objectId)) return BadRequest();
        try 
        {
            var stream = await _gridFS.OpenDownloadStreamAsync(objectId);
            var contentType = stream.FileInfo.Metadata?.GetValue("contentType", "application/octet-stream").AsString ?? "application/octet-stream";
            return File(stream, contentType, enableRangeProcessing: true);
        }
        catch(GridFSFileNotFoundException) { return NotFound(); }
    }
}
