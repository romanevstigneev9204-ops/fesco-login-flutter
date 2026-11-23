namespace BatteryTray;

/// <summary>
/// A single reading from one source before devices are merged.
/// Percent is null when that source had no usable battery value.
/// </summary>
public sealed record BatteryObservation(
    string Id,
    string? Address,
    string Name,
    int? Percent,
    BatteryChargeState ChargeState,
    bool FromGatt,
    DateTimeOffset ObservedAt);
