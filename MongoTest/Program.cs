using System;
using System.IO;
using MongoDB.Driver;
using MongoDB.Driver.GridFS;

class Program
{
    static void Main()
    {
        var client = new MongoClient("mongodb+srv://admin:admin1234@cluster0.p7sz34m.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0");
        var db = client.GetDatabase("Kiosko_IA_Db");
        var collection = db.GetCollection<MongoDB.Bson.BsonDocument>("Projects");
        var filter = Builders<MongoDB.Bson.BsonDocument>.Filter.Empty;
        var sort = Builders<MongoDB.Bson.BsonDocument>.Sort.Descending("_id");
        var projects = collection.Find(filter).Sort(sort).Limit(10).ToList();
        
        foreach (var p in projects)
        {
            var title = p.Contains("title") ? p["title"].AsString : "null";
            var promo = p.Contains("promoVideoUrl") && !p["promoVideoUrl"].IsBsonNull ? p["promoVideoUrl"].AsString : "null";
            Console.WriteLine($"{title}: {promo}");
        }
    }
}
