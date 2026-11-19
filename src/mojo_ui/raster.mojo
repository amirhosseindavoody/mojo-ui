"""Software drawing into a row-major, straight-alpha RGBA framebuffer."""

from .color import Color
from .font import GLYPH_ADVANCE, GLYPH_HEIGHT, GLYPH_WIDTH, _glyph
from .geometry import Point, Rect
from .png import _write_png


struct Framebuffer(Movable):
    var _width: Int
    var _height: Int
    var _pixels: List[Color]

    def __init__(out self, width: Int, height: Int) raises:
        if width <= 0 or height <= 0:
            raise Error("Framebuffer dimensions must be positive")
        if width > 0x7FFFFFFF or height > 0x7FFFFFFF:
            raise Error("Framebuffer dimensions exceed the PNG format limit")
        if height > Int.MAX // (width * 4 + 1):
            raise Error("Framebuffer size exceeds the addressable byte count")
        self._width = width
        self._height = height
        self._pixels = List[Color](length=width * height, fill=Color.TRANSPARENT)

    def width(self) -> Int:
        return self._width

    def height(self) -> Int:
        return self._height

    def bounds(self) -> Rect:
        return Rect(0, 0, self._width, self._height)

    def pixel(self, x: Int, y: Int) -> Color:
        """Read a pixel, returning transparent for coordinates outside the image."""
        if 0 <= x < self._width and 0 <= y < self._height:
            return self._pixels[y * self._width + x]
        return Color.TRANSPARENT

    def clear(mut self, color: Color):
        """Replace every pixel with color, including its alpha."""
        for index in range(len(self._pixels)):
            self._pixels[index] = color

    def _blend_at(mut self, x: Int, y: Int, color: Color):
        # Drawing methods clip before calling this helper.
        var index = y * self._width + x
        self._pixels[index] = color.over(self._pixels[index])

    def fill_rect(mut self, rect: Rect, color: Color):
        var area = rect.intersection(self.bounds())
        for y in range(area.y, area.bottom()):
            for x in range(area.x, area.right()):
                self._blend_at(x, y, color)

    def stroke_rect(mut self, rect: Rect, color: Color, thickness: Int = 1):
        """Draw an inside border. Each pixel gets blended at most once."""
        if rect.is_empty() or thickness <= 0:
            return
        var top = min(thickness, rect.height)
        var bottom = min(thickness, rect.height - top)
        var sides_y = rect.y + top
        var sides_height = rect.height - top - bottom
        var left = min(thickness, rect.width)
        var right = min(thickness, rect.width - left)

        self.fill_rect(Rect(rect.x, rect.y, rect.width, top), color)
        self.fill_rect(
            Rect(rect.x, rect.bottom() - bottom, rect.width, bottom), color
        )
        self.fill_rect(Rect(rect.x, sides_y, left, sides_height), color)
        self.fill_rect(
            Rect(rect.right() - right, sides_y, right, sides_height), color
        )

    def draw_line(mut self, start: Point, end: Point, color: Color):
        """Draw a one-pixel line, including both endpoints."""
        # Step along the axis that changes most. Restrict those steps to the
        # image first, so an offscreen endpoint cannot create a long loop.
        var dx = Int128(end.x) - Int128(start.x)
        var dy = Int128(end.y) - Int128(start.y)
        var steep = abs(dy) > abs(dx)
        var first = start.y if steep else start.x
        var last = end.y if steep else end.x
        var minor_first = start.x if steep else start.y
        var minor_last = end.x if steep else end.y
        var major_limit = self._height if steep else self._width
        var minor_limit = self._width if steep else self._height

        if first > last:
            # A consistent stepping direction makes reversing a line safe.
            first, last = last, first
            minor_first, minor_last = minor_last, minor_first

        # Interpolate in wide integers to avoid losing precision when the
        # endpoints are far offscreen. The bias rounds to the nearest pixel,
        # with ties toward the larger coordinate. A point uses a span of one.
        var span = max(Int128(1), Int128(last) - Int128(first))
        var limit = Int128(minor_limit) * span
        for major in range(max(first, 0), min(last, major_limit - 1) + 1):
            var offset = Int128(major) - Int128(first)
            var minor = (
                Int128(minor_first) * (span - offset)
                + Int128(minor_last) * offset
                + span // 2
            )
            if minor >= Int128(0) and minor < limit:
                var pixel = Int(minor // span)
                if steep:
                    self._blend_at(pixel, major, color)
                else:
                    self._blend_at(major, pixel, color)

    def fill_rounded_rect(mut self, rect: Rect, radius: Int, color: Color):
        """Fill a rectangle with circular corners sampled at pixel centers."""
        var corner = min(radius, min(rect.width, rect.height) // 2)
        if corner <= 0:
            self.fill_rect(rect, color)
            return

        var area = rect.intersection(self.bounds())
        var inner_left = Float64(rect.x + corner)
        var inner_top = Float64(rect.y + corner)
        var inner_right = Float64(rect.right() - corner)
        var inner_bottom = Float64(rect.bottom() - corner)
        var radius_squared = Float64(corner) * Float64(corner)
        # A pixel belongs to the shape if its center lies within the radius
        # of the center rectangle. Straight edges follow from the same test.
        for y in range(area.y, area.bottom()):
            var center_y = Float64(y) + 0.5
            var dy = max(0.0, max(inner_top - center_y, center_y - inner_bottom))
            for x in range(area.x, area.right()):
                var center_x = Float64(x) + 0.5
                var dx = max(0.0, max(inner_left - center_x, center_x - inner_right))
                if dx * dx + dy * dy <= radius_squared:
                    self._blend_at(x, y, color)

    def draw_text(
        mut self, text: String, position: Point, color: Color, scale: Int = 1
    ):
        self.draw_text(text, position, color, scale, self.bounds())

    def draw_text(
        mut self, text: String, position: Point, color: Color, scale: Int, clip: Rect
    ):
        """Draw one line of bitmap text within a rectangular clip."""
        if scale <= 0 or scale > Int.MAX // GLYPH_HEIGHT:
            return
        var area = clip.intersection(self.bounds())
        if area.is_empty():
            return
        var x = position.x
        var advance = GLYPH_ADVANCE * scale
        for character in text.codepoints():
            if x >= area.right():
                break
            var glyph_rect = Rect(x, position.y, GLYPH_WIDTH * scale, GLYPH_HEIGHT * scale)
            var visible = glyph_rect.intersection(area)
            if not visible.is_empty():
                var glyph = _glyph(Int(character))
                for y in range(visible.y, visible.bottom()):
                    var row = glyph[(y - position.y) // scale]
                    for column in range(visible.x, visible.right()):
                        var bit = GLYPH_WIDTH - 1 - (column - x) // scale
                        if (row >> UInt8(bit)) & 1 != 0:
                            self._blend_at(column, y, color)
            if x > Int.MAX - advance:
                break
            x += advance

    def write_png(self, path: String) raises:
        """Write the current pixels to an RGBA PNG file."""
        _write_png(path, self._width, self._height, self._pixels)
