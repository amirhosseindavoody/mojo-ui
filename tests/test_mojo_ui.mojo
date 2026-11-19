"""Headless geometry, raster, export, and widget checks."""

from std.tempfile import TemporaryDirectory
from std.testing import assert_equal, assert_true

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
    text_width,
)


def test_geometry() raises:
    var box = Rect(2, 3, 6, 4)
    assert_true(box.contains(Point(2, 3)))
    assert_true(box.contains(Point(7, 6)))
    assert_true(not box.contains(Point(8, 4)))
    assert_true(not box.contains(Point(5, 7)))
    assert_true(box.intersection(Rect(-1, 4, 5, 6)) == Rect(2, 4, 2, 3))
    assert_true(box.intersection(Rect(8, 3, 2, 4)).is_empty())
    assert_true(box.inset(Insets(1, 2, 3, 0)) == Rect(3, 5, 2, 2))
    assert_true(box.inset(Insets.uniform(20)) == Rect(8, 7, 0, 0))
    assert_true(Size(-2, 4) == Size(0, 4))
    assert_equal(Rect(Int.MAX - 2, 0, 10, 1).right(), Int.MAX)


def test_color() raises:
    var half_red = Color(255, 0, 0, 128)
    assert_true(Color.TRANSPARENT.over(half_red) == half_red)
    assert_true(half_red.over(Color.TRANSPARENT) == half_red)
    assert_true(Color.BLUE.over(half_red) == Color.BLUE)
    assert_true(half_red.over(Color.BLUE) == Color(128, 0, 127, 255))
    assert_true(half_red.over(Color(0, 0, 255, 128)) == Color(170, 0, 85, 192))


def test_rectangles() raises:
    var frame = Framebuffer(8, 8)
    assert_true(frame.pixel(0, 0) == Color.TRANSPARENT)
    frame.clear(Color.BLUE)
    assert_true(frame.pixel(7, 7) == Color.BLUE)
    assert_true(frame.pixel(-1, 0) == Color.TRANSPARENT)
    assert_true(frame.pixel(8, 0) == Color.TRANSPARENT)
    assert_true(frame.pixel(0, 8) == Color.TRANSPARENT)

    frame.fill_rect(Rect(-2, -1, 4, 3), Color(255, 0, 0, 128))
    assert_true(frame.pixel(0, 0) == Color(128, 0, 127, 255))
    assert_true(frame.pixel(1, 1) == Color(128, 0, 127, 255))
    assert_true(frame.pixel(2, 1) == Color.BLUE)
    assert_true(frame.pixel(1, 2) == Color.BLUE)

    frame.clear(Color.TRANSPARENT)
    var ink = Color(255, 0, 0, 128)
    frame.stroke_rect(Rect(2, 2, 5, 4), ink)
    assert_true(frame.pixel(2, 2) == ink)
    assert_true(frame.pixel(6, 5) == ink)
    assert_true(frame.pixel(4, 3) == Color.TRANSPARENT)

    frame.clear(Color.TRANSPARENT)
    frame.fill_rounded_rect(Rect(-1, 0, 7, 6), 99, Color.GREEN)
    assert_true(frame.pixel(0, 0) == Color.GREEN)
    assert_true(frame.pixel(2, 0) == Color.GREEN)
    assert_true(frame.pixel(0, 2) == Color.GREEN)
    assert_true(frame.pixel(5, 0) == Color.TRANSPARENT)
    assert_true(frame.pixel(5, 5) == Color.TRANSPARENT)
    assert_true(frame.pixel(6, 2) == Color.TRANSPARENT)


def test_lines() raises:
    var frame = Framebuffer(6, 5)
    frame.draw_line(
        Point(Int.MAX, Int.MAX), Point(Int.MIN, Int.MIN), Color.WHITE
    )
    for y in range(frame.height()):
        for x in range(frame.width()):
            var expected = Color.WHITE if x == y else Color.TRANSPARENT
            assert_true(frame.pixel(x, y) == expected)

    frame.clear(Color.TRANSPARENT)
    frame.draw_line(Point(1, 0), Point(3, 4), Color.GREEN)
    assert_true(frame.pixel(1, 0) == Color.GREEN)
    assert_true(frame.pixel(2, 1) == Color.GREEN)
    assert_true(frame.pixel(1, 1) == Color.TRANSPARENT)
    assert_true(frame.pixel(3, 4) == Color.GREEN)

    frame.draw_line(Point(-3, 2), Point(1, 2), Color.RED)
    frame.draw_line(Point(5, 4), Point(5, 4), Color.BLUE)
    assert_true(frame.pixel(0, 2) == Color.RED)
    assert_true(frame.pixel(1, 2) == Color.RED)
    assert_true(frame.pixel(5, 4) == Color.BLUE)


