using System.Diagnostics;
using System.Text.RegularExpressions;
using Windows.Devices.Bluetooth;
using Windows.Devices.Bluetooth.GenericAttributeProfile;
using Windows.Devices.Enumeration;
using Windows.Devices.Radios;
using Windows.Storage.Streams;

namespace BatteryTray;

/// <summary>
/// Reads paired Bluetooth batteries on Windows.
/// Classic devices use the OS battery property. LE devices also use Battery Service 0x180F.
/// A device with neither reading is omitted.
/// </summary>
public sealed class WindowsBluetoothBatteryProvider : IBatteryProvider
{
    // Windows Bluetooth battery percentage. Accept only a literal 0–100; do not scale other ranges.
    private const string BatteryLevelProperty = "{104EA319-6EE2-4701-BD47-8DDBF425BBE5} 2";

    private const string BluetoothProtocolId = "{e0cbf06c-cd8b-4647-bb8a-263b43f0f974}";

    private const string AddressProperty = "System.Devices.Aep.DeviceAddress";

    private const string DisplayNameProperty = "System.ItemNameDisplay";

    private static readonly Guid BatteryLevelStatusUuid = BluetoothUuidHelper.FromShortId(0x2BED);

    private static readonly string AepSelector =
        $"System.Devices.Aep.ProtocolId:=\"{BluetoothProtocolId}\" AND System.Devices.Aep.IsPaired:=System.StructuredQueryType.Boolean#True";

    private static readonly string[] ExtraProperties =
    [
        AddressProperty,
        DisplayNameProperty,
        "System.Devices.Aep.IsConnected",
        BatteryLevelProperty,
    ];

    private static readonly Regex AddressInId = new(
        "([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}",
        RegexOptions.CultureInvariant | RegexOptions.Compiled);

    private static readonly TimeSpan GattTimeout = TimeSpan.FromSeconds(4);

    public string Name => "Windows Bluetooth";

    public bool IsDemo => false;

    public async Task<BatterySnapshot> ReadAsync(CancellationToken cancellationToken)
    {
        try
        {
            var radioOn = await TryGetRadioOnAsync(cancellationToken).ConfigureAwait(true);
            IReadOnlyList<DeviceInformation> devices;
            try
            {
                devices = await EnumeratePairedAsync(cancellationToken).ConfigureAwait(true);
            }
            catch (Exception exception) when (exception is not OperationCanceledException)
            {
                Trace.TraceError(exception.ToString());
                var status = radioOn == false
                    ? BatteryReadStatus.RadioUnavailable
                    : BatteryReadStatus.Failed;
                return BatterySnapshot.Empty(status);
            }

            var observedAt = DateTimeOffset.Now;
            var observations = new List<BatteryObservation>();
            foreach (var device in devices)
            {
                cancellationToken.ThrowIfCancellationRequested();
                if (string.IsNullOrWhiteSpace(device.Id))
                {
                    continue;
                }

                var name = ReadName(device);
                var address = ReadAddress(device);
                var property = ReadProperty(device, address, name, observedAt);
                if (property is not null)
                {
                    observations.Add(property);
                }

                var gatt = await TryReadGattAsync(device, address, name, observedAt, cancellationToken)
                    .ConfigureAwait(true);
                if (gatt is not null)
                {
                    observations.Add(gatt);
                }
            }

            var merged = DeviceBatteryMerger.Merge(observations);
            if (merged.Count == 0 && radioOn == false)
            {
                return new BatterySnapshot(merged, observedAt, BatteryReadStatus.RadioUnavailable);
            }

            return new BatterySnapshot(merged, observedAt, BatteryReadStatus.Ok);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception exception)
        {
            Trace.TraceError(exception.ToString());
            return BatterySnapshot.Empty(BatteryReadStatus.Failed);
        }
    }

    private static async Task<IReadOnlyList<DeviceInformation>> EnumeratePairedAsync(
        CancellationToken cancellationToken)
    {
        var map = new Dictionary<string, DeviceInformation>(StringComparer.OrdinalIgnoreCase);
        await AddAsync(BluetoothLEDevice.GetDeviceSelectorFromPairingState(true), kind: null).ConfigureAwait(true);
        await AddAsync(BluetoothDevice.GetDeviceSelectorFromPairingState(true), kind: null).ConfigureAwait(true);
        await AddAsync(AepSelector, DeviceInformationKind.AssociationEndpoint).ConfigureAwait(true);
        return map.Values.ToList();

        async Task AddAsync(string selector, DeviceInformationKind? kind)
        {
            DeviceInformationCollection collection = kind is null
                ? await DeviceInformation.FindAllAsync(selector, ExtraProperties).AsTask(cancellationToken)
                : await DeviceInformation.FindAllAsync(selector, ExtraProperties, kind.Value).AsTask(cancellationToken);

            foreach (var device in collection)
            {
                if (!string.IsNullOrWhiteSpace(device.Id) && !map.ContainsKey(device.Id))
                {
                    map.Add(device.Id, device);
                }
            }
        }
    }

