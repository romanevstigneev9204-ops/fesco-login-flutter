namespace BatteryTray;

internal static class ChargeStateText
{
    public static string Format(BatteryChargeState state) => state switch
    {
        BatteryChargeState.Charging => "Заряжается",
        BatteryChargeState.NotCharging => "Не заряжается",
        _ => "Состояние неизвестно",
    };
}