def test_text() raises:
    assert_equal(text_width("", 2), 0)
    assert_equal(text_width("A?", 2), 22)
    var frame = Framebuffer(12, 12)
    frame.draw_text("a", Point(-2, 1), Color.WHITE, 2, Rect(1, 1, 4, 8))
    assert_true(frame.pixel(0, 1) == Color.TRANSPARENT)
    assert_true(frame.pixel(1, 1) == Color.WHITE)
    assert_true(frame.pixel(4, 1) == Color.WHITE)
    assert_true(frame.pixel(5, 1) == Color.TRANSPARENT)
    assert_true(frame.pixel(1, 9) == Color.TRANSPARENT)


def test_layout_and_widgets() raises:
    var column = Stack.vertical(
        Rect(10, 20, 60, 40), spacing=3, padding=Insets(4, 5, 6, 7)
    )
    assert_true(column.place(Size(12, 7)) == Rect(14, 25, 12, 7))
    assert_true(column.place(Size(0, 7)).is_empty())
    var row_bounds = column.place(Size(99, 8))
    assert_true(row_bounds == Rect(14, 35, 50, 8))
    assert_true(column.place(Size(12, 99)) == Rect(14, 46, 12, 7))
    assert_true(column.place(Size(12, 7)).is_empty())

    var row = Stack.horizontal(row_bounds, spacing=2, padding=Insets.uniform(1))
    assert_true(row.place(Size(20, 4)) == Rect(15, 36, 20, 4))
    assert_true(row.place(Size(99, 99)) == Rect(37, 36, 26, 6))
    assert_true(row.place(Size(1, 1)).is_empty())

    var frame = Framebuffer(22, 12)
    var label = Label("H")
    assert_true(label.size() == Size(5, 7))
    label.draw(frame, Rect(0, 0, 2, 3))
    assert_true(frame.pixel(0, 2) == Color.WHITE)
    assert_true(frame.pixel(0, 3) == Color.TRANSPARENT)
    assert_true(frame.pixel(4, 0) == Color.TRANSPARENT)

    var button = Button("A", Color.BLUE, padding=Insets(2, 1, 2, 1), radius=0)
    assert_true(button.size() == Size(9, 9))
    button.draw(frame, Rect(8, 0, 13, 11))
    assert_true(frame.pixel(7, 0) == Color.TRANSPARENT)
    assert_true(frame.pixel(8, 0) == Color.BLUE)
    assert_true(frame.pixel(13, 2) == Color.WHITE)
    assert_true(frame.pixel(12, 2) == Color.BLUE)
    assert_true(frame.pixel(21, 10) == Color.TRANSPARENT)


def test_png_round_trip() raises:
    var frame = Framebuffer(2, 2)
    frame.fill_rect(Rect(0, 0, 1, 1), Color.RED)
    frame.fill_rect(Rect(1, 0, 1, 1), Color.GREEN)
    frame.fill_rect(Rect(0, 1, 1, 1), Color.BLUE)
    frame.fill_rect(Rect(1, 1, 1, 1), Color(10, 20, 30, 128))

    # Reference generated with Python zlib's stored DEFLATE mode and CRC-32.
    # It covers dimensions, row order, RGBA bytes, and both kinds of checksum.
    # fmt: off
    var expected: List[UInt8] = [
        137, 80, 78, 71, 13, 10, 26, 10,  # Signature
        0, 0, 0, 13, 73, 72, 68, 82,  # IHDR header
        0, 0, 0, 2, 0, 0, 0, 2, 8, 6, 0, 0, 0, 114, 182, 13, 36,
        0, 0, 0, 29, 73, 68, 65, 84,  # IDAT header
        120, 1, 1, 18, 0, 237, 255,  # zlib and stored block headers
        0, 255, 0, 0, 255, 0, 255, 0, 255,  # Filter and top row
        0, 0, 0, 255, 255, 10, 20, 30, 128,  # Filter and bottom row
        64, 242, 6, 183, 24, 173, 115, 114,  # Adler-32 and chunk CRC-32
        0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130,  # IEND
    ]
    # fmt: on
    with TemporaryDirectory() as directory:
        var path = String(directory) + "/test.png"
        frame.write_png(path)
        with open(path, "r") as file:
            var actual = file.read_bytes()
            assert_equal(len(actual), len(expected))
            for index in range(len(expected)):
                assert_equal(actual[index], expected[index])


def main() raises:
    test_geometry()
    test_color()
    test_rectangles()
    test_lines()
    test_text()
    test_layout_and_widgets()
    test_png_round_trip()
    print("All mojo-ui tests passed")
