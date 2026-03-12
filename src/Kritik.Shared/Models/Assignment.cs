using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class Assignment
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string Title { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string TeacherId { get; set; } = null!;
    public string? RubricId { get; set; }
    public DateTime? DueDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? AccessCode { get; set; } // Opcional: código para unirse
    public string? ClassroomId { get; set; } // Link assignment to a class
}
