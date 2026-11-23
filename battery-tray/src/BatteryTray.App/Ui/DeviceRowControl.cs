using System.Drawing.Drawing2D;

namespace BatteryTray;

internal sealed class DeviceRowControl : Control
{
    private readonly Label _name = new()
    {
        AutoEllipsis = true,
        UseMnemonic = false,
        AutoSize = false,
    };

    private readonly Label _percent = new()
    {
        AutoSize = false,
        UseMnemonic = false,
        TextAlign = ContentAlignment.MiddleRight,
    };

    private readonly Label _state = new()
    {
        AutoEllipsis = true,
        UseMnemonic = false,
        AutoSize = false,
    };

    private ThemePalette _theme;
    private bool _drawSeparator = true;
    private Font? _nameFont;
    private Font? _percentFont;
    private Font? _stateFont;

    public DeviceRowControl(DeviceBattery device, ThemePalette theme)
    {
        Device = device;
        _theme = theme;
        SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        Controls.Add(_name);
        Controls.Add(_percent);
        Controls.Add(_state);
        _name.MouseDown += ForwardMouseDown;
        _percent.MouseDown += ForwardMouseDown;
        _state.MouseDown += ForwardMouseDown;
        AccessibleRole = AccessibleRole.ListItem;
        ApplyTheme(theme);
        SetText();
    }

    public DeviceBattery Device { get; }

    public bool DrawSeparator
    {
        get => _drawSeparator;
        set
        {
            _drawSeparator = value;
            Invalidate();
        }
    }

    public void ApplyTheme(ThemePalette theme)
    {
        _theme = theme;
        BackColor = theme.Window;
        _name.ForeColor = theme.Text;
        _name.BackColor = theme.Window;
        _percent.ForeColor = Device.Percent < 20 ? theme.FillLow : theme.Text;
        _percent.BackColor = theme.Window;
        _state.ForeColor = theme.Secondary;
        _state.BackColor = theme.Window;

        _nameFont?.Dispose();
        _percentFont?.Dispose();
        _stateFont?.Dispose();
        _nameFont = new Font("Segoe UI", 10f, FontStyle.Regular, GraphicsUnit.Point);
        _percentFont = new Font("Segoe UI Semibold", 14f, FontStyle.Regular, GraphicsUnit.Point);
        _stateFont = new Font("Segoe UI", 8.5f, FontStyle.Regular, GraphicsUnit.Point);
        _name.Font = _nameFont;
        _percent.Font = _percentFont;
        _state.Font = _stateFont;
        Invalidate();
    }

    protected override void OnResize(EventArgs e)
    {
        base.OnResize(e);
        LayoutChildren();
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        e.Graphics.Clear(_theme.Window);
        e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
        var track = TrackRectangle();
        using (var trackBrush = new SolidBrush(_theme.Track))
        {
            FillCapsule(e.Graphics, track, trackBrush);
        }

        if (Device.Percent > 0 && track.Width > 0)
        {
            var width = Math.Max(track.Height, track.Width * Device.Percent / 100f);
            width = Math.Min(width, track.Width);
            var filled = new RectangleF(track.X, track.Y, width, track.Height);
            using var fillBrush = new SolidBrush(Device.Percent < 20 ? _theme.FillLow : _theme.Fill);
            FillCapsule(e.Graphics, filled, fillBrush);
        }

        if (_drawSeparator)
        {
            e.Graphics.SmoothingMode = SmoothingMode.None;
            var pad = Pad();
            using var pen = new Pen(_theme.Divider);
            e.Graphics.DrawLine(pen, pad, Height - 1, Width - pad, Height - 1);
        }
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _nameFont?.Dispose();
            _percentFont?.Dispose();
            _stateFont?.Dispose();
        }

        base.Dispose(disposing);
    }

    private void ForwardMouseDown(object? sender, MouseEventArgs e) => OnMouseDown(e);

    private void SetText()
    {
        var name = string.IsNullOrWhiteSpace(Device.Name) ? "Неизвестное устройство" : Device.Name;
        var state = ChargeStateText.Format(Device.ChargeState);
        _name.Text = name;
        _percent.Text = Device.Percent + "%";
        _state.Text = state;
        AccessibleName = $"{name}, {Device.Percent} процентов, {state}";
    }

    private void LayoutChildren()
    {
        var pad = Pad();
        var percentWidth = Math.Max(Px(52), TextRenderer.MeasureText(_percent.Text, _percent.Font).Width);
        var percentHeight = Px(24);
        _percent.SetBounds(Width - pad - percentWidth, Px(10), percentWidth, percentHeight);
        _name.SetBounds(pad, Px(14), Math.Max(Px(20), _percent.Left - pad - Px(8)), Px(20));
        _state.SetBounds(pad, Px(50), Math.Max(Px(20), Width - (pad * 2)), Px(18));
    }

    private RectangleF TrackRectangle()
    {
        var pad = Pad();
        return new RectangleF(pad, Px(40), Math.Max(0, Width - (pad * 2)), Math.Max(2, Px(4)));
    }

    private int Pad() => Px(16);

    private int Px(int dip) => Math.Max(1, (int)Math.Round(dip * DeviceDpi / 96.0));

    private static void FillCapsule(Graphics graphics, RectangleF rect, Brush brush)
    {
        if (rect.Width <= 0.5f || rect.Height <= 0.5f)
        {
            return;
        }

        using var path = new GraphicsPath();
        var diameter = Math.Min(rect.Height, rect.Width);
        if (rect.Width <= rect.Height + 0.5f)
        {
            path.AddEllipse(rect.X, rect.Y, diameter, rect.Height);
            graphics.FillPath(brush, path);
            return;
        }

        path.AddArc(rect.X, rect.Y, diameter, rect.Height, 90, 180);
        path.AddArc(rect.Right - diameter, rect.Y, diameter, rect.Height, 270, 180);
        path.CloseFigure();
        graphics.FillPath(brush, path);
    }
}
