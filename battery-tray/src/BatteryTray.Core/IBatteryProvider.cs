namespace BatteryTray;

public interface IBatteryProvider
{
    string Name { get; }

    /// <summary>
    /// True only for the labeled preview provider. The tray uses a real provider unless config opts in.
    /// </summary>
    bool IsDemo { get; }

    Task<BatterySnapshot> ReadAsync(CancellationToken cancellationToken);
}
