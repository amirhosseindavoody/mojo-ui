"""Integer geometry in framebuffer pixels, with the origin at the top left."""


@fieldwise_init
struct Point(TrivialRegisterPassable, Equatable):
    var x: Int
    var y: Int

    def __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y


struct Size(TrivialRegisterPassable, Equatable):
    var width: Int
    var height: Int

    def __init__(out self, width: Int, height: Int):
        self.width = max(0, width)
        self.height = max(0, height)

    def __eq__(self, other: Self) -> Bool:
        return self.width == other.width and self.height == other.height


struct Insets(TrivialRegisterPassable):
    var left: Int
    var top: Int
    var right: Int
    var bottom: Int

    def __init__(out self, left: Int, top: Int, right: Int, bottom: Int):
        self.left = max(0, left)
        self.top = max(0, top)
        self.right = max(0, right)
        self.bottom = max(0, bottom)

    @staticmethod
    def uniform(pixels: Int) -> Self:
        return Self(pixels, pixels, pixels, pixels)


struct Rect(TrivialRegisterPassable, Equatable):
    """A half-open rectangle. Right and bottom edges are excluded."""

    var x: Int
    var y: Int
    var width: Int
    var height: Int

    def __init__(out self, x: Int, y: Int, width: Int, height: Int):
        self.x = x
        self.y = y
        # Keep even very large offscreen rectangles safe to intersect.
        self.width = max(0, width)
        self.height = max(0, height)
        if x > Int.MAX - self.width:
            self.width = Int.MAX - x
        if y > Int.MAX - self.height:
            self.height = Int.MAX - y

    def __eq__(self, other: Self) -> Bool:
        return (
            self.x == other.x
            and self.y == other.y
            and self.width == other.width
            and self.height == other.height
        )

    def right(self) -> Int:
        return self.x + self.width

    def bottom(self) -> Int:
        return self.y + self.height

    def is_empty(self) -> Bool:
        return self.width == 0 or self.height == 0

    def contains(self, point: Point) -> Bool:
        return (
            self.x <= point.x < self.right()
            and self.y <= point.y < self.bottom()
        )

    def intersection(self, other: Self) -> Self:
        var left = max(self.x, other.x)
        var top = max(self.y, other.y)
        var right = min(self.right(), other.right())
        var bottom = min(self.bottom(), other.bottom())
        if right <= left or bottom <= top:
            return Self(left, top, 0, 0)
        return Self(left, top, right - left, bottom - top)

    def inset(self, padding: Insets) -> Self:
        """Shrink each edge, stopping once it meets the opposite edge."""
        var left = min(padding.left, self.width)
        var top = min(padding.top, self.height)
        var width = max(0, self.width - left - padding.right)
        var height = max(0, self.height - top - padding.bottom)
        return Self(self.x + left, self.y + top, width, height)
