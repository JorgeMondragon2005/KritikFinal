using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;
using MongoDB.Bson;

namespace Kritik.Backend.Services;

public class ProjectService
{
    private readonly IMongoCollection<Project> _projectsCollection;

    public ProjectService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        _projectsCollection = database.GetCollection<Project>("projects");

        // Create indexes for Category and Technologies
        var indexKeysCategory = Builders<Project>.IndexKeys.Ascending(x => x.Category);
        var indexKeysTechnologies = Builders<Project>.IndexKeys.Ascending(x => x.Technologies);
        
        var indexModelCategory = new CreateIndexModel<Project>(indexKeysCategory);
        var indexModelTechnologies = new CreateIndexModel<Project>(indexKeysTechnologies);
        
        _projectsCollection.Indexes.CreateMany(new[] { indexModelCategory, indexModelTechnologies });
    }

    public async Task<List<Project>> GetAsync(string? search = null, string? category = null, string? technology = null, string? studentId = null, string? teacherId = null, string? assignmentId = null)
    {
        var builder = Builders<Project>.Filter;
        var filters = new List<FilterDefinition<Project>>();

        if (!string.IsNullOrEmpty(search))
        {
            var regex = new BsonRegularExpression(search, "i"); // Case-insensitive
            filters.Add(builder.Or(
                builder.Regex(x => x.TeamName, regex),
                builder.Regex(x => x.Description, regex)
            ));
        }

        if (!string.IsNullOrEmpty(category))
        {
            filters.Add(builder.Eq(x => x.Category, category));
        }

        if (!string.IsNullOrEmpty(technology))
        {
            filters.Add(builder.AnyEq(x => x.Technologies, technology));
        }

        if (!string.IsNullOrEmpty(studentId))
        {
            filters.Add(builder.Eq(x => x.StudentId, studentId));
        }

        if (!string.IsNullOrEmpty(teacherId))
        {
            filters.Add(builder.Eq(x => x.AssignedTeacherId, teacherId));
        }

        if (!string.IsNullOrEmpty(assignmentId))
        {
            filters.Add(builder.Eq(x => x.AssignmentId, assignmentId));
        }

        var finalFilter = filters.Count > 0 ? builder.And(filters) : builder.Empty;

        return await _projectsCollection.Find(finalFilter).ToListAsync();
    }

    public async Task<Project?> GetAsync(string id) =>
        await _projectsCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task CreateAsync(Project newProject) =>
        await _projectsCollection.InsertOneAsync(newProject);

    public async Task CreateManyAsync(IEnumerable<Project> projects) =>
        await _projectsCollection.InsertManyAsync(projects);

    public async Task UpdateAsync(string id, Project updatedProject) =>
        await _projectsCollection.ReplaceOneAsync(x => x.Id == id, updatedProject);

    public async Task RemoveAsync(string id) =>
        await _projectsCollection.DeleteOneAsync(x => x.Id == id);
}
