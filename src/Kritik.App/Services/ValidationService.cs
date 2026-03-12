using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Maui.Storage;
using System.Net.Http;

namespace Kritik.App.Services
{
    public class ValidationService
    {
        private readonly HttpClient _http;

        public ValidationService(HttpClient http)
        {
            _http = http;
        }

        /// <summary>
        /// Valida si un usuario puede votar por un proyecto específico.
        /// </summary>
        /// <param name="projectId">Identificador del proyecto</param>
        /// <param name="userId">Identificador del usuario (Opcional para verificación remota)</param>
        /// <returns>True si YA ha votado, False si puede votar.</returns>
        public async Task<bool> HasVotedAsync(string projectId, string? userId = null)
        {
             // 1. Verificación Local (Rápida - Preferencias del Dispositivo)
            string key = $"vote_{projectId}";
            bool localVote = Preferences.Default.Get(key, false);
            if (localVote) return true;

            // 2. Verificación Remota (Seguridad - Backend)
            if (!string.IsNullOrEmpty(userId))
            {
                return !await CanEvaluateViaApiAsync(projectId, userId);
            }

            return false;
        }

        // Verifica si el dispositivo ya emitió un voto para este proyecto (Lógica de Negocio Remota)
        public async Task<bool> CanEvaluateViaApiAsync(string projectId, string userId)
        {
            try
            {
                // Nota: El endpoint original sugerido era api/evaluations/check
                // Ajustamos para que coincida con la firma del método
                var response = await _http.GetAsync($"api/evaluations/check?projectId={projectId}&userId={userId}");
                return response.IsSuccessStatusCode;
            }
            catch
            {
                // Por seguridad, si falla la red, asumimos que NO se puede evaluar para evitar inconsistencias
                // O podríamos permitirlo y validar luego. En este caso, seguimos la regla del usuario:
                return false; 
            }
        }

        /// <summary>
        /// Registra un voto para prevenir duplicados futuros.
        /// </summary>
        public void RegisterVote(string projectId)
        {
            string key = $"vote_{projectId}";
            Preferences.Default.Set(key, true);
        }

        // Valida que los criterios técnicos tengan un rango correcto (Principio de Prevención de Errores)
        public bool IsScoreValid(int score)
        {
            // La rúbrica actual usa 1-5, pero el requerimiento menciona 1-10. 
            // Ajustamos para permitir ambos o validamos según la configuración activa.
            // Por ahora, validamos rango positivo genérico para flexibilidad.
            return score >= 1 && score <= 10;
        }
    }
}
