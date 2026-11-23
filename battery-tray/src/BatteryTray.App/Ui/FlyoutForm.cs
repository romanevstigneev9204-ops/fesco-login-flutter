using System.Globalization;
using System.Runtime.InteropServices;

namespace BatteryTray;

internal sealed class FlyoutForm : Form
{
    private const int CornerPreference = 33;
    private const int RoundCorners = 2;
    private const int BorderColorAttribute = 34;
    private const int ToolWindow = 0x00000080;
    private const int DropShadow = 0x00020000;

    private readonly Label _title = new() { AutoSize = false, UseMnemonic = false };
    private readonly Label _demo = new() { AutoSize = false, UseMnemonic = false, Text = "Демо-данные" };
    private readonly Button _refresh = new() { Text = "Обновить", UseMnemonic = false };
    private readonly Panel _body = new() { AutoScroll = false };
    private readonly Label _messageTitle = new() { AutoSize = false, UseMnemonic = false };
    private readonly Label _messageBody = new() { AutoSize = false, UseMnemonic = false };
    private readonly Label _footer = new() { AutoSize = false, UseMnemonic = false };

    private readonly List<DeviceRowControl> _rows = [];
    private ThemePalette _theme = ThemePalette.LightTheme();
    private Font? _titleFont;
    private Font? _demoFont;
    private Font? _bodyFont;
    private Font? _footerFont;
    private Font? _buttonFont;
    private bool _roundWithRegion;
    private bool _showDemo;
    private bool _refreshing;
    private BatterySnapshot? _rendered;

    public FlyoutForm()
    {
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        TopMost = true;
        KeyPreview = true;
        AutoScaleMode = AutoScaleMode.None;
        Font = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point);
        AccessibleName = "Заряд Bluetooth-устройств";
        AccessibleRole = AccessibleRole.Window;

        _refresh.FlatStyle = FlatStyle.Flat;
        _refresh.FlatAppearance.BorderSize = 0;
        _refresh.Cursor = Cursors.Hand;
        _refresh.TabStop = true;
        _refresh.Click += (_, _) => RefreshRequested?.Invoke(this, EventArgs.Empty);

        Controls.Add(_title);
        Controls.Add(_demo);
        Controls.Add(_refresh);
        Controls.Add(_body);
        _body.Controls.Add(_messageTitle);
        _body.Controls.Add(_messageBody);
        Controls.Add(_footer);

