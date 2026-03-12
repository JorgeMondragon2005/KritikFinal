using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class EvaluationService
{
    private readonly IMongoCollection<Evaluation> _evaluationsCollection;

    public EvaluationService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        _evaluationsCollection = database.GetCollection<Evaluation>("evaluations");

        // Create unique compound index for EvaluatorId and ProjectId to prevent duplicate evaluations
        var indexKeys = Builders<Evaluation>.IndexKeys.Ascending(x => x.EvaluatorId).Ascending(x => x.ProjectId);
        var indexOptions = new CreateIndexOptions { Unique = true };
        var indexModel = new CreateIndexModel<Evaluation>(indexKeys, indexOptions);
        _evaluationsCollection.Indexes.CreateOne(indexModel);
    }

    public async Task<List<Evaluation>> GetAsync() =>
        await _evaluationsCollection.Find(_ => true).ToListAsync();

    public async Task<Evaluation?> GetAsync(string id) =>
        await _evaluationsCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task<Evaluation?> GetByProjectIdAsync(string projectId) =>
        await _evaluationsCollection.Find(x => x.ProjectId == projectId).FirstOrDefaultAsync();

    public async Task CreateAsync(Evaluation newEvaluation) =>
        await _evaluationsCollection.InsertOneAsync(newEvaluation);

    public async Task UpdateAsync(string id, Evaluation updatedEvaluation) =>
        await _evaluationsCollection.ReplaceOneAsync(x => x.Id == id, updatedEvaluation);

    public async Task RemoveAsync(string id) =>
        await _evaluationsCollection.DeleteOneAsync(x => x.Id == id);
}
