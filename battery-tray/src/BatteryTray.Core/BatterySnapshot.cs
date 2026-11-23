namespace BatteryTray;

public sealed record BatterySnapshot(
    IReadOnlyList<DeviceBattery> Devices,
    DateTimeOffset RetrievedAt,
    BatteryReadStatus Status)
{
    public static BatterySnapshot Empty(BatteryReadStatus status) =>
        new(Array.Empty<DeviceBattery>(), DateTimeOffset.Now, status);
}
