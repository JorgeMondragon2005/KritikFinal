using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class CriteriaService
{
    private readonly IMongoCollection<Criterion> _criteriaCollection;

    public CriteriaService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        _criteriaCollection = database.GetCollection<Criterion>("criteria");
        
        // Ensure default criteria exist if collection is empty
        SeedDefaults();
    }

    private void SeedDefaults()
    {
        if (_criteriaCollection.CountDocuments(FilterDefinition<Criterion>.Empty) == 0)
        {
            var defaults = new List<Criterion>
            {
                new Criterion { Name = "Innovación", Description = "Originalidad y creatividad de la propuesta." },
                new Criterion { Name = "Factibilidad", Description = "Viabilidad técnica y económica." },
                new Criterion { Name = "UI/UX", Description = "Calidad del diseño y experiencia de usuario." },
                new Criterion { Name = "Presentación", Description = "Claridad y dominio del tema al exponer." }
            };
            _criteriaCollection.InsertMany(defaults);
        }
    }

    public async Task<List<Criterion>> GetAsync() =>
        await _criteriaCollection.Find(_ => true).ToListAsync();

    public async Task CreateAsync(Criterion newCriterion) =>
        await _criteriaCollection.InsertOneAsync(newCriterion);

    public async Task UpdateAsync(string id, Criterion updatedCriterion) =>
        await _criteriaCollection.ReplaceOneAsync(x => x.Id == id, updatedCriterion);

    public async Task RemoveAsync(string id) =>
        await _criteriaCollection.DeleteOneAsync(x => x.Id == id);
}
