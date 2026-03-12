using System.Net.Http.Json;
using Kritik.Shared.Models;


namespace Kritik.App.Services;

public class EvaluationService
{
    private readonly HttpClient _httpClient;

    private readonly Queue<Evaluation> _retryQueue = new();
    private bool _isProcessingQueue = false;

    public EvaluationService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<bool> SubmitEvaluationAsync(Evaluation evaluation)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/evaluations", evaluation);
            if (response.IsSuccessStatusCode) return true;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Network error: {ex.Message}. Queuing evaluation for retry.");
            _retryQueue.Enqueue(evaluation);
            _ = ProcessQueueInBackground();
            return true; // Return true as we've handled it via retry queue
        }
        return false;
    }

    private async Task ProcessQueueInBackground()
    {
        if (_isProcessingQueue) return;
        _isProcessingQueue = true;

        while (_retryQueue.Count > 0)
        {
            try
            {
                await Task.Delay(10000); // Wait 10s between retries
                var evaluation = _retryQueue.Peek();
                var response = await _httpClient.PostAsJsonAsync("api/evaluations", evaluation);
                if (response.IsSuccessStatusCode)
                {
                    _retryQueue.Dequeue();
                    Console.WriteLine("Successfully synced queued evaluation.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Retry failed: {ex.Message}");
                await Task.Delay(5000); // Wait a bit more before next retry
            }
        }
        _isProcessingQueue = false;
    }

    public async Task<List<Evaluation>> GetEvaluationsAsync()
    {
        try
        {
            return await _httpClient.GetFromJsonAsync<List<Evaluation>>("api/evaluations") ?? new List<Evaluation>();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error fetching evaluations: {ex.Message}");
            return new List<Evaluation>();
        }
    }
}
