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
    private readonly UserService _userService;
    private readonly EmailService _emailService;
    private readonly NotificationService _notificationService;

    public AssignmentsController(
        AssignmentService assignmentService, 
        EnrollmentService enrollmentService, 
        ClassroomService classroomService,
        UserService userService,
        EmailService emailService,
        NotificationService notificationService)
    {
        _assignmentService = assignmentService;
        _enrollmentService = enrollmentService;
        _classroomService = classroomService;
        _userService = userService;
        _emailService = emailService;
        _notificationService = notificationService;
    }

    [HttpGet]
    public async Task<List<Assignment>> Get([FromQuery] string? teacherId, [FromQuery] string? studentId, [FromQuery] string? evaluatorId)
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
            var teacherAssignments = await _assignmentService.GetByTeacherAsync(teacherId);
            return teacherAssignments;
        }
        
        if (!string.IsNullOrEmpty(evaluatorId))
        {
            var allAssignments = await _assignmentService.GetAsync();
            return allAssignments
                .Where(a => a.Jurors != null && a.Jurors.Any(j => j.UserId == evaluatorId))
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
        var teacher = await _userService.GetAsync(newAssignment.TeacherId);
        string teacherName = teacher?.FullName ?? "Un Profesor";

        newAssignment.AssignedEvaluators ??= new List<string>();

        if (newAssignment.Jurors != null && newAssignment.Jurors.Any())
        {
            foreach (var juror in newAssignment.Jurors)
            {
                var existingUser = await _userService.GetByEmailAsync(juror.Email.Trim().ToLower());
                if (existingUser != null)
                {
                    juror.UserId = existingUser.Id;
                    if (!newAssignment.AssignedEvaluators.Contains(existingUser.Id))
                    {
                        newAssignment.AssignedEvaluators.Add(existingUser.Id);
                    }
                    if (existingUser.Role?.ToLower() == "student") 
                    {
                        existingUser.Role = "Evaluator";
                        await _userService.UpdateAsync(existingUser.Id!, existingUser);
                    }
                    // Background fire-and-forget
                    _ = _emailService.SendJurorInvitationAsync(juror.Email, newAssignment.Title, teacherName, false);
                }
                else
                {
                    _ = _emailService.SendJurorInvitationAsync(juror.Email, newAssignment.Title, teacherName, true);
                }
            }
        }

        await _assignmentService.CreateAsync(newAssignment);

        // Notificar a alumnos inscritos
        if (!string.IsNullOrEmpty(newAssignment.ClassroomId))
        {
            var enrollments = await _enrollmentService.GetByClassAsync(newAssignment.ClassroomId);
            var studentsToNotify = enrollments.Where(e => e.Status == "Accepted").Select(e => e.StudentId).ToList();
            
            foreach (var studentId in studentsToNotify)
            {
                await _notificationService.CreateAsync(new Notification
                {
                    UserId = studentId,
                    Title = "Nueva Tarea/Convocatoria",
                    Message = $"El profesor {teacherName} ha publicado '{newAssignment.Title}'.",
                    CreatedAt = DateTime.UtcNow,
                    ActionUrl = $"/assignment/{newAssignment.Id}"
                });
            }
        }

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
