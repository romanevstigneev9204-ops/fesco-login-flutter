namespace BatteryTray;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        using var instance = new Mutex(false, @"Local\BatteryTray.SingleInstance");
        try
        {
            if (!instance.WaitOne(TimeSpan.Zero))
            {
                return;
            }
        }
        catch (AbandonedMutexException)
        {
            // The previous instance exited without releasing the mutex. This process owns it now.
        }

        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        var config = TrayConfig.Load(AppContext.BaseDirectory);
        var provider = BatteryProviders.Select(config, () => new WindowsBluetoothBatteryProvider());

        Application.Run(new TrayApplicationContext(provider, config));
    }
}
