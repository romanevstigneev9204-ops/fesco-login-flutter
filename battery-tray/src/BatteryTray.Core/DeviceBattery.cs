namespace BatteryTray;

/// <summary>
/// One device with a real battery percentage. Percent is never implied.
/// </summary>
public sealed record DeviceBattery
{
    public DeviceBattery(
        string id,
        string name,
        int percent,
        BatteryChargeState chargeState,
        DateTimeOffset observedAt)
    {
        if (string.IsNullOrWhiteSpace(id))
        {
            throw new ArgumentException("Device id is required.", nameof(id));
        }

        if (percent is < 0 or > 100)
        {
            throw new ArgumentOutOfRangeException(
                nameof(percent),
                percent,
                "Battery percent must be between 0 and 100.");
        }

        Id = id.Trim();
        Name = (name ?? string.Empty).Trim();
        Percent = percent;
        ChargeState = chargeState;
        ObservedAt = observedAt;
    }

    public string Id { get; }

    public string Name { get; }

    public int Percent { get; }

    public BatteryChargeState ChargeState { get; }

    public DateTimeOffset ObservedAt { get; }
}
