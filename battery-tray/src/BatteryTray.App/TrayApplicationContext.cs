using System.Globalization;
using Microsoft.Win32;

namespace BatteryTray;

internal sealed class TrayApplicationContext : ApplicationContext
{
    private readonly IBatteryProvider _provider;
    private readonly NotifyIcon _notifyIcon;
    private readonly ContextMenuStrip _menu;
    private readonly FlyoutForm _flyout;
    private readonly System.Windows.Forms.Timer _refreshTimer;
    private readonly System.Windows.Forms.Timer _hoverTimer;
    private readonly System.Windows.Forms.Timer _dismissTimer;
    private readonly CancellationTokenSource _lifetime = new();

    private TrayIconHandle? _iconHandle;
    private BatterySnapshot? _snapshot;
    private int _refreshing;
    private int _closed;
    private DateTime _lastIconActivityUtc = DateTime.MinValue;
    private DateTime _suppressOpenUntilUtc = DateTime.MinValue;

    public TrayApplicationContext(IBatteryProvider provider, TrayConfig config)
    {
        if (SynchronizationContext.Current is null)
        {
            SynchronizationContext.SetSynchronizationContext(new WindowsFormsSynchronizationContext());
        }

        _provider = provider;
        _flyout = new FlyoutForm();
        _flyout.RefreshRequested += (_, _) => _ = RefreshAsync();

        _menu = new ContextMenuStrip
        {
            Font = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point),
        };
        _menu.Items.Add("Обновить", null, (_, _) => _ = RefreshAsync());
        _menu.Items.Add(new ToolStripSeparator());
        _menu.Items.Add("Выход", null, (_, _) => ExitThread());

        _notifyIcon = new NotifyIcon
        {
            Visible = true,
            Text = "Батарея Bluetooth",
            ContextMenuStrip = _menu,
        };
        _notifyIcon.MouseMove += OnIconMouseMove;
        _notifyIcon.MouseClick += OnIconMouseClick;

        _hoverTimer = new System.Windows.Forms.Timer { Interval = 160 };
        _hoverTimer.Tick += (_, _) =>
        {
            _hoverTimer.Stop();
            if (!_flyout.Visible && DateTime.UtcNow - _lastIconActivityUtc < TimeSpan.FromMilliseconds(400))
            {
                ShowFlyout(pinned: false);
            }
        };

        _dismissTimer = new System.Windows.Forms.Timer { Interval = 80 };
        _dismissTimer.Tick += (_, _) => DismissIfPointerLeft();
        _flyout.Deactivate += (_, _) =>
        {
            if (!_flyout.Visible || !_flyout.Pinned)
            {
                return;
            }

            _flyout.Hide();
            _dismissTimer.Stop();
            _suppressOpenUntilUtc = DateTime.UtcNow.AddMilliseconds(300);
        };

        _refreshTimer = new System.Windows.Forms.Timer
        {
            Interval = config.NormalizedRefreshSeconds * 1000,
        };
        _refreshTimer.Tick += (_, _) => _ = RefreshAsync();

