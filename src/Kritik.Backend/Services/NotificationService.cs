using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class NotificationService
{
    private readonly IMongoCollection<Notification> _notificationsCollection;

    public NotificationService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        _notificationsCollection = database.GetCollection<Notification>("notificaciones");
    }

    public async Task<List<Notification>> GetByUserIdAsync(string userId) =>
        await _notificationsCollection.Find(x => x.UserId == userId).SortByDescending(n => n.CreatedAt).ToListAsync();

    public async Task CreateAsync(Notification notification) =>
        await _notificationsCollection.InsertOneAsync(notification);

    public async Task MarkAsReadAsync(string id)
    {
        var update = Builders<Notification>.Update.Set(n => n.IsRead, true);
        await _notificationsCollection.UpdateOneAsync(n => n.Id == id, update);
    }
    
    public async Task MarkAllAsReadAsync(string userId)
    {
        var update = Builders<Notification>.Update.Set(n => n.IsRead, true);
        await _notificationsCollection.UpdateManyAsync(n => n.UserId == userId && !n.IsRead, update);
    }
}
