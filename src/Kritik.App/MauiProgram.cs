using Microsoft.Extensions.Logging;
using Microsoft.Maui.Devices;
using Microsoft.AspNetCore.Components.Authorization;

namespace Kritik.App;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		var builder = MauiApp.CreateBuilder();
		builder
			.UseMauiApp<App>()
			.ConfigureFonts(fonts =>
			{
				fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
			});

		builder.Services.AddMauiBlazorWebView();

#if DEBUG
		builder.Services.AddBlazorWebViewDeveloperTools();
		builder.Logging.AddDebug();
#endif
        
        // Configure HttpClient for Kritik.Backend
        string baseAddress = DeviceInfo.Platform == DevicePlatform.Android ? "http://10.0.2.2:5229" : "http://localhost:5229";
        
        // Allow specific IP override for physical Android devices if needed
        // baseAddress = "http://192.168.0.130:5229"; 

        builder.Services.AddScoped(sp => new HttpClient { BaseAddress = new Uri(baseAddress) });

        builder.Services.AddScoped<Services.ValidationService>();

        builder.Services.AddScoped<Services.ProjectService>();
        builder.Services.AddScoped<Services.EvaluationService>();
        builder.Services.AddScoped<Services.ToastService>();
        builder.Services.AddScoped<Services.AuthService>();
        builder.Services.AddScoped<Services.CriteriaService>();
        builder.Services.AddScoped<Services.ExportService>();
        builder.Services.AddSingleton<Services.NotificationService>();
        
        builder.Services.AddAuthorizationCore();
        builder.Services.AddScoped<AuthenticationStateProvider, Services.CustomAuthStateProvider>();

		return builder.Build();
	}
}