        SystemEvents.UserPreferenceChanged += OnUserPreferenceChanged;
        ApplyTheme();
        _flyout.ApplySnapshot(null, provider.IsDemo, refreshing: true);
        _refreshTimer.Start();
        _ = RefreshAsync();
    }

    protected override void ExitThreadCore()
    {
        Interlocked.Exchange(ref _closed, 1);
        _lifetime.Cancel();
        _refreshTimer.Stop();
        _hoverTimer.Stop();
        _dismissTimer.Stop();
        SystemEvents.UserPreferenceChanged -= OnUserPreferenceChanged;
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        _iconHandle?.Dispose();
        _menu.Dispose();
        _flyout.Dispose();
        _refreshTimer.Dispose();
        _hoverTimer.Dispose();
        _dismissTimer.Dispose();
        _lifetime.Dispose();
        base.ExitThreadCore();
    }

    private void OnIconMouseMove(object? sender, MouseEventArgs e)
    {
        if ((Control.MouseButtons & MouseButtons.Right) == MouseButtons.Right)
        {
            return;
        }

        _lastIconActivityUtc = DateTime.UtcNow;
        if (_flyout.Visible)
        {
            return;
        }

        _hoverTimer.Stop();
        _hoverTimer.Start();
    }

    private void OnIconMouseClick(object? sender, MouseEventArgs e)
    {
        if (e.Button != MouseButtons.Left)
        {
            return;
        }

        _hoverTimer.Stop();
        if (DateTime.UtcNow < _suppressOpenUntilUtc)
        {
            return;
        }

        if (_flyout.Visible && _flyout.Pinned)
        {
            _flyout.Hide();
            _dismissTimer.Stop();
            return;
        }

        if (_flyout.Visible)
        {
            _flyout.Pin();
            return;
        }

        ShowFlyout(pinned: true);
    }

    private void ShowFlyout(bool pinned)
    {
        _flyout.ApplySnapshot(_snapshot, _provider.IsDemo, refreshing: _refreshing == 1);
        _flyout.Present(pinned);
        _dismissTimer.Enabled = !pinned;
        _ = RefreshAsync();
    }

    private void DismissIfPointerLeft()
    {
        if (!_flyout.Visible || _flyout.Pinned)
        {
            _dismissTimer.Stop();
            return;
        }

        var bounds = _flyout.Bounds;
        bounds.Inflate(16, 28);
        if (bounds.Contains(Cursor.Position))
        {
            return;
        }

        if (DateTime.UtcNow - _lastIconActivityUtc < TimeSpan.FromMilliseconds(450))
        {
            return;
        }

        _flyout.Hide();
        _dismissTimer.Stop();
    }

    private async Task RefreshAsync()
    {
        if (Interlocked.Exchange(ref _refreshing, 1) == 1)
        {
            return;
        }

        try
        {
            if (_flyout.Visible)
            {
                _flyout.ApplySnapshot(_snapshot, _provider.IsDemo, refreshing: true);
            }

            var snapshot = await _provider.ReadAsync(_lifetime.Token).ConfigureAwait(true);
            if (Volatile.Read(ref _closed) == 1)
            {
                return;
            }

            _snapshot = snapshot;
            UpdateIcon(snapshot);
            if (_flyout.Visible)
            {
                _flyout.ApplySnapshot(snapshot, _provider.IsDemo, refreshing: false);
            }
        }
        catch (OperationCanceledException)
        {
            // The tray is closing.
        }
        catch (Exception exception)
        {
            System.Diagnostics.Trace.TraceError(exception.ToString());
            _snapshot = BatterySnapshot.Empty(BatteryReadStatus.Failed);
            UpdateIcon(_snapshot);
            if (_flyout.Visible)
            {
                _flyout.ApplySnapshot(_snapshot, _provider.IsDemo, refreshing: false);
            }
        }
        finally
        {
            Interlocked.Exchange(ref _refreshing, 0);
        }
    }

    private void UpdateIcon(BatterySnapshot snapshot)
    {
        int? lowest = snapshot.Devices.Count == 0
            ? null
            : snapshot.Devices.Min(static device => device.Percent);
        ReplaceIcon(lowest);
        SetTooltip(snapshot);
    }

    private void ReplaceIcon(int? lowestPercent)
    {
        try
        {
            var forDarkBackground = !ThemePalette.TaskbarUsesLightTheme() && !SystemInformation.HighContrast;
            var next = TrayIconFactory.Create(lowestPercent, forDarkBackground);
            var previous = _iconHandle;
            _iconHandle = next;
            _notifyIcon.Icon = next.Icon;
            previous?.Dispose();
        }
        catch (Exception exception)
        {
            System.Diagnostics.Trace.TraceError(exception.ToString());
        }
    }

    private void SetTooltip(BatterySnapshot snapshot)
    {
        var text = FormatTooltip(snapshot, _provider.IsDemo);
        try
        {
            _notifyIcon.Text = text;
        }
        catch (ArgumentException)
        {
            _notifyIcon.Text = text.Length <= 63 ? text : text[..60] + "...";
        }
    }

    private void ApplyTheme()
    {
        var theme = ThemePalette.ForCurrentSystem();
        _flyout.ApplyTheme(theme);
        _menu.BackColor = theme.Window;
        _menu.ForeColor = theme.Text;
        ReplaceIcon(_snapshot is { Devices.Count: > 0 }
            ? _snapshot.Devices.Min(static device => device.Percent)
            : null);
        if (_snapshot is not null)
        {
            SetTooltip(_snapshot);
        }
    }

    private void OnUserPreferenceChanged(object sender, UserPreferenceChangedEventArgs e)
    {
        if (e.Category is not (UserPreferenceCategory.General or UserPreferenceCategory.Color or UserPreferenceCategory.VisualStyle))
        {
            return;
        }

        if (_flyout.IsHandleCreated && _flyout.InvokeRequired)
        {
            _flyout.BeginInvoke(ApplyTheme);
            return;
        }

        ApplyTheme();
    }

    private static string FormatTooltip(BatterySnapshot snapshot, bool isDemo)
    {
        if (snapshot.Status == BatteryReadStatus.RadioUnavailable && snapshot.Devices.Count == 0)
        {
            return "Bluetooth выключен";
        }

        if (snapshot.Devices.Count == 0)
        {
            return "Нет данных о заряде";
        }

        var lines = snapshot.Devices
            .Select(static device =>
            {
                var name = string.IsNullOrWhiteSpace(device.Name) ? "Неизвестное устройство" : device.Name;
                return string.Format(CultureInfo.CurrentCulture, "{0} — {1}%", name, device.Percent);
            });
        var text = string.Join("\n", lines);
        if (isDemo)
        {
            text = "Демо. " + text;
        }

        return text.Length <= 127 ? text : text[..124] + "...";
    }
}
