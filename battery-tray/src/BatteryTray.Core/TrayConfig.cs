using System.Text.Json;
using System.Text.Json.Serialization;

namespace BatteryTray;

public sealed class TrayConfig
{
    public const int DefaultRefreshIntervalSeconds = 30;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
        NumberHandling = JsonNumberHandling.Strict,
    };

    public bool UseDemoProvider { get; init; }

    public int RefreshIntervalSeconds { get; init; } = DefaultRefreshIntervalSeconds;

    public int NormalizedRefreshSeconds
    {
        get
        {
            var seconds = RefreshIntervalSeconds <= 0
                ? DefaultRefreshIntervalSeconds
                : RefreshIntervalSeconds;
            return Math.Clamp(seconds, 10, 300);
        }
    }

    public static TrayConfig Load(string directory)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(directory);
        var path = Path.Combine(directory, "appsettings.json");
        if (!File.Exists(path))
        {
            return new TrayConfig();
        }

        try
        {
            var json = File.ReadAllText(path);
            return JsonSerializer.Deserialize<TrayConfig>(json, JsonOptions) ?? new TrayConfig();
        }
        catch (Exception exception) when (exception is JsonException or IOException)
        {
            return new TrayConfig();
        }
    }
}
