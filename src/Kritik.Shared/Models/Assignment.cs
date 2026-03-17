using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

[BsonIgnoreExtraElements]
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
    public List<string>? AssignedEvaluators { get; set; } // Legacy or Keep it for simple strings
    public List<JurorAssignment> Jurors { get; set; } = new();
}

public class JurorAssignment
{
    public string Email { get; set; } = null!;
    public int WeightPercentage { get; set; } = 0; // 0-100
    public string Status { get; set; } = "Pending"; // "Pending", "Accepted", "Completed"
    public string? UserId { get; set; } // Id of the user in DB, if mapped
}
