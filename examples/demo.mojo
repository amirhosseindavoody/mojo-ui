"""Render a small UI into a PNG without opening a window."""

from mojo_ui import (
    Button,
    Color,
    Framebuffer,
    Insets,
    Label,
    Point,
    Rect,
    Size,
    Stack,
)


def main() raises:
    var frame = Framebuffer(480, 248)
    frame.clear(Color.rgb(17, 23, 36))

    var panel = Rect(32, 30, 416, 188)
    frame.fill_rounded_rect(panel, 16, Color.rgb(29, 40, 59))
    var column = Stack.vertical(panel, spacing=12, padding=Insets.uniform(24))

    var title = Label("MOJO UI", Color.rgb(236, 243, 253), scale=4)
    title.draw(frame, column.place(title.size()))

    var description = Label(
        "SOFTWARE RENDERING", Color.rgb(172, 190, 214), scale=2
    )
    description.draw(frame, column.place(description.size()))

    var divider = column.place(Size(368, 1))
    frame.draw_line(
        Point(divider.x, divider.y),
        Point(divider.right() - 1, divider.y),
        Color.rgb(66, 82, 108),
    )

    var row = Stack.horizontal(column.place(Size(368, 36)), spacing=10)
    var start = Button(
        "START",
        Color.rgb(119, 224, 194),
        Color.rgb(14, 39, 36),
        scale=2,
        padding=Insets(14, 10, 14, 10),
        radius=8,
    )
    var about = Button(
        "ABOUT",
        Color.rgb(52, 69, 94),
        scale=2,
        padding=Insets(14, 10, 14, 10),
        radius=8,
    )
    start.draw(frame, row.place(start.size()))
    about.draw(frame, row.place(about.size()))

    var path = "examples/out/demo.png"
    frame.write_png(path)
    print("Wrote", path)
