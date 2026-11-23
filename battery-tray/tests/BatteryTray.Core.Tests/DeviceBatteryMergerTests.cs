namespace BatteryTray.Tests;

public sealed class DeviceBatteryMergerTests
{
    private static readonly DateTimeOffset Earlier = new(2026, 11, 23, 8, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset Later = Earlier.AddMinutes(1);

    [Fact]
    public void Merge_DropsDevicesWithoutAPercent()
    {
        var devices = DeviceBatteryMerger.Merge(
        [
            Observation("mouse", "AA:BB:CC:DD:EE:01", "Мышь", null, BatteryChargeState.Unknown, false, Earlier),
            Observation("ghost", null, "Пусто", 140, BatteryChargeState.Charging, true, Later),
        ]);

        Assert.Empty(devices);
    }

    [Fact]
    public void Merge_PrefersGattPercentAndDoesNotAverage()
    {
        var devices = DeviceBatteryMerger.Merge(
        [
            Observation("classic", "aa:bb:cc:dd:ee:ff", "Наушники", 70, BatteryChargeState.Unknown, false, Later),
            Observation("le", "AA-BB-CC-DD-EE-FF", "Наушники LE", 61, BatteryChargeState.NotCharging, true, Earlier),
        ]);

        var device = Assert.Single(devices);
        Assert.Equal(61, device.Percent);
        Assert.Equal(BatteryChargeState.NotCharging, device.ChargeState);
        Assert.Equal("Наушники", device.Name);
    }

    [Fact]
    public void Merge_KeepsDistinctAddressesAndSortsByName()
    {
        var devices = DeviceBatteryMerger.Merge(
        [
            Observation("b", "11:22:33:44:55:02", "Мышь", 18, BatteryChargeState.Charging, true, Earlier),
            Observation("a", "11:22:33:44:55:01", "Клавиатура", 54, BatteryChargeState.Unknown, false, Earlier),
        ]);

        Assert.Equal(["Клавиатура", "Мышь"], devices.Select(device => device.Name).ToArray());
        Assert.Equal([54, 18], devices.Select(device => device.Percent).ToArray());
    }

    [Fact]
    public void Merge_UsesDeviceIdWhenAddressIsMissing()
    {
        var devices = DeviceBatteryMerger.Merge(
        [
            Observation("same", null, "Ручка", 40, BatteryChargeState.Unknown, false, Earlier),
            Observation("same", "   ", "Ручка", 41, BatteryChargeState.Charging, true, Later),
            Observation("other", null, "Другая", 10, BatteryChargeState.NotCharging, false, Earlier),
        ]);

        Assert.Equal(2, devices.Count);
        var pen = Assert.Single(devices, device => device.Name == "Ручка");
        Assert.Equal(41, pen.Percent);
        Assert.Equal(BatteryChargeState.Charging, pen.ChargeState);
    }

    [Fact]
    public void Selection_UsesLowestRealPercent()
    {
        Assert.Equal(12, BatterySelection.Lowest([80, 12, 40]));
        Assert.Equal(
            BatteryChargeState.Charging,
            BatterySelection.Combine([BatteryChargeState.Unknown, BatteryChargeState.NotCharging, BatteryChargeState.Charging]));
        Assert.Equal(
            BatteryChargeState.NotCharging,
            BatterySelection.Combine([BatteryChargeState.Unknown, BatteryChargeState.NotCharging]));
        Assert.Equal(BatteryChargeState.Unknown, BatterySelection.Combine([BatteryChargeState.Unknown]));
    }

    [Fact]
    public void DeviceBattery_RejectsInventedPercent()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() =>
            new DeviceBattery("id", "Имя", 101, BatteryChargeState.Unknown, Earlier));
    }

    private static BatteryObservation Observation(
        string id,
        string? address,
        string name,
        int? percent,
        BatteryChargeState charge,
        bool fromGatt,
        DateTimeOffset observedAt) =>
        new(id, address, name, percent, charge, fromGatt, observedAt);
}
