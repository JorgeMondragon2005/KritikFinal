using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System.ComponentModel.DataAnnotations;

namespace Kritik.Shared.Models;

public class Evaluation
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    [BsonRepresentation(BsonType.ObjectId)]
    public string EvaluatorId { get; set; } = null!;

    [BsonRepresentation(BsonType.ObjectId)]
    public string ProjectId { get; set; } = null!;

    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    public RubricScores Scores { get; set; } = new();

    public string? RubricId { get; set; }
    public Dictionary<string, int> DetailedScores { get; set; } = new();

    public string? Feedback { get; set; }
    public string? EvidencePhotoBase64 { get; set; }
    public string? SignatureBase64 { get; set; }
}

public class RubricScores
{
    // Dictionary of Criterion Name/Id -> Score mapping
    public Dictionary<string, int> Values { get; set; } = new();

    public double Average => Values.Any() ? Values.Values.Average() : 0;
}
