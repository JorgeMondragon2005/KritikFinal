using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class Classroom
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string TeacherId { get; set; } = null!;
    public string AccessCode { get; set; } = null!; // For students to find the class
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
