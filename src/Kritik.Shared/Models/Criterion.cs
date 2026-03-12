using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class Criterion
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }
    
    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public int MinValue { get; set; } = 0;
    public int MaxValue { get; set; } = 10;
    public double Weight { get; set; } = 1.0; // For future weighted averages
}
