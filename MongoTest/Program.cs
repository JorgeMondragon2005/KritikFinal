using System;
using System.IO;
using System.Threading.Tasks;
using MongoDB.Bson;
using MongoDB.Driver;

class Program
{
    static async Task Main()
    {
        var client = new MongoClient("mongodb+srv://admin:admin1234@cluster0.p7sz34m.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0");
        var db = client.GetDatabase("Kiosko_IA_Db");
        var collection = db.GetCollection<BsonDocument>("projects");
        
        Console.WriteLine("Fetching projects from database...");
        var docs = await collection.Find(new BsonDocument()).ToListAsync();
        Console.WriteLine($"Found {docs.Count} projects in the database.");
    }
}
