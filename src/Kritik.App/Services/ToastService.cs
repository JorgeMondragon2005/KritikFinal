using System;

namespace Kritik.App.Services
{
    public class ToastService
    {
        public event Action<string, string>? OnShow;

        public void Show(string message, string type = "success")
        {
            OnShow?.Invoke(message, type);
        }
    }
}
