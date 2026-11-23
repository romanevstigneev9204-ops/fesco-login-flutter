namespace BatteryTray.Tests;

public sealed class DemoAndConfigTests
{
    [Fact]
    public async Task DemoProvider_IsLabeledAndStaysInRange()
    {
        var provider = new DemoBatteryProvider();
        var snapshot = await provider.ReadAsync(CancellationToken.None);

        Assert.True(provider.IsDemo);
        Assert.Equal(BatteryReadStatus.Ok, snapshot.Status);
        Assert.NotEmpty(snapshot.Devices);
        Assert.All(snapshot.Devices, device =>
        {
            Assert.InRange(device.Percent, 0, 100);
            Assert.StartsWith("Демо · ", device.Name, StringComparison.Ordinal);
        });
        Assert.Contains(snapshot.Devices, device => device.ChargeState == BatteryChargeState.Charging);
        Assert.Contains(snapshot.Devices, device => device.ChargeState == BatteryChargeState.NotCharging);
        Assert.Contains(snapshot.Devices, device => device.ChargeState == BatteryChargeState.Unknown);
    }

    [Fact]
    public void Select_KeepsDemoOffUnlessConfigAsksForIt()
    {
        var calls = 0;
        IBatteryProvider Real()
        {
            calls++;
            return new RecordingProvider();
        }

        var selected = BatteryProviders.Select(new TrayConfig(), Real);
        Assert.Equal(1, calls);
        Assert.False(selected.IsDemo);
        Assert.IsType<RecordingProvider>(selected);

        calls = 0;
        var demo = BatteryProviders.Select(new TrayConfig { UseDemoProvider = true }, Real);
        Assert.Equal(0, calls);
        Assert.True(demo.IsDemo);
    }

    [Fact]
    public void Load_MissingOrBrokenFileLeavesDemoOff()
    {
        var directory = Directory.CreateTempSubdirectory("battery-tray-config-");
        try
        {
            var missing = TrayConfig.Load(directory.FullName);
            Assert.False(missing.UseDemoProvider);
            Assert.Equal(30, missing.NormalizedRefreshSeconds);

            File.WriteAllText(Path.Combine(directory.FullName, "appsettings.json"), "{ not json");
            var broken = TrayConfig.Load(directory.FullName);
            Assert.False(broken.UseDemoProvider);
            Assert.Equal(30, broken.NormalizedRefreshSeconds);

            File.WriteAllText(
                Path.Combine(directory.FullName, "appsettings.json"),
                """
                {
                  "UseDemoProvider": true,
                  "RefreshIntervalSeconds": 3
                }
                """);
            var enabled = TrayConfig.Load(directory.FullName);
            Assert.True(enabled.UseDemoProvider);
            Assert.Equal(10, enabled.NormalizedRefreshSeconds);
        }
        finally
        {
            directory.Delete(recursive: true);
        }
    }

    private sealed class RecordingProvider : IBatteryProvider
    {
        public string Name => "Recording";

        public bool IsDemo => false;

        public Task<BatterySnapshot> ReadAsync(CancellationToken cancellationToken) =>
            Task.FromResult(BatterySnapshot.Empty(BatteryReadStatus.Ok));
    }
}
