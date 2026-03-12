using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class UserService
{
    private readonly IMongoCollection<User> _usersCollection;

    public UserService(IOptions<MongoDBSettings> settings, IMongoDatabase database, ILogger<UserService> logger)
    {
        _usersCollection = database.GetCollection<User>("usuario");

        try
        {
            // Create unique index for Email
            var indexKeys = Builders<User>.IndexKeys.Ascending(x => x.Email);
            var indexOptions = new CreateIndexOptions { Unique = true };
            var indexModel = new CreateIndexModel<User>(indexKeys, indexOptions);
            _usersCollection.Indexes.CreateOne(indexModel);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Could not create unique index for Email. This might be because of duplicate or null emails in existing data.");
        }
    }

    public async Task<User?> GetAsync(string id) =>
        await _usersCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task<User?> GetByEmailAsync(string email) =>
        await _usersCollection.Find(x => x.Email == email).FirstOrDefaultAsync();

    public async Task CreateAsync(User newUser) =>
        await _usersCollection.InsertOneAsync(newUser);

    public async Task UpdateAsync(string id, User updatedUser) =>
        await _usersCollection.ReplaceOneAsync(x => x.Id == id, updatedUser);
}
