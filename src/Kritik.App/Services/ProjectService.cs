using System.Net.Http.Json;
using Kritik.Shared.Models;

namespace Kritik.App.Services;

public class ProjectService
{
    private readonly HttpClient _httpClient;

    public ProjectService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<List<Project>> GetProjectsAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<Project>>("api/projects") ?? new List<Project>();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching projects: {ex.Message}");
            return GetMockProjects();
        }
    }

    public async Task<List<ProjectRankingDTO>> GetRankingsAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<ProjectRankingDTO>>("api/projects/ranking") ?? new List<ProjectRankingDTO>();
        }
        catch
        {
            return GetMockRankings();
        }
    }

    private List<Project> GetMockProjects()
    {
        return new List<Project>
        {
            new Project { Id = "1", TeamName = "EcoSmart", Category = "Sostenibilidad", Description = "Basurero inteligente con IA." },
            new Project { Id = "2", TeamName = "EduVR", Category = "Educación", Description = "Realidad virtual para escuelas." }
        };
    }

    private List<ProjectRankingDTO> GetMockRankings()
    {
        return new List<ProjectRankingDTO>
        {
            new ProjectRankingDTO { ProjectId = "1", TeamName = "EcoSmart Bin", Category = "Sostenibilidad", AverageScore = 9.8, TotalVotes = 45, IntegrityRate = 1.0 },
            new ProjectRankingDTO { ProjectId = "2", TeamName = "EduTech VR", Category = "Educación", AverageScore = 9.5, TotalVotes = 38, IntegrityRate = 0.98 },
            new ProjectRankingDTO { ProjectId = "3", TeamName = "HealthTrack AI", Category = "Salud", AverageScore = 9.2, TotalVotes = 41, IntegrityRate = 0.95 },
            new ProjectRankingDTO { ProjectId = "4", TeamName = "AgroDrone", Category = "Tecnología", AverageScore = 8.9, TotalVotes = 30, IntegrityRate = 1.0 },
            new ProjectRankingDTO { ProjectId = "5", TeamName = "FinBot", Category = "Finanzas", AverageScore = 8.5, TotalVotes = 25, IntegrityRate = 0.92 }
        };
    }

    public async Task<Project?> GetProjectByIdAsync(string id)
    {
        try
        {
             return await _httpClient.GetFromJsonAsync<Project>($"api/projects/{id}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching project {id}: {ex.Message}");
            return null;
        }
    }

    public async Task<bool> UpsertProjectsAsync(List<Project> projects)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/projects/batch", projects);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error importing projects: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> UpdateProjectAsync(string id, Project project)
    {
        try
        {
            var response = await _httpClient.PutAsJsonAsync($"api/projects/{id}", project);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error updating project {id}: {ex.Message}");
            return false;
        }
    }
}
