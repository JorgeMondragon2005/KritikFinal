using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models
{
    public class EvaluationModel
    {
        [BsonId]
        [BsonRepresentation(BsonType.ObjectId)]
        public string Id { get; set; } = string.Empty;

        [BsonRepresentation(BsonType.ObjectId)]
        public string ProjectId { get; set; } = string.Empty;

        [BsonRepresentation(BsonType.ObjectId)]
        public string UserId { get; set; } = string.Empty;

        public int Innovation { get; set; }

        public int Usability { get; set; }

        public int Complexity { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
