using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

namespace BatteryTray;

internal static class TrayIconFactory
{
    private static readonly int[] Sizes = [16, 20, 24, 32, 40, 48];

    public static TrayIconHandle Create(int? lowestPercent, bool forDarkBackground)
    {
        var frames = new List<IconFrame>(Sizes.Length);
        foreach (var size in Sizes)
        {
            using var bitmap = Render(size, lowestPercent, forDarkBackground);
            frames.Add(ReadFrame(bitmap));
        }

        var iconStream = new MemoryStream(BuildIco(frames));
        iconStream.Position = 0;
        return new TrayIconHandle(iconStream, new Icon(iconStream));
    }

    private static Bitmap Render(int size, int? percent, bool forDarkBackground)
    {
        var bitmap = new Bitmap(size, size, PixelFormat.Format32bppArgb);
        using var graphics = Graphics.FromImage(bitmap);
        graphics.SmoothingMode = SmoothingMode.AntiAlias;
        graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
        graphics.Clear(Color.Transparent);

        var glyph = forDarkBackground
            ? Color.FromArgb(245, 245, 245)
            : Color.FromArgb(28, 28, 28);
        if (percent is null)
        {
            glyph = Color.FromArgb(170, glyph);
        }

        var low = Color.FromArgb(214, 96, 86);
        var scale = size / 32f;
        var body = new RectangleF(1.5f * scale, 9f * scale, 24f * scale, 14f * scale);
        var nub = new RectangleF(body.Right + (1.2f * scale), 13f * scale, 3.2f * scale, 6f * scale);
        var stroke = Math.Max(1f, 1.6f * scale);

        using var pen = new Pen(glyph, stroke) { LineJoin = LineJoin.Round, StartCap = LineCap.Round, EndCap = LineCap.Round };
        using var outline = RoundedRect(body, 2.4f * scale);
        graphics.DrawPath(pen, outline);
        using var nubBrush = new SolidBrush(glyph);
        graphics.FillRectangle(nubBrush, nub);

        if (percent is int level)
        {
            var inset = stroke + (1.1f * scale);
            var inner = new RectangleF(
                body.X + inset,
                body.Y + inset,
                Math.Max(0, body.Width - (inset * 2)),
                Math.Max(0, body.Height - (inset * 2)));
            var fraction = level <= 0 ? 0.08f : Math.Clamp(level, 0, 100) / 100f;
            var filled = new RectangleF(inner.X, inner.Y, Math.Max(1f, inner.Width * fraction), inner.Height);
            using var fillBrush = new SolidBrush(level < 20 ? low : glyph);
            using var fill = RoundedRect(filled, Math.Max(0.8f, 1.2f * scale));
            graphics.FillPath(fillBrush, fill);
        }

        return bitmap;
    }

    private static GraphicsPath RoundedRect(RectangleF rect, float radius)
    {
        var path = new GraphicsPath();
        var diameter = Math.Min(radius * 2, Math.Min(rect.Width, rect.Height));
        if (diameter <= 0.1f)
        {
            path.AddRectangle(rect);
            return path;
        }

        path.AddArc(rect.X, rect.Y, diameter, diameter, 180, 90);
        path.AddArc(rect.Right - diameter, rect.Y, diameter, diameter, 270, 90);
        path.AddArc(rect.Right - diameter, rect.Bottom - diameter, diameter, diameter, 0, 90);
        path.AddArc(rect.X, rect.Bottom - diameter, diameter, diameter, 90, 90);
        path.CloseFigure();
        return path;
    }

    private static IconFrame ReadFrame(Bitmap bitmap)
    {
        var width = bitmap.Width;
        var height = bitmap.Height;
        var bounds = new Rectangle(0, 0, width, height);
        var data = bitmap.LockBits(bounds, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
        try
        {
            if (data.Stride < width * 4)
            {
                throw new InvalidOperationException("Tray bitmap stride is too small.");
            }

            var source = new byte[data.Stride * height];
            Marshal.Copy(data.Scan0, source, 0, source.Length);
            var pixels = new byte[width * height * 4];
            for (var y = 0; y < height; y++)
            {
                Buffer.BlockCopy(source, y * data.Stride, pixels, y * width * 4, width * 4);
            }

            return new IconFrame(width, height, pixels);
        }
        finally
        {
            bitmap.UnlockBits(data);
        }
    }

    private static byte[] BuildIco(IReadOnlyList<IconFrame> frames)
    {
        using var output = new MemoryStream();
        using var writer = new BinaryWriter(output);
        writer.Write((ushort)0);
        writer.Write((ushort)1);
        writer.Write((ushort)frames.Count);

        var offset = 6 + (16 * frames.Count);
        foreach (var frame in frames)
        {
            var imageSize = ImageBytes(frame);
            writer.Write((byte)(frame.Width >= 256 ? 0 : frame.Width));
            writer.Write((byte)(frame.Height >= 256 ? 0 : frame.Height));
            writer.Write((byte)0);
            writer.Write((byte)0);
            writer.Write((ushort)1);
            writer.Write((ushort)32);
            writer.Write(imageSize);
            writer.Write(offset);
            offset += imageSize;
        }

        foreach (var frame in frames)
        {
            WriteImage(writer, frame);
        }

        writer.Flush();
        return output.ToArray();
    }

    private static int ImageBytes(IconFrame frame)
    {
        var xor = frame.Width * frame.Height * 4;
        var maskStride = ((frame.Width + 31) / 32) * 4;
        return 40 + xor + (maskStride * frame.Height);
    }

    private static void WriteImage(BinaryWriter writer, IconFrame frame)
    {
        writer.Write(40);
        writer.Write(frame.Width);
        writer.Write(frame.Height * 2);
        writer.Write((ushort)1);
        writer.Write((ushort)32);
        writer.Write(0);
        writer.Write(frame.Width * frame.Height * 4);
        writer.Write(0);
        writer.Write(0);
        writer.Write(0);
        writer.Write(0);

        for (var y = frame.Height - 1; y >= 0; y--)
        {
            writer.Write(frame.TopDownBgra, y * frame.Width * 4, frame.Width * 4);
        }

        var maskStride = ((frame.Width + 31) / 32) * 4;
        var mask = new byte[maskStride];
        for (var y = frame.Height - 1; y >= 0; y--)
        {
            Array.Clear(mask);
            for (var x = 0; x < frame.Width; x++)
            {
                var alpha = frame.TopDownBgra[(y * frame.Width * 4) + (x * 4) + 3];
                if (alpha < 16)
                {
                    mask[x / 8] |= (byte)(0x80 >> (x % 8));
                }
            }

            writer.Write(mask);
        }
    }

    private readonly record struct IconFrame(int Width, int Height, byte[] TopDownBgra);
}

internal sealed class TrayIconHandle : IDisposable
{
    private readonly MemoryStream _stream;

    public TrayIconHandle(MemoryStream stream, Icon icon)
    {
        _stream = stream;
        Icon = icon;
    }

    public Icon Icon { get; }

    public void Dispose()
    {
        Icon.Dispose();
        _stream.Dispose();
    }
}
