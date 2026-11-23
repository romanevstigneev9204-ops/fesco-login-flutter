using Microsoft.Win32;

namespace BatteryTray;

internal sealed record ThemePalette(
    bool Light,
    bool HighContrast,
    Color Window,
    Color Text,
    Color Secondary,
    Color Track,
    Color Fill,
    Color FillLow,
    Color Border,
    Color Divider,
    Color ButtonHover,
    Color ButtonText,
    Color Demo)
{
    public static ThemePalette ForCurrentSystem()
    {
        if (SystemInformation.HighContrast)
        {
            return HighContrastTheme();
        }

        return AppsUseLightTheme() ? LightTheme() : DarkTheme();
    }

    public static bool TaskbarUsesLightTheme() =>
        ReadDword("SystemUsesLightTheme", fallback: 0) != 0;

    public static ThemePalette LightTheme() => new(
        Light: true,
        HighContrast: false,
        Window: Color.FromArgb(255, 255, 255),
        Text: Color.FromArgb(28, 28, 28),
        Secondary: Color.FromArgb(98, 98, 96),
        Track: Color.FromArgb(228, 228, 226),
        Fill: Color.FromArgb(46, 110, 92),
        FillLow: Color.FromArgb(164, 62, 50),
        Border: Color.FromArgb(214, 214, 210),
        Divider: Color.FromArgb(236, 236, 234),
        ButtonHover: Color.FromArgb(243, 243, 241),
        ButtonText: Color.FromArgb(46, 110, 92),
        Demo: Color.FromArgb(138, 90, 18));

    public static ThemePalette DarkTheme() => new(
        Light: false,
        HighContrast: false,
        Window: Color.FromArgb(32, 32, 32),
        Text: Color.FromArgb(244, 244, 242),
        Secondary: Color.FromArgb(168, 168, 166),
        Track: Color.FromArgb(58, 58, 58),
        Fill: Color.FromArgb(138, 196, 174),
        FillLow: Color.FromArgb(224, 140, 132),
        Border: Color.FromArgb(72, 72, 72),
        Divider: Color.FromArgb(48, 48, 48),
        ButtonHover: Color.FromArgb(46, 46, 46),
        ButtonText: Color.FromArgb(168, 210, 194),
        Demo: Color.FromArgb(230, 194, 122));

    public static ThemePalette HighContrastTheme() => new(
        Light: true,
        HighContrast: true,
        Window: SystemColors.Window,
        Text: SystemColors.WindowText,
        Secondary: SystemColors.GrayText,
        Track: SystemColors.ControlDark,
        Fill: SystemColors.Highlight,
        FillLow: SystemColors.Highlight,
        Border: SystemColors.WindowFrame,
        Divider: SystemColors.ControlDark,
        ButtonHover: SystemColors.ControlLight,
        ButtonText: SystemColors.HotTrack,
        Demo: SystemColors.HotTrack);

    private static bool AppsUseLightTheme() => ReadDword("AppsUseLightTheme", fallback: 1) != 0;

    private static int ReadDword(string name, int fallback)
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(
                @"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            return key?.GetValue(name) is int value ? value : fallback;
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException or System.Security.SecurityException)
        {
            return fallback;
        }
    }
}
