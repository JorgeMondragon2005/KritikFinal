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
        try
        {
            using (var stream = file.OpenReadStream())
            {
                await _gridFS.UploadFromStreamAsync(fileId, fileName, stream, options);
            }
        }
        catch (Exception ex)
        {
            return Ok(new { url = "ERROR", details = ex.ToString() });
        }

        var url = $"/api/upload/{fileId}";
        return Ok(new { url });
    }

    [HttpGet("{id:length(24)}")]
    public async Task<IActionResult> GetFile(string id)
    {
        if (!ObjectId.TryParse(id, out var objectId)) return BadRequest();
        try 
        {
            var stream = await _gridFS.OpenDownloadStreamAsync(objectId);
            var contentType = stream.FileInfo.Metadata?.GetValue("contentType", "application/octet-stream").AsString;
            
            if (string.IsNullOrEmpty(contentType) || contentType == "application/octet-stream" || contentType == "application/x-www-form-urlencoded")
            {
                var ext = Path.GetExtension(stream.FileInfo.Filename).ToLower();
                contentType = ext switch
                {
                    ".mp4" => "video/mp4",
                    ".mov" => "video/quicktime",
                    ".avi" => "video/x-msvideo",
                    ".jpg" or ".jpeg" => "image/jpeg",
                    ".png" => "image/png",
                    ".pdf" => "application/pdf",
                    _ => "application/octet-stream"
                };
            }
            // Buffer completely to intercept MongoDB NotSupportedException on Seek() which ExoPlayer triggers.
            // Using a temporary physical file ensures 0 RAM consumption regardless of video size.
            var tempPath = Path.GetTempFileName();
            using (var fs = new FileStream(tempPath, FileMode.Create, FileAccess.Write, FileShare.None))
            {
                await stream.CopyToAsync(fs);
            }
            
            var readStream = new FileStream(tempPath, FileMode.Open, FileAccess.Read, FileShare.Read, 4096, FileOptions.DeleteOnClose);
            return File(readStream, contentType ?? "application/octet-stream", enableRangeProcessing: true);
        }
        catch(GridFSFileNotFoundException) { return NotFound(); }
    }
}
