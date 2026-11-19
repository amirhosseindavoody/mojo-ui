"""Immediate-mode layout and widgets that draw into a framebuffer."""

from .color import Color
from .font import GLYPH_HEIGHT, text_width
from .geometry import Insets, Point, Rect, Size
from .raster import Framebuffer


struct Stack:
    """Place items from the top left, with fixed padding and spacing."""

    var _bounds: Rect
    var _horizontal: Bool
    var _spacing: Int
    var _used: Int

    def __init__(out self, bounds: Rect, horizontal: Bool, spacing: Int):
        self._bounds = bounds
        self._horizontal = horizontal
        self._spacing = max(0, spacing)
        self._used = 0

    @staticmethod
    def vertical(
        bounds: Rect, spacing: Int = 0, padding: Insets = Insets.uniform(0)
    ) -> Self:
        return Self(bounds.inset(padding), False, spacing)

    @staticmethod
    def horizontal(
        bounds: Rect, spacing: Int = 0, padding: Insets = Insets.uniform(0)
    ) -> Self:
        return Self(bounds.inset(padding), True, spacing)

    def place(mut self, preferred: Size) -> Rect:
        """Allocate up to the requested size, clipped to the stack's bounds."""
        var bounds = self._bounds
        var width = min(preferred.width, bounds.width)
        var height = min(preferred.height, bounds.height)
        var x = bounds.x
        var y = bounds.y
        var capacity = bounds.height
        if self._horizontal:
            x += self._used
            capacity = bounds.width
            width = min(width, capacity - self._used)
        else:
            y += self._used
            height = min(height, capacity - self._used)

        var placed = Rect(x, y, width, height)
        if not placed.is_empty():
            self._used += width if self._horizontal else height
            self._used += min(self._spacing, capacity - self._used)
        return placed


struct Label:
    """A single line of text drawn from the top left of its bounds."""

    var text: String
    var color: Color
    var scale: Int

    def __init__(
        out self, var text: String, color: Color = Color.WHITE, scale: Int = 1
    ):
        self.text = text^
        self.color = color
        self.scale = scale

    def size(self) -> Size:
        if self.scale <= 0 or self.scale > Int.MAX // GLYPH_HEIGHT:
            return Size(0, 0)
        return Size(
            text_width(self.text, self.scale), GLYPH_HEIGHT * self.scale
        )

    def draw(self, mut frame: Framebuffer, bounds: Rect):
        frame.draw_text(
            self.text, Point(bounds.x, bounds.y), self.color, self.scale, bounds
        )


struct Button:
    """A rounded background and a centered label with configurable padding."""

    var label: Label
    var background: Color
    var padding: Insets
    var radius: Int

    def __init__(
        out self,
        var text: String,
        background: Color,
        foreground: Color = Color.WHITE,
        scale: Int = 1,
        padding: Insets = Insets(10, 6, 10, 6),
        radius: Int = 4,
    ):
        self.label = Label(text^, foreground, scale)
        self.background = background
        self.padding = padding
        self.radius = radius

    def size(self) -> Size:
        var text = self.label.size()
        # Saturate each padding addition to keep the preferred size representable.
        var width = text.width + min(self.padding.left, Int.MAX - text.width)
        var height = text.height + min(self.padding.top, Int.MAX - text.height)
        return Size(
            width + min(self.padding.right, Int.MAX - width),
            height + min(self.padding.bottom, Int.MAX - height),
        )

    def draw(self, mut frame: Framebuffer, bounds: Rect):
        frame.fill_rounded_rect(bounds, self.radius, self.background)
        var content = bounds.inset(self.padding)
        var text = self.label.size()
        var x = content.x + max(0, (content.width - text.width) // 2)
        var y = content.y + max(0, (content.height - text.height) // 2)
        var text_bounds = Rect(x, y, text.width, text.height).intersection(
            content
        )
        self.label.draw(frame, text_bounds)
