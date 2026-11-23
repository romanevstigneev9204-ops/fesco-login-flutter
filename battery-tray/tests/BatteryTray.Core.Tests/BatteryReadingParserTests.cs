namespace BatteryTray.Tests;

public sealed class BatteryReadingParserTests
{
    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(72)]
    [InlineData(100)]
    public void TryReadPercent_AcceptsLiteralIntegers(int value)
    {
        Assert.Equal(value, BatteryReadingParser.TryReadPercent(value));
        Assert.Equal(value, BatteryReadingParser.TryReadPercent((byte)value));
        Assert.Equal(value, BatteryReadingParser.TryReadPercent(value.ToString(System.Globalization.CultureInfo.InvariantCulture)));
        Assert.Equal(value, BatteryReadingParser.TryReadPercent(value + "%"));
    }

    [Theory]
    [InlineData(null)]
    [InlineData(-1)]
    [InlineData(101)]
    [InlineData(255)]
    public void TryReadPercent_RejectsMissingAndOutOfRange(object? value)
    {
        Assert.Null(BatteryReadingParser.TryReadPercent(value));
    }

    [Fact]
    public void TryReadPercent_DoesNotScaleValuesAboveOneHundred()
    {
        Assert.Null(BatteryReadingParser.TryReadPercent((byte)180));
        Assert.Null(BatteryReadingParser.TryReadPercent(10.5d));
        Assert.Equal(10, BatteryReadingParser.TryReadPercent(10.0d));
        Assert.Null(BatteryReadingParser.TryReadPercent("about 40"));
        Assert.Null(BatteryReadingParser.TryReadPercent(new byte[] { 40, 1 }));
        Assert.Equal(40, BatteryReadingParser.TryReadPercent(new byte[] { 40 }));
    }

    [Fact]
    public void ParseBatteryLevelStatus_ReadsChargeBits()
    {
        Assert.Equal(BatteryChargeState.Charging, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0x40, 0x00]));
        Assert.Equal(BatteryChargeState.Charging, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0x42, 0x00]));
        Assert.Equal(BatteryChargeState.NotCharging, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0x80, 0x00]));
        Assert.Equal(BatteryChargeState.NotCharging, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0xC0, 0x00]));
        Assert.Equal(BatteryChargeState.Unknown, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0x00, 0x00]));
        Assert.Equal(BatteryChargeState.Unknown, BatteryReadingParser.ParseBatteryLevelStatus([0x00, 0x40]));
        Assert.Equal(BatteryChargeState.Unknown, BatteryReadingParser.ParseBatteryLevelStatus([]));
    }

    [Fact]
    public void TryReadEmbeddedBatteryLevel_UsesFlaggedOffset()
    {
        Assert.Null(BatteryReadingParser.TryReadEmbeddedBatteryLevel([0x00, 0x40, 0x00]));
        Assert.Equal(40, BatteryReadingParser.TryReadEmbeddedBatteryLevel([0x02, 0x00, 0x00, 40]));
        Assert.Equal(80, BatteryReadingParser.TryReadEmbeddedBatteryLevel([0x03, 0x40, 0x00, 0x01, 0x00, 80]));
        Assert.Null(BatteryReadingParser.TryReadEmbeddedBatteryLevel([0x02, 0x00, 0x00, 140]));
        Assert.Null(BatteryReadingParser.TryReadEmbeddedBatteryLevel([0x03, 0x00, 0x00, 0x01]));
    }
}
