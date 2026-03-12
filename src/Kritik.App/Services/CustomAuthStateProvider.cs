using System.Security.Claims;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Components.Authorization;

namespace Kritik.App.Services;

public class CustomAuthStateProvider : AuthenticationStateProvider
{
    private ClaimsPrincipal _anonymous = new ClaimsPrincipal(new ClaimsIdentity());

    public override Task<AuthenticationState> GetAuthenticationStateAsync()
    {
        var token = Preferences.Get("jwt_token", string.Empty);
        var username = Preferences.Get("user_name", string.Empty);
        var role = Preferences.Get("user_role", string.Empty);
        
        if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(username))
        {
            return Task.FromResult(new AuthenticationState(_anonymous));
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.Name, username),
            new Claim(ClaimTypes.Role, role)
        };

        var identity = new ClaimsIdentity(claims, "CustomAuth");
        var user = new ClaimsPrincipal(identity);

        return Task.FromResult(new AuthenticationState(user));
    }

    public void NotifyUserLoggedIn(User user, string token)
    {
        // Save to preferences for persistence
        Preferences.Set("jwt_token", token);
        Preferences.Set("user_name", user.Username);
        Preferences.Set("user_role", user.Role);

        var claims = new[]
        {
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var identity = new ClaimsIdentity(claims, "CustomAuth");
        var principal = new ClaimsPrincipal(identity);
        
        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(principal)));
    }

    public void NotifyUserLoggedOut()
    {
        Preferences.Remove("jwt_token");
        Preferences.Remove("user_name");
        Preferences.Remove("user_role");

        NotifyAuthenticationStateChanged(Task.FromResult(new AuthenticationState(_anonymous)));
    }
}
