namespace BatteryTray;

/// <summary>
/// Collapses classic and LE views of the same radio into one row.
/// A GATT percent wins over a Windows property. Percents are never averaged.
/// </summary>
public static class DeviceBatteryMerger
{
    public static IReadOnlyList<DeviceBattery> Merge(IEnumerable<BatteryObservation> observations)
    {
        var groups = observations
            .Where(static observation => !string.IsNullOrWhiteSpace(observation.Id))
            .GroupBy(NormalizeKey, StringComparer.OrdinalIgnoreCase);

        var devices = new List<DeviceBattery>();
        foreach (var group in groups)
        {
            var withPercent = group
                .Where(static observation => observation.Percent is >= 0 and <= 100)
                .ToList();
            if (withPercent.Count == 0)
            {
                continue;
            }

            var chosen = withPercent
                .OrderByDescending(static observation => observation.FromGatt)
                .ThenByDescending(static observation => observation.ObservedAt)
                .ThenBy(static observation => observation.Id, StringComparer.Ordinal)
                .First();

            var charge = withPercent
                .OrderByDescending(static observation => observation.ChargeState != BatteryChargeState.Unknown)
                .ThenByDescending(static observation => observation.FromGatt)
                .ThenByDescending(static observation => observation.ObservedAt)
                .First()
                .ChargeState;

            var name = group
                .Select(static observation => observation.Name)
                .FirstOrDefault(static candidate => !string.IsNullOrWhiteSpace(candidate))
                ?.Trim() ?? string.Empty;

            devices.Add(new DeviceBattery(
                group.Key,
                name,
                chosen.Percent!.Value,
                charge,
                chosen.ObservedAt));
        }

        devices.Sort(static (left, right) =>
            string.Compare(left.Name, right.Name, StringComparison.CurrentCultureIgnoreCase));
        return devices;
    }

    public static string NormalizeKey(BatteryObservation observation)
    {
        var address = NormalizeAddress(observation.Address);
        if (!string.IsNullOrEmpty(address))
        {
            return "addr:" + address;
        }

        return "id:" + observation.Id.Trim();
    }

    public static string? NormalizeAddress(string? address)
    {
        if (string.IsNullOrWhiteSpace(address))
        {
            return null;
        }

        Span<char> hex = stackalloc char[address.Length];
        var count = 0;
        foreach (var character in address)
        {
            if (Uri.IsHexDigit(character))
            {
                hex[count++] = char.ToUpperInvariant(character);
            }
        }

        if (count < 12)
        {
            return null;
        }

        if (count > 12)
        {
            hex = hex[(count - 12)..count];
            count = 12;
        }

        return new string(hex[..count]);
    }
}
