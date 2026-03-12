using Kritik.Shared.Models;

namespace Kritik.App.Services;

public class NotificationService
{
    public event Action<string, string>? OnNotificationReceived;

    public void Notify(string title, string message)
    {
        OnNotificationReceived?.Invoke(title, message);
    }

    // Mock SignalR "Hub" behavior
    public void StartListening()
    {
        _ = SimulateTraffic();
    }

    private async Task SimulateTraffic()
    {
        var random = new Random();
        while (true)
        {
            await Task.Delay(random.Next(30000, 60000)); // Every 30-60s
            var alerts = new[] 
            { 
                "¡Nuevo proyecto destacado!", 
                "Votación al 80% completada.", 
                "Mesa 4: Presentación iniciando." 
            };
            Notify("Evento Kritik", alerts[random.Next(alerts.Length)]);
        }
    }
}
