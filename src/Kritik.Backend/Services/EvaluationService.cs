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
    }

    public async Task<List<Evaluation>> GetAsync() =>
        await _evaluationsCollection.Find(_ => true).ToListAsync();

    public async Task<Evaluation?> GetAsync(string id) =>
        await _evaluationsCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task<List<Evaluation>> GetByProjectIdAsync(string projectId) =>
        await _evaluationsCollection.Find(x => x.ProjectId == projectId).ToListAsync();

    public async Task CreateAsync(Evaluation newEvaluation) =>
        await _evaluationsCollection.InsertOneAsync(newEvaluation);

    public async Task UpdateAsync(string id, Evaluation updatedEvaluation) =>
        await _evaluationsCollection.ReplaceOneAsync(x => x.Id == id, updatedEvaluation);

    public async Task RemoveAsync(string id) =>
        await _evaluationsCollection.DeleteOneAsync(x => x.Id == id);
}
