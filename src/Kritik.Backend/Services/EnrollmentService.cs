using Kritik.Backend.Settings;
using Kritik.Shared.Models;
using Microsoft.Extensions.Options;
using MongoDB.Driver;

namespace Kritik.Backend.Services;

public class EnrollmentService
{
    private readonly IMongoCollection<ClassEnrollment> _enrollmentCollection;

    public EnrollmentService(IOptions<MongoDBSettings> settings, IMongoDatabase database)
    {
        // Per user rules: Use 'cita' for join requests/enrollments
        _enrollmentCollection = database.GetCollection<ClassEnrollment>("cita");
    }

    public async Task<List<ClassEnrollment>> GetByClassAsync(string classroomId) =>
        await _enrollmentCollection.Find(x => x.ClassroomId == classroomId).ToListAsync();

    public async Task<List<ClassEnrollment>> GetByStudentAsync(string studentId) =>
        await _enrollmentCollection.Find(x => x.StudentId == studentId).ToListAsync();

    public async Task<ClassEnrollment?> GetAsync(string studentId, string classroomId) =>
        await _enrollmentCollection.Find(x => x.StudentId == studentId && x.ClassroomId == classroomId).FirstOrDefaultAsync();

    public async Task CreateAsync(ClassEnrollment enrollment) =>
        await _enrollmentCollection.InsertOneAsync(enrollment);

    public async Task UpdateStatusAsync(string id, string status)
    {
        var update = Builders<ClassEnrollment>.Update.Set(x => x.Status, status);
        await _enrollmentCollection.UpdateOneAsync(x => x.Id == id, update);
    }

    public async Task RemoveAsync(string id) =>
        await _enrollmentCollection.DeleteOneAsync(x => x.Id == id);

    public async Task RemoveByClassroomAsync(string classroomId) =>
        await _enrollmentCollection.DeleteManyAsync(x => x.ClassroomId == classroomId);
}
