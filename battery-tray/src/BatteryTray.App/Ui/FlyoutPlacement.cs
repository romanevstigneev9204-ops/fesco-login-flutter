namespace BatteryTray;

internal static class FlyoutPlacement
{
    public static Point Place(Size flyout, Point cursor, Rectangle screenBounds, Rectangle workingArea)
    {
        const int gap = 10;
        var topBar = workingArea.Top > screenBounds.Top + 1 && cursor.Y < workingArea.Top;
        var leftBar = workingArea.Left > screenBounds.Left + 1 && cursor.X < workingArea.Left;
        var rightBar = workingArea.Right < screenBounds.Right - 1 && cursor.X >= workingArea.Right;

        int x;
        int y;
        if (leftBar)
        {
            x = cursor.X + gap;
            y = cursor.Y - (flyout.Height / 2);
        }
        else if (rightBar)
        {
            x = cursor.X - flyout.Width - gap;
            y = cursor.Y - (flyout.Height / 2);
        }
        else if (topBar)
        {
            x = cursor.X - (flyout.Width / 2);
            y = cursor.Y + gap;
        }
        else
        {
            x = cursor.X - (flyout.Width / 2);
            y = cursor.Y - flyout.Height - gap;
        }

        return Clamp(new Point(x, y), flyout, workingArea);
    }

    public static Point Clamp(Point origin, Size flyout, Rectangle workingArea)
    {
        var minX = workingArea.Left + 8;
        var maxX = workingArea.Right - flyout.Width - 8;
        var minY = workingArea.Top + 8;
        var maxY = workingArea.Bottom - flyout.Height - 8;

        var x = maxX < minX ? workingArea.Left : Math.Clamp(origin.X, minX, maxX);
        var y = maxY < minY ? workingArea.Top : Math.Clamp(origin.Y, minY, maxY);
        return new Point(x, y);
    }
}
