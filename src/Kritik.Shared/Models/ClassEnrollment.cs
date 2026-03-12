using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class ClassEnrollment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string ClassroomId { get; set; } = null!;
    public string StudentId { get; set; } = null!;
    
    [BsonIgnore]
    public string? StudentName { get; set; }
    
    public string Status { get; set; } = "Pending"; // Pending, Accepted, Rejected
    public DateTime? RequestedAt { get; set; } = DateTime.UtcNow;
}
