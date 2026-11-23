namespace BatteryTray;

/// <summary>
/// Charging state when the device or Windows actually reports one.
/// </summary>
public enum BatteryChargeState
{
    Unknown = 0,
    Charging = 1,
    NotCharging = 2,
}
