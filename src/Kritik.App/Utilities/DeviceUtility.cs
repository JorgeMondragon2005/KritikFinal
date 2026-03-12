using Microsoft.Maui.Devices;

namespace Kritik.App.Utilities;

public static class DeviceUtility
{
    public static string GetBaseAddress()
    {
        return DeviceInfo.Platform == DevicePlatform.Android ? "http://10.0.2.2:5229" : "http://localhost:5229";
    }
}
