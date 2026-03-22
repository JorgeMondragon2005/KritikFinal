using System;
using System.IO;
using System.Threading.Tasks;
using MongoDB.Driver;
using MongoDB.Driver.GridFS;

class Program
{
    static async Task Main()
    {
        var client = new MongoClient("mongodb+srv://admin:admin1234@cluster0.p7sz34m.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0");
        var db = client.GetDatabase("Kiosko_IA_Db");
        
        Console.WriteLine("Dropping GridFS collections to reclaim 512MB M0 Free Tier Quota...");
        await db.DropCollectionAsync("fs.files");
        await db.DropCollectionAsync("fs.chunks");
        await db.CreateCollectionAsync("fs.files");
        await db.CreateCollectionAsync("fs.chunks");
        Console.WriteLine("Successfully wiped Video GridFS! Quota completely restored.");
    }
}
