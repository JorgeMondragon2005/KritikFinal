using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models
{
    public class ProjectModel
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; } = string.Empty;

        public string TeamName { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public string Category { get; set; } = string.Empty;

        public string ImageUrl { get; set; } = string.Empty;
    }
}
