using System.Net.Http.Json;
using Kritik.Shared.Models;
using Microsoft.AspNetCore.Components.Authorization;

namespace Kritik.App.Services;

public class AuthService
{
    private readonly HttpClient _httpClient;
    private readonly AuthenticationStateProvider _authStateProvider;
    private User? _currentUser;

    public AuthService(HttpClient httpClient, AuthenticationStateProvider authStateProvider)
    {
        _httpClient = httpClient;
        _authStateProvider = authStateProvider;
    }

    public async Task<User?> LoginAsync(string email, string password)
    {
        try
        {
            var request = new LoginRequest { Username = email, Password = password };
            var response = await _httpClient.PostAsJsonAsync("api/auth/login", request);

            if (response.IsSuccessStatusCode)
            {
                var loginResponse = await response.Content.ReadFromJsonAsync<LoginResponse>();
                if (loginResponse != null)
                {
                    _currentUser = new User
                    {
                        Id = email, // Or use a real ID from response if available
                        Username = email,
                        FullName = loginResponse.FullName,
                        Role = loginResponse.Role
                    };
                    
                    if (_authStateProvider is CustomAuthStateProvider customAuthProvider)
                    {
                        customAuthProvider.NotifyUserLoggedIn(_currentUser, loginResponse.Token);
                    }
                    else
                    {
                        Console.WriteLine("Warning: Expected _authStateProvider to be CustomAuthStateProvider");
                    }

                    return _currentUser;
                }
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Login failed: {ex.Message}");
        }
        return null;
    }

    public async Task<bool> RegisterAsync(User newUser)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/auth/register", newUser);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Registration failed: {ex.Message}");
            return false;
        }
    }

    public async Task LogoutAsync()
    {
        _currentUser = null;
        if (_authStateProvider is CustomAuthStateProvider customAuthProvider)
        {
            customAuthProvider.NotifyUserLoggedOut();
        }
        await Task.CompletedTask;
    }
    
    public User? GetCurrentUser()
    {
        return _currentUser;
    }
}