    private static async Task<bool?> TryGetRadioOnAsync(CancellationToken cancellationToken)
    {
        try
        {
            var radios = await Radio.GetRadiosAsync().AsTask(cancellationToken).ConfigureAwait(true);
            var bluetooth = new List<Radio>();
            foreach (var radio in radios)
            {
                if (radio.Kind == RadioKind.Bluetooth)
                {
                    bluetooth.Add(radio);
                }
            }

            if (bluetooth.Count == 0)
            {
                return null;
            }

            foreach (var radio in bluetooth)
            {
                if (radio.State == RadioState.On)
                {
                    return true;
                }
            }

            return false;
        }
        catch (Exception exception) when (exception is not OperationCanceledException)
        {
            Trace.TraceInformation("Bluetooth radio query failed: {0}", exception.Message);
            return null;
        }
    }

    private static BatteryObservation? ReadProperty(
        DeviceInformation device,
        string? address,
        string name,
        DateTimeOffset observedAt)
    {
        if (!device.Properties.TryGetValue(BatteryLevelProperty, out var raw))
        {
            return null;
        }

        var percent = BatteryReadingParser.TryReadPercent(raw);
        if (percent is null)
        {
            return null;
        }

        return new BatteryObservation(
            device.Id,
            address,
            name,
            percent,
            BatteryChargeState.Unknown,
            FromGatt: false,
            observedAt);
    }

    private static async Task<BatteryObservation?> TryReadGattAsync(
        DeviceInformation device,
        string? address,
        string name,
        DateTimeOffset observedAt,
        CancellationToken cancellationToken)
    {
        if (!LooksLikeLowEnergy(device.Id))
        {
            return null;
        }

        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(GattTimeout);
        BluetoothLEDevice? ble = null;
        try
        {
            ble = await BluetoothLEDevice.FromIdAsync(device.Id).AsTask(timeout.Token).ConfigureAwait(true);
            if (ble is null)
            {
                return null;
            }

            var access = await ble.RequestAccessAsync().AsTask(timeout.Token).ConfigureAwait(true);
            if (access is DeviceAccessStatus.DeniedByUser or DeviceAccessStatus.DeniedBySystem)
            {
                return null;
            }

            var reading = await ReadBatteryServiceAsync(ble, timeout.Token).ConfigureAwait(true);
            if (reading is null)
            {
                return null;
            }

            return new BatteryObservation(
                device.Id,
                address,
                name,
                reading.Value.Percent,
                reading.Value.ChargeState,
                FromGatt: true,
                observedAt);
        }
        catch (Exception exception) when (exception is not OperationCanceledException
                                           || !cancellationToken.IsCancellationRequested)
        {
            Trace.TraceInformation("GATT battery read skipped for {0}: {1}", device.Id, exception.Message);
            return null;
        }
        finally
        {
            ble?.Dispose();
        }
    }

