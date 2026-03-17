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
            
            var rawKey = _brevoSettings.ApiKey;
            Console.WriteLine($"[DEBUG] ApiKey string length: {(rawKey == null ? "NULL" : rawKey.Length.ToString())}");
            Console.WriteLine($"[DEBUG] ApiKey first 10 chars: {(string.IsNullOrEmpty(rawKey) ? "EMPTY" : rawKey.Substring(0, Math.Min(10, rawKey.Length)))}");
            
            client.DefaultRequestHeaders.Add("api-key", rawKey?.Trim());
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
                            <span style='font-size: 38px; font-weight: bold; letter-spacing: 6px; white-space: nowrap; color: #1a1a2e; background: #fff; padding: 16px 24px; border-radius: 8px; border: 2px solid #f5a623;'>
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
                var errorBody = await response.Content.ReadAsStringAsync();
                _logger.LogError("Error Brevo: [{Status}] {Error}", response.StatusCode, errorBody);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error crítico enviando correo: {Msg}", ex.Message);
        }
    }

    public async Task SendRecoveryCodeAsync(string toEmail, string token)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            var rawKey = _brevoSettings.ApiKey;
            client.DefaultRequestHeaders.Add("api-key", rawKey?.Trim());
            client.DefaultRequestHeaders.Add("accept", "application/json");

            var body = new
            {
                sender = new { name = _brevoSettings.SenderName, email = _brevoSettings.SenderEmail },
                to = new[] { new { email = toEmail } },
                subject = "🔐 Recuperación de Contraseña - Kritik",
                htmlContent = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f9f9f9; border-radius: 12px;'>
                        <h2 style='color: #1a1a2e; text-align: center;'>Kritik <span style='color: #f5a623;'>IA</span> </h2>
                        <p style='color: #444; font-size: 16px; text-align: center;'>Hemos recibido una solicitud para restablecer tu contraseña.</p>
                        <p style='color: #444; font-size: 14px; text-align: center;'>Utiliza este código temporal en la aplicación para crear tu nuevo acceso:</p>
                        <div style='text-align: center; margin: 32px 0;'>
                            <span style='font-size: 38px; font-weight: bold; letter-spacing: 6px; white-space: nowrap; color: #1a1a2e; background: #fff; padding: 16px 24px; border-radius: 8px; border: 2px solid #e74c3c;'>
                                {token}
                            </span>
                        </div>
                        <p style='color: #888; font-size: 13px; text-align: center;'>Este código expira. Si no has solicitado esto, puedes ignorar este correo y tu cuenta seguirá segura.</p>
                    </div>"
            };

            var json = JsonSerializer.Serialize(body);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            await client.PostAsync("https://api.brevo.com/v3/smtp/email", content);
        }
        catch(Exception ex)
        {
            _logger.LogError(ex, "Error enviando correo de recuperación a: {Email}", toEmail);
        }
    }
    public async Task SendJurorInvitationAsync(string toEmail, string assignmentTitle, string inviterName, bool isNewUser)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Add("api-key", _brevoSettings.ApiKey?.Trim());
            client.DefaultRequestHeaders.Add("accept", "application/json");

            var messageHtml = isNewUser
                ? $"<p>El profesor <b>{inviterName}</b> te ha invitado a evaluar el proyecto/convocatoria <b>'{assignmentTitle}'</b>.</p><p>Dado que aún no tienes una cuenta en Kritik, por favor regístrate en la aplicación con este correo para comenzar a evaluar los proyectos asignados.</p>"
                : $"<p>El profesor <b>{inviterName}</b> te ha asignado como Jurado en la convocatoria <b>'{assignmentTitle}'</b>.</p><p>Ingresa a tu cuenta de Kritik para ver los detalles de los proyectos a evaluar.</p>";

            var body = new
            {
                sender = new { name = _brevoSettings.SenderName, email = _brevoSettings.SenderEmail },
                to = new[] { new { email = toEmail } },
                subject = "🏛️ Invitación para Jurado Evaluador - Kritik",
                htmlContent = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 480px; margin: auto; padding: 32px; background: #f9f9f9; border-radius: 12px;'>
                        <h2 style='color: #1a1a2e; text-align: center;'><span style='color: #f5a623;'>Kritik</span> 🎓</h2>
                        {messageHtml}
                        <hr style='border: none; border-top: 1px solid #eee; margin: 24px 0;'/>
                        <p style='color: #bbb; font-size: 11px; text-align: center;'>© Kritik App - Plataforma de evaluación entre pares</p>
                    </div>"
            };

            var json = JsonSerializer.Serialize(body);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            await client.PostAsync("https://api.brevo.com/v3/smtp/email", content);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error enviando invitación de jurado a: {Email}", toEmail);
        }
    }
}
