using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;

namespace Kritik.Backend.Services;

public class AIService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    public AIService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _apiKey = configuration["GeminiSettings:ApiKey"] ?? throw new ArgumentNullException("Gemini API Key is missing");
    }

    public async Task<string> GenerateContentAsync(string prompt)
    {
        if (string.IsNullOrEmpty(_apiKey) || _apiKey == "YOUR_GEMINI_API_KEY")
        {
            return "La API Key de Gemini no está configurada o es inválida.";
        }

        var url = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

        var requestBody = new
        {
            contents = new[]
            {
                new
                {
                    parts = new[]
                    {
                        new { text = prompt }
                    }
                }
            }
        };

        var jsonOptions = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        var content = new StringContent(JsonSerializer.Serialize(requestBody, jsonOptions), Encoding.UTF8, "application/json");

        var response = await _httpClient.PostAsync(url, content);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            throw new Exception($"Error from Gemini API: {response.StatusCode} - {errorContent}");
        }

        var responseString = await response.Content.ReadAsStringAsync();
        using var jsonDoc = JsonDocument.Parse(responseString);
        
        try
        {
            var root = jsonDoc.RootElement;
            var candidates = root.GetProperty("candidates");
            if (candidates.GetArrayLength() > 0)
            {
                var firstCandidate = candidates[0];
                var contentElem = firstCandidate.GetProperty("content");
                var parts = contentElem.GetProperty("parts");
                if (parts.GetArrayLength() > 0)
                {
                    return parts[0].GetProperty("text").GetString() ?? string.Empty;
                }
            }
        }
        catch (Exception ex)
        {
            throw new Exception("Failed to parse Gemini response.", ex);
        }

        return string.Empty;
    }
}