    private static async Task<(int Percent, BatteryChargeState ChargeState)?> ReadBatteryServiceAsync(
        BluetoothLEDevice ble,
        CancellationToken cancellationToken)
    {
        GattDeviceServicesResult? services = null;
        try
        {
            services = await ble
                .GetGattServicesForUuidAsync(GattServiceUuids.Battery, BluetoothCacheMode.Uncached)
                .AsTask(cancellationToken)
                .ConfigureAwait(true);

            if (services.Status != GattCommunicationStatus.Success || services.Services.Count == 0)
            {
                DisposeServices(services);
                services = await ble
                    .GetGattServicesForUuidAsync(GattServiceUuids.Battery, BluetoothCacheMode.Cached)
                    .AsTask(cancellationToken)
                    .ConfigureAwait(true);
            }

            if (services.Status != GattCommunicationStatus.Success || services.Services.Count == 0)
            {
                return null;
            }

            var percents = new List<int>();
            var charges = new List<BatteryChargeState>();
            foreach (var service in services.Services)
            {
                var levelBytes = await ReadCharacteristicAsync(
                        service,
                        GattCharacteristicUuids.BatteryLevel,
                        cancellationToken)
                    .ConfigureAwait(true);
                var statusBytes = await ReadCharacteristicAsync(
                        service,
                        BatteryLevelStatusUuid,
                        cancellationToken)
                    .ConfigureAwait(true);

                var percent = levelBytes is { Length: > 0 }
                    ? BatteryReadingParser.TryReadPercent(levelBytes[0])
                    : null;
                percent ??= statusBytes is null
                    ? null
                    : BatteryReadingParser.TryReadEmbeddedBatteryLevel(statusBytes);

                if (percent is not int value)
                {
                    continue;
                }

                percents.Add(value);
                charges.Add(statusBytes is null
                    ? BatteryChargeState.Unknown
                    : BatteryReadingParser.ParseBatteryLevelStatus(statusBytes));
            }

            if (percents.Count == 0)
            {
                return null;
            }

            return (BatterySelection.Lowest(percents), BatterySelection.Combine(charges));
        }
        finally
        {
            if (services is not null)
            {
                DisposeServices(services);
            }
        }
    }

    private static async Task<byte[]?> ReadCharacteristicAsync(
        GattDeviceService service,
        Guid uuid,
        CancellationToken cancellationToken)
    {
        GattCharacteristicsResult? result = null;
        try
        {
            result = await service
                .GetCharacteristicsForUuidAsync(uuid, BluetoothCacheMode.Uncached)
                .AsTask(cancellationToken)
                .ConfigureAwait(true);

            if (result.Status != GattCommunicationStatus.Success || result.Characteristics.Count == 0)
            {
                DisposeAll(result.Characteristics);
                result = await service
                    .GetCharacteristicsForUuidAsync(uuid, BluetoothCacheMode.Cached)
                    .AsTask(cancellationToken)
                    .ConfigureAwait(true);
            }

            if (result.Status != GattCommunicationStatus.Success || result.Characteristics.Count == 0)
            {
                return null;
            }

            var characteristic = result.Characteristics[0];
            var read = await characteristic
                .ReadValueAsync(BluetoothCacheMode.Uncached)
                .AsTask(cancellationToken)
                .ConfigureAwait(true);
            if (read.Status != GattCommunicationStatus.Success)
            {
                read = await characteristic
                    .ReadValueAsync(BluetoothCacheMode.Cached)
                    .AsTask(cancellationToken)
                    .ConfigureAwait(true);
            }

            if (read.Status != GattCommunicationStatus.Success || read.Value is null || read.Value.Length == 0)
            {
                return null;
            }

            return CopyBuffer(read.Value);
        }
        finally
        {
            if (result is not null)
            {
                DisposeAll(result.Characteristics);
            }
        }
    }

    private static byte[] CopyBuffer(IBuffer buffer)
    {
        var length = checked((int)buffer.Length);
        var bytes = new byte[length];
        using var reader = DataReader.FromBuffer(buffer);
        reader.ReadBytes(bytes);
        return bytes;
    }

    private static void DisposeServices(GattDeviceServicesResult result)
    {
        foreach (var service in result.Services)
        {
            service.Dispose();
        }
    }

    private static void DisposeAll(System.Collections.IEnumerable items)
    {
        foreach (var item in items)
        {
            (item as IDisposable)?.Dispose();
        }
    }

    private static bool LooksLikeLowEnergy(string id) =>
        id.Contains("BTHLE", StringComparison.OrdinalIgnoreCase)
        || id.Contains("BluetoothLE", StringComparison.OrdinalIgnoreCase);

    private static string ReadName(DeviceInformation device)
    {
        if (device.Properties.TryGetValue(DisplayNameProperty, out var display) && display is string text)
        {
            var trimmed = text.Trim();
            if (trimmed.Length > 0)
            {
                return trimmed;
            }
        }

        return device.Name?.Trim() ?? string.Empty;
    }

    private static string? ReadAddress(DeviceInformation device)
    {
        if (device.Properties.TryGetValue(AddressProperty, out var value) && value is string address)
        {
            var normalized = DeviceBatteryMerger.NormalizeAddress(address);
            if (normalized is not null)
            {
                return address;
            }
        }

        var match = AddressInId.Match(device.Id);
        return match.Success ? match.Value : null;
    }
}
