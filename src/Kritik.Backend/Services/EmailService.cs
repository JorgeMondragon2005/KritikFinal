using Kritik.Backend.Settings;
using Microsoft.Extensions.Options;
using System.Text;
using System.Text.Json;

namespace Kritik.Backend.Services;

public class EmailService
{
    private readonly BrevoSettings _brevoSettings;
    private readonly ILogger<EmailService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;

    public EmailService(IOptions<BrevoSettings> brevoSettings, ILogger<EmailService> logger, IHttpClientFactory httpClientFactory)
    {
        _brevoSettings = brevoSettings.Value;
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task SendVerificationCodeAsync(string toEmail, string code)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("api-key", _brevoSettings.ApiKey?.Trim());
            client.DefaultRequestHeaders.Add("accept", "application/json");

            var body = new
            {
                sender = new { name = _brevoSettings.SenderName, email = _brevoSettings.SenderEmail },
                to = new[] { new { email = toEmail } },
                subject = "🎓 Tu código de verificación - Kritik",
                htmlContent = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f9f9f9; border-radius: 12px;'>
                        <h2 style='color: #1a1a2e; text-align: center;'>Bienvenido a <span style='color: #f5a623;'>Kritik</span> 🎓</h2>
                        <p style='color: #444; font-size: 16px;'>Usa el siguiente código para verificar tu cuenta:</p>
                        <div style='text-align: center; margin: 32px 0;'>
                            <span style='font-size: 42px; font-weight: bold; letter-spacing: 12px; color: #1a1a2e; background: #fff; padding: 16px 32px; border-radius: 8px; border: 2px solid #f5a623;'>
                                {code}
                            </span>
                        </div>
                        <p style='color: #888; font-size: 13px; text-align: center;'>Este código expira en 15 minutos. Si no solicitaste esto, ignora este correo.</p>
                        <hr style='border: none; border-top: 1px solid #eee; margin: 24px 0;'/>
                        <p style='color: #bbb; font-size: 11px; text-align: center;'>© Kritik App - Plataforma de evaluación entre pares</p>
                    </div>"
            };

            var json = JsonSerializer.Serialize(body);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("https://api.brevo.com/v3/smtp/email", content);

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("✅ Correo de verificación enviado a {Email}", toEmail);
                Console.WriteLine($"✅ Correo de verificación enviado a {toEmail}");
            }
            else
            {
                var error = await response.Content.ReadAsStringAsync();
                _logger.LogError("❌ Error enviando correo a {Email}: {Error}", toEmail, error);
                Console.WriteLine($"❌ Error enviando correo a {toEmail}: {error}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ Excepción al enviar correo a {Email}", toEmail);
            Console.WriteLine($"❌ Excepción al enviar correo a {toEmail}: {ex.Message}");
        }
    }
}
