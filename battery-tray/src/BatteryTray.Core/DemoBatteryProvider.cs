namespace BatteryTray;

/// <summary>
/// Fixed preview data for the flyout. Names and the provider flag say these are not real devices.
/// </summary>
public sealed class DemoBatteryProvider : IBatteryProvider
{
    public string Name => "Demo";

    public bool IsDemo => true;

    public Task<BatterySnapshot> ReadAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var now = DateTimeOffset.Now;
        IReadOnlyList<DeviceBattery> devices =
        [
            new("demo-headphones", "Демо · Наушники", 72, BatteryChargeState.NotCharging, now),
            new("demo-mouse", "Демо · Мышь", 18, BatteryChargeState.Charging, now),
            new("demo-keyboard", "Демо · Клавиатура", 54, BatteryChargeState.Unknown, now),
        ];

        return Task.FromResult(new BatterySnapshot(devices, now, BatteryReadStatus.Ok));
    }
}
