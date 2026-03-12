using System.Net.Http.Json;
using Kritik.Shared.Models;

namespace Kritik.App.Services;

public class CriteriaService
{
    private readonly HttpClient _httpClient;

    public CriteriaService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<List<Criterion>> GetCriteriaAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<Criterion>>("api/criteria") ?? new List<Criterion>();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching criteria: {ex.Message}");
            return GetDefaultCriteria();
        }
    }

    private List<Criterion> GetDefaultCriteria()
    {
        return new List<Criterion>
        {
            new Criterion { Id = "1", Name = "Innovación", Description = "Creatividad de la solución." },
            new Criterion { Name = "Técnica", Description = "Uso de herramientas." },
            new Criterion { Name = "Impacto", Description = "Valor social." }
        };
    }
}
