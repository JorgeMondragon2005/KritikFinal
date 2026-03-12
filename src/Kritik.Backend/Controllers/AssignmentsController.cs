using Kritik.Backend.Services;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Mvc;

namespace Kritik.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AssignmentsController : ControllerBase
{
    private readonly AssignmentService _assignmentService;
    private readonly EnrollmentService _enrollmentService;
    private readonly ClassroomService _classroomService;

    public AssignmentsController(AssignmentService assignmentService, EnrollmentService enrollmentService, ClassroomService classroomService)
    {
        _assignmentService = assignmentService;
        _enrollmentService = enrollmentService;
        _classroomService = classroomService;
    }

    [HttpGet]
    public async Task<List<Assignment>> Get([FromQuery] string? teacherId, [FromQuery] string? studentId)
    {
        if (!string.IsNullOrEmpty(studentId))
        {
            var enrollments = await _enrollmentService.GetByStudentAsync(studentId);
            var activeClassIds = enrollments
                .Where(e => e.Status == "Accepted")
                .Select(e => e.ClassroomId)
                .Distinct()
                .ToList();

            var allAssignments = new List<Assignment>();
            foreach (var classId in activeClassIds)
            {
                var classroom = await _classroomService.GetAsync(classId);
                if (classroom == null) continue;

                var classAssignments = await _assignmentService.GetByClassAsync(classId);
                allAssignments.AddRange(classAssignments);
            }

            // Deduplicate by ID and Title
            return allAssignments
                .GroupBy(a => a.Id)
                .Select(g => g.First())
                .GroupBy(a => a.Title)
                .Select(g => g.First())
                .ToList();
        }

        if (!string.IsNullOrEmpty(teacherId))
        {
            var teacherClasses = await _classroomService.GetByTeacherAsync(teacherId);
            var classIds = teacherClasses.Select(c => c.Id).Where(id => id != null).ToList();
            
            var allAssignments = new List<Assignment>();
            foreach (var classId in classIds)
            {
                var classAssignments = await _assignmentService.GetByClassAsync(classId!);
                allAssignments.AddRange(classAssignments);
            }
            
            // Deduplicate by ID and Title
            return allAssignments
                .GroupBy(a => a.Id)
                .Select(g => g.First())
                .GroupBy(a => a.Title)
                .Select(g => g.First())
                .ToList();
        }
        
        // Return empty list instead of ALL assignments if no filter is provided
        // unless it's an admin context (which would use a different specific endpoint if needed)
        return new List<Assignment>();
    }

    [HttpGet("classroom/{classroomId}")]
    public async Task<List<Assignment>> GetByClassroom(string classroomId)
    {
        return await _assignmentService.GetByClassAsync(classroomId);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Assignment>> GetById(string id)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        return assignment;
    }

    [HttpGet("code/{code}")]
    public async Task<ActionResult<Assignment>> GetByCode(string code)
    {
        var assignment = await _assignmentService.GetByAccessCodeAsync(code);
        if (assignment is null) return NotFound();
        return assignment;
    }

    [HttpPost]
    public async Task<IActionResult> Post(Assignment newAssignment)
    {
        await _assignmentService.CreateAsync(newAssignment);
        return Ok(newAssignment);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(string id, Assignment updatedAssignment)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        
        updatedAssignment.Id = assignment.Id;
        await _assignmentService.UpdateAsync(id, updatedAssignment);
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id)
    {
        var assignment = await _assignmentService.GetAsync(id);
        if (assignment is null) return NotFound();
        
        await _assignmentService.RemoveAsync(id);
        return NoContent();
    }
}