        _body.AccessibleRole = AccessibleRole.List;
        ApplyTheme(ThemePalette.ForCurrentSystem());
    }

    public event EventHandler? RefreshRequested;

    public bool Pinned { get; private set; }

    protected override bool ShowWithoutActivation => !Pinned;

    protected override CreateParams CreateParams
    {
        get
        {
            var parameters = base.CreateParams;
            parameters.ClassStyle |= DropShadow;
            parameters.ExStyle |= ToolWindow;
            return parameters;
        }
    }

    public void ApplyTheme(ThemePalette theme)
    {
        _theme = theme;
        BackColor = theme.Window;
        _body.BackColor = theme.Window;
        ForeColor = theme.Text;

        ReplaceFonts();
        _title.Font = _titleFont;
        _title.ForeColor = theme.Text;
        _title.BackColor = theme.Window;
        _demo.Font = _demoFont;
        _demo.ForeColor = theme.Demo;
        _demo.BackColor = theme.Window;
        _messageTitle.Font = _titleFont;
        _messageTitle.ForeColor = theme.Text;
        _messageTitle.BackColor = theme.Window;
        _messageBody.Font = _bodyFont;
        _messageBody.ForeColor = theme.Secondary;
        _messageBody.BackColor = theme.Window;
        _footer.Font = _footerFont;
        _footer.ForeColor = theme.Secondary;
        _footer.BackColor = theme.Window;
        _refresh.Font = _buttonFont;
        _refresh.ForeColor = theme.ButtonText;
        _refresh.BackColor = theme.Window;
        _refresh.FlatAppearance.MouseOverBackColor = theme.ButtonHover;
        _refresh.FlatAppearance.MouseDownBackColor = theme.ButtonHover;

        foreach (var row in _rows)
        {
            row.ApplyTheme(theme);
        }

        if (IsHandleCreated)
        {
            ApplyWindowChrome();
            Relayout();
        }
    }

    public void ApplySnapshot(BatterySnapshot? snapshot, bool isDemo, bool refreshing)
    {
        _showDemo = isDemo;
        _refreshing = refreshing;
        if (!SameContent(_rendered, snapshot))
        {
            RebuildRows(snapshot);
            _rendered = snapshot;
        }

        SetMessage(snapshot, refreshing);
        _footer.Text = FormatFooter(snapshot, refreshing);
        if (IsHandleCreated)
        {
            var origin = Location;
            Relayout();
            if (Visible)
            {
                var screen = Screen.FromPoint(Cursor.Position);
                Location = FlyoutPlacement.Clamp(origin, Size, screen.WorkingArea);
            }
        }
    }

    public void Present(bool pinned)
    {
        Pinned = pinned;
        if (!IsHandleCreated)
        {
            CreateHandle();
        }

        Relayout();
        var cursor = Cursor.Position;
        var screen = Screen.FromPoint(cursor);
        Location = FlyoutPlacement.Place(Size, cursor, screen.Bounds, screen.WorkingArea);
        if (!Visible)
        {
            Show();
        }

        if (pinned)
        {
            Activate();
            _refresh.Focus();
        }
    }

    public void Pin()
    {
        if (Pinned)
        {
            return;
        }

        Pinned = true;
        Activate();
        _refresh.Focus();
    }

    protected override void OnHandleCreated(EventArgs e)
    {
        base.OnHandleCreated(e);
        ApplyWindowChrome();
        Relayout();
    }

    protected override void OnDpiChanged(DpiChangedEventArgs e)
    {
        base.OnDpiChanged(e);
        Relayout();
    }

    protected override void OnShown(EventArgs e)
    {
        base.OnShown(e);
        ApplyWindowChrome();
    }

    protected override void OnKeyDown(KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Escape)
        {
            Hide();
            e.Handled = true;
            return;
        }

        if (e.KeyCode == Keys.F5)
        {
            RefreshRequested?.Invoke(this, EventArgs.Empty);
            e.Handled = true;
            return;
        }

        base.OnKeyDown(e);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        if (_roundWithRegion)
        {
            using var pen = new Pen(_theme.Border);
            e.Graphics.DrawRectangle(pen, 0, 0, Width - 1, Height - 1);
        }
    }

    protected override void OnMouseDown(MouseEventArgs e)
    {
        base.OnMouseDown(e);
        if (!Pinned && e.Button == MouseButtons.Left)
        {
            Pin();
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _titleFont?.Dispose();
            _demoFont?.Dispose();
            _bodyFont?.Dispose();
            _footerFont?.Dispose();
            _buttonFont?.Dispose();
        }

        base.Dispose(disposing);
    }

    private void RebuildRows(BatterySnapshot? snapshot)
    {
        foreach (var row in _rows)
        {
            _body.Controls.Remove(row);
            row.Dispose();
        }

        _rows.Clear();
        if (snapshot is null || snapshot.Devices.Count == 0 || snapshot.Status != BatteryReadStatus.Ok)
        {
            return;
        }

        foreach (var device in snapshot.Devices)
        {
            var row = new DeviceRowControl(device, _theme);
            row.MouseDown += (_, _) =>
            {
                if (!Pinned)
                {
                    Pin();
                }
            };
            _rows.Add(row);
            _body.Controls.Add(row);
        }

        for (var index = 0; index < _rows.Count; index++)
        {
            _rows[index].DrawSeparator = index < _rows.Count - 1;
        }
    }

    private void SetMessage(BatterySnapshot? snapshot, bool refreshing)
    {
        if (snapshot is { Status: BatteryReadStatus.Ok, Devices.Count: > 0 })
        {
            _messageTitle.Text = string.Empty;
            _messageBody.Text = string.Empty;
            _messageTitle.Visible = false;
            _messageBody.Visible = false;
            return;
        }

        _messageTitle.Visible = true;
        _messageBody.Visible = true;
        if (snapshot is null && refreshing)
        {
            _messageTitle.Text = "Обновление…";
            _messageBody.Text = "Проверяем сопряжённые Bluetooth-устройства.";
            return;
        }

        switch (snapshot?.Status)
        {
            case BatteryReadStatus.RadioUnavailable:
                _messageTitle.Text = "Bluetooth выключен";
                _messageBody.Text = "Включите Bluetooth, чтобы проверить заряд сопряжённых устройств.";
                break;
            case BatteryReadStatus.Failed:
                _messageTitle.Text = "Не удалось получить данные";
                _messageBody.Text = "Windows не ответил на запрос Bluetooth. Нажмите «Обновить» и попробуйте ещё раз.";
                break;
            default:
                _messageTitle.Text = "Нет данных о заряде";
                _messageBody.Text = "Среди сопряжённых Bluetooth-устройств нет тех, которые сообщают уровень батареи.";
                break;
        }
    }

    private void Relayout()
    {
        var width = Px(336);
        var pad = Px(16);
        var headerHeight = _showDemo ? Px(62) : Px(48);
        var footerHeight = Px(36);
        var rowHeight = Px(74);

        _title.Text = "Батарея Bluetooth";
        var buttonSize = TextRenderer.MeasureText(_refresh.Text, _refresh.Font);
        var buttonWidth = buttonSize.Width + Px(12);
        var buttonHeight = Px(28);
        _refresh.SetBounds(width - pad - buttonWidth, Px(10), buttonWidth, buttonHeight);
        _title.SetBounds(pad, Px(14), Math.Max(Px(40), _refresh.Left - pad - Px(8)), Px(22));
        _demo.Visible = _showDemo;
        _demo.SetBounds(pad, Px(36), Math.Max(Px(40), width - (pad * 2)), Px(18));

        var contentHeight = _rows.Count > 0 ? _rows.Count * rowHeight : Px(132);
        var maxBody = Px(360);
        var bodyHeight = Math.Min(contentHeight, maxBody);
        var scroll = contentHeight > maxBody ? SystemInformation.VerticalScrollBarWidth : 0;
        _body.AutoScroll = contentHeight > maxBody;
        _body.SetBounds(0, headerHeight, width, bodyHeight);

        var rowWidth = Math.Max(Px(80), width - scroll);
        for (var index = 0; index < _rows.Count; index++)
        {
            _rows[index].SetBounds(0, index * rowHeight, rowWidth, rowHeight);
        }

        var showMessage = _rows.Count == 0;
        _messageTitle.Visible = showMessage;
        _messageBody.Visible = showMessage;
        if (showMessage)
        {
            _messageTitle.SetBounds(pad, Px(28), width - (pad * 2), Px(24));
            _messageBody.SetBounds(pad, Px(56), width - (pad * 2), Px(64));
        }

        _footer.SetBounds(pad, headerHeight + bodyHeight + Px(8), width - (pad * 2), Px(18));
        ClientSize = new Size(width, headerHeight + bodyHeight + footerHeight);
        if (_roundWithRegion)
        {
            Region = CreateRoundRegion(Width, Height, Px(10));
        }

        Invalidate();
    }

    private static bool SameContent(BatterySnapshot? left, BatterySnapshot? right)
    {
        if (left is null || right is null)
        {
            return left is null && right is null;
        }

        if (left.Status != right.Status || left.Devices.Count != right.Devices.Count)
        {
            return false;
        }

        for (var index = 0; index < left.Devices.Count; index++)
        {
            var before = left.Devices[index];
            var after = right.Devices[index];
            if (before.Id != after.Id
                || before.Name != after.Name
                || before.Percent != after.Percent
                || before.ChargeState != after.ChargeState)
            {
                return false;
            }
        }

        return true;
    }

    private static string FormatFooter(BatterySnapshot? snapshot, bool refreshing)
    {
        if (refreshing)
        {
            return "Обновление…";
        }

        if (snapshot is null)
        {
            return string.Empty;
        }

        var local = snapshot.RetrievedAt.LocalDateTime;
        if (DateTime.Now - local < TimeSpan.FromSeconds(15))
        {
            return "Обновлено только что";
        }

        return "Обновлено в " + local.ToString("HH:mm", CultureInfo.CurrentCulture);
    }

    private void ReplaceFonts()
    {
        _titleFont?.Dispose();
        _demoFont?.Dispose();
        _bodyFont?.Dispose();
        _footerFont?.Dispose();
        _buttonFont?.Dispose();
        _titleFont = new Font("Segoe UI", 11f, FontStyle.Regular, GraphicsUnit.Point);
        _demoFont = new Font("Segoe UI", 8.5f, FontStyle.Regular, GraphicsUnit.Point);
        _bodyFont = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point);
        _footerFont = new Font("Segoe UI", 8.25f, FontStyle.Regular, GraphicsUnit.Point);
        _buttonFont = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point);
    }

    private void ApplyWindowChrome()
    {
        var preference = RoundCorners;
        var rounded = DwmSetWindowAttribute(Handle, CornerPreference, ref preference, sizeof(int));
        _roundWithRegion = rounded != 0;
        var border = ColorTranslator.ToWin32(_theme.Border);
        DwmSetWindowAttribute(Handle, BorderColorAttribute, ref border, sizeof(int));
    }

    private int Px(int dip)
    {
        var dpi = IsHandleCreated ? DeviceDpi : 96;
        return Math.Max(1, (int)Math.Round(dip * dpi / 96.0));
    }

    private static Region CreateRoundRegion(int width, int height, int radius)
    {
        using var path = new System.Drawing.Drawing2D.GraphicsPath();
        var diameter = radius * 2;
        path.AddArc(0, 0, diameter, diameter, 180, 90);
        path.AddArc(width - diameter, 0, diameter, diameter, 270, 90);
        path.AddArc(width - diameter, height - diameter, diameter, diameter, 0, 90);
        path.AddArc(0, height - diameter, diameter, diameter, 90, 90);
        path.CloseFigure();
        return new Region(path);
    }

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attribute, ref int value, int size);
}
