namespace BatteryTray;

public static class BatteryProviders
{
    public static IBatteryProvider Select(TrayConfig config, Func<IBatteryProvider> realProvider)
    {
        ArgumentNullException.ThrowIfNull(config);
        ArgumentNullException.ThrowIfNull(realProvider);
        return config.UseDemoProvider ? new DemoBatteryProvider() : realProvider();
    }
}
