"""Straight-alpha RGBA colors with 8-bit channels."""


@fieldwise_init
struct Color(TrivialRegisterPassable, Equatable):
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8

    comptime TRANSPARENT = Self(0, 0, 0, 0)
    comptime BLACK = Self(0, 0, 0, 255)
    comptime WHITE = Self(255, 255, 255, 255)
    comptime RED = Self(255, 0, 0, 255)
    comptime GREEN = Self(0, 255, 0, 255)
    comptime BLUE = Self(0, 0, 255, 255)

    @staticmethod
    def rgb(r: UInt8, g: UInt8, b: UInt8) -> Self:
        return Self(r, g, b, 255)

    def __eq__(self, other: Self) -> Bool:
        return (
            self.r == other.r
            and self.g == other.g
            and self.b == other.b
            and self.a == other.a
        )

    def over(self, background: Self) -> Self:
        """Composite this color over a background using source-over."""
        if self.a == 0:
            return background
        if self.a == 255 or background.a == 0:
            return self

        # Keep the weights at full integer precision until the final division.
        var foreground_weight = Int(self.a) * 255
        var background_weight = Int(background.a) * (255 - Int(self.a))
        var total_weight = foreground_weight + background_weight
        var red = Int(self.r) * foreground_weight + Int(background.r) * background_weight
        var green = Int(self.g) * foreground_weight + Int(background.g) * background_weight
        var blue = Int(self.b) * foreground_weight + Int(background.b) * background_weight
        return Self(
            UInt8((red + total_weight // 2) // total_weight),
            UInt8((green + total_weight // 2) // total_weight),
            UInt8((blue + total_weight // 2) // total_weight),
            UInt8((total_weight + 127) // 255),
        )
