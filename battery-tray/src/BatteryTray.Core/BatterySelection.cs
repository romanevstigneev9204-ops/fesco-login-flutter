namespace BatteryTray;

/// <summary>
/// Picks one reported percent when a single device exposes several battery services.
/// The lowest real reading is kept. Nothing is averaged.
/// </summary>
public static class BatterySelection
{
    public static int Lowest(IReadOnlyList<int> percents)
    {
        if (percents.Count == 0)
        {
            throw new ArgumentException("At least one percent is required.", nameof(percents));
        }

        var lowest = percents[0];
        for (var index = 1; index < percents.Count; index++)
        {
            if (percents[index] < lowest)
            {
                lowest = percents[index];
            }
        }

        return lowest;
    }

    public static BatteryChargeState Combine(IEnumerable<BatteryChargeState> states)
    {
        var sawNotCharging = false;
        foreach (var state in states)
        {
            if (state == BatteryChargeState.Charging)
            {
                return BatteryChargeState.Charging;
            }

            if (state == BatteryChargeState.NotCharging)
            {
                sawNotCharging = true;
            }
        }

        return sawNotCharging ? BatteryChargeState.NotCharging : BatteryChargeState.Unknown;
    }
}
