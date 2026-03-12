using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class ClassroomService
{
    private readonly IMongoCollection<Classroom> _classroomCollection;

    public ClassroomService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        // Per user rules: Use 'taller' for classrooms
        _classroomCollection = database.GetCollection<Classroom>("taller");
    }

    public async Task<List<Classroom>> GetAsync() =>
        await _classroomCollection.Find(_ => true).ToListAsync();

    public async Task<List<Classroom>> GetByTeacherAsync(string teacherId) =>
        await _classroomCollection.Find(x => x.TeacherId == teacherId).ToListAsync();

    public async Task<List<Classroom>> GetByTeacherIdsAsync(List<string> teacherIds) =>
        await _classroomCollection.Find(x => teacherIds.Contains(x.TeacherId)).ToListAsync();

    public async Task<Classroom?> GetByCodeAsync(string code) =>
        await _classroomCollection.Find(x => x.AccessCode == code).FirstOrDefaultAsync();

    public async Task<Classroom?> GetAsync(string id) =>
        await _classroomCollection.Find(x => x.Id == id).FirstOrDefaultAsync();

    public async Task CreateAsync(Classroom newClassroom) =>
        await _classroomCollection.InsertOneAsync(newClassroom);

    public async Task UpdateAsync(string id, Classroom updatedClassroom) =>
        await _classroomCollection.ReplaceOneAsync(x => x.Id == id, updatedClassroom);

    public async Task RemoveAsync(string id) =>
        await _classroomCollection.DeleteOneAsync(x => x.Id == id);
}
