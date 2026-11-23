using System.Globalization;

namespace BatteryTray;

/// <summary>
/// Turns raw OS or GATT values into a percent or charge state.
/// Values outside 0–100 are rejected rather than scaled into a fake percentage.
/// </summary>
public static class BatteryReadingParser
{
    public static int? TryReadPercent(object? value)
    {
        switch (value)
        {
            case null:
                return null;
            case byte unsignedByte:
                return InRange(unsignedByte);
            case sbyte signedByte:
                return InRange(signedByte);
            case short int16:
                return InRange(int16);
            case ushort uint16:
                return InRange(uint16);
            case int int32:
                return InRange(int32);
            case uint uint32 when uint32 <= int.MaxValue:
                return InRange((int)uint32);
            case long int64 when int64 is >= int.MinValue and <= int.MaxValue:
                return InRange((int)int64);
            case float single:
                return FromReal(single);
            case double real:
                return FromReal(real);
            case string text:
                return FromText(text);
            case byte[] bytes when bytes.Length == 1:
                return InRange(bytes[0]);
            default:
                return null;
        }
    }

    /// <summary>
    /// Battery Level Status (0x2BED). Power State is the uint16 at offset 1.
    /// Charge State is bits 6–7: 0 unknown, 1 charging, 2 discharging active, 3 discharging inactive.
    /// </summary>
    public static BatteryChargeState ParseBatteryLevelStatus(ReadOnlySpan<byte> value)
    {
        if (value.Length < 3)
        {
            return BatteryChargeState.Unknown;
        }

        var powerState = (ushort)(value[1] | (value[2] << 8));
        return ((powerState >> 6) & 0x3) switch
        {
            1 => BatteryChargeState.Charging,
            2 or 3 => BatteryChargeState.NotCharging,
            _ => BatteryChargeState.Unknown,
        };
    }

    /// <summary>
    /// Optional Battery Level embedded in Battery Level Status, used only when the
    /// dedicated Battery Level characteristic is absent.
    /// </summary>
    public static int? TryReadEmbeddedBatteryLevel(ReadOnlySpan<byte> value)
    {
        if (value.Length < 3)
        {
            return null;
        }

        var flags = value[0];
        var levelPresent = (flags & 0x02) != 0;
        if (!levelPresent)
        {
            return null;
        }

        var identifierPresent = (flags & 0x01) != 0;
        var offset = 3 + (identifierPresent ? 2 : 0);
        if (offset >= value.Length)
        {
            return null;
        }

        return InRange(value[offset]);
    }

    private static int? FromText(string text)
    {
        var trimmed = text.Trim();
        if (trimmed.EndsWith('%'))
        {
            trimmed = trimmed[..^1].Trim();
        }

        if (!int.TryParse(trimmed, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed))
        {
            return null;
        }

        return InRange(parsed);
    }

    private static int? FromReal(double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            return null;
        }

        var nearest = Math.Round(value);
        if (Math.Abs(value - nearest) > 0.001)
        {
            return null;
        }

        if (nearest is < int.MinValue or > int.MaxValue)
        {
            return null;
        }

        return InRange((int)nearest);
    }

    private static int? InRange(int value) => value is >= 0 and <= 100 ? value : null;
}
