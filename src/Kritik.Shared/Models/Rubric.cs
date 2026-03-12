using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class Rubric
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string Name { get; set; } = null!;
    public List<RubricItem> Items { get; set; } = new();
    public bool IsGlobal { get; set; } = false;
    public string? CreatorId { get; set; }
}

public class RubricItem
{
    public string Criteria { get; set; } = null!;
    public int MaxPoints { get; set; } = 10;
    public string Description { get; set; } = null!;
}
