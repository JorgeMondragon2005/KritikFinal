using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class RubricService
{
    private readonly IMongoCollection<Rubric> _rubricsCollection;

    public RubricService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        _rubricsCollection = database.GetCollection<Rubric>("rubrics");
    }

    public async Task<List<Rubric>> GetAsync() =>
        await _rubricsCollection.Find(_ => true).ToListAsync();

    public async Task<List<Rubric>> GetGlobalOrCreatedByAsync(string creatorId) =>
        await _rubricsCollection.Find(x => x.IsGlobal || x.CreatorId == creatorId).ToListAsync();

    public async Task<Rubric?> GetAsync(string id) =>
        await _rubricsCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task CreateAsync(Rubric newRubric) =>
        await _rubricsCollection.InsertOneAsync(newRubric);

    public async Task UpdateAsync(string id, Rubric updatedRubric) =>
        await _rubricsCollection.ReplaceOneAsync(x => x.Id == id, updatedRubric);

    public async Task RemoveAsync(string id) =>
        await _rubricsCollection.DeleteOneAsync(x => x.Id == id);
}
