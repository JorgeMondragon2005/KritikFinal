using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace Kritik.Shared.Models;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string? Id { get; set; }

    public string Email { get; set; } = null!;
    public string PasswordHash { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Role { get; set; } = "Student"; // Student, Evaluator, Admin
    public bool IsEmailVerified { get; set; } = false;
    public string? VerificationCode { get; set; }

    // Profile fields
    public string? Telefono { get; set; }
    public string? Bio { get; set; }
    public string? FotoPerfil { get; set; }
}

public class LoginRequest
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
}

public class LoginResponse
{
    public string Id { get; set; } = null!;
    public string Token { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Role { get; set; } = null!;
}
