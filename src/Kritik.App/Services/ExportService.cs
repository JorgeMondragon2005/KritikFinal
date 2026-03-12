using System.Text;
using Microsoft.JSInterop;

namespace Kritik.App.Services;

public class ExportService
{
    private readonly IJSRuntime _js;

    public ExportService(IJSRuntime js)
    {
        _js = js;
    }

    public async Task ExportRankingToCsvAsync(IEnumerable<Kritik.Shared.Models.ProjectRankingDTO> rankings)
    {
        var csv = new StringBuilder();
        csv.AppendLine("Posicion,Equipo,Categoria,Puntaje Promedio,Votos Totales");
        
        int pos = 1;
        foreach (var r in rankings)
        {
            csv.AppendLine($"{pos},{r.TeamName},{r.Category},{r.AverageScore},{r.TotalVotes}");
            pos++;
        }

        var bytes = Encoding.UTF8.GetBytes(csv.ToString());
        var base64 = Convert.ToBase64String(bytes);
        
        await _js.InvokeVoidAsync("downloadFile", "Kritik_Ranking.csv", "text/csv", base64);
    }
}
