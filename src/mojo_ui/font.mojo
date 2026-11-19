"""A tiny 5×7 bitmap font for labels and buttons."""


comptime GLYPH_WIDTH = 5
comptime GLYPH_HEIGHT = 7
comptime GLYPH_ADVANCE = GLYPH_WIDTH + 1

# Each value is one row. The leftmost pixel is the highest of the five bits.
# The eighth slot pads the bitmap to a fixed-size vector.
comptime _Glyph = SIMD[DType.uint8, 8]


def text_width(text: String, scale: Int = 1) -> Int:
    """Return the width in pixels, excluding the trailing letter spacing."""
    if scale <= 0:
        return 0
    var count = 0
    for _ in text.codepoints():
        count += 1
    if count == 0:
        return 0
    var columns = count * GLYPH_ADVANCE - 1
    if columns > Int.MAX // scale:
        return Int.MAX
    return columns * scale


def _glyph(codepoint: Int) -> _Glyph:
    var letter = codepoint
    if ord("a") <= letter <= ord("z"):
        letter -= ord("a") - ord("A")

    if letter == ord("A"):
        return _Glyph(0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001, 0)
    if letter == ord("B"):
        return _Glyph(0b11110, 0b10001, 0b10001, 0b11110, 0b10001, 0b10001, 0b11110, 0)
    if letter == ord("C"):
        return _Glyph(0b01110, 0b10001, 0b10000, 0b10000, 0b10000, 0b10001, 0b01110, 0)
    if letter == ord("D"):
        return _Glyph(0b11110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b11110, 0)
    if letter == ord("E"):
        return _Glyph(0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b11111, 0)
    if letter == ord("F"):
        return _Glyph(0b11111, 0b10000, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000, 0)
    if letter == ord("G"):
        return _Glyph(0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01110, 0)
    if letter == ord("H"):
        return _Glyph(0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001, 0)
    if letter == ord("I"):
        return _Glyph(0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110, 0)
    if letter == ord("J"):
        return _Glyph(0b00111, 0b00010, 0b00010, 0b00010, 0b00010, 0b10010, 0b01100, 0)
    if letter == ord("K"):
        return _Glyph(0b10001, 0b10010, 0b10100, 0b11000, 0b10100, 0b10010, 0b10001, 0)
    if letter == ord("L"):
        return _Glyph(0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111, 0)
    if letter == ord("M"):
        return _Glyph(0b10001, 0b11011, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001, 0)
    if letter == ord("N"):
        return _Glyph(0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001, 0)
    if letter == ord("O"):
        return _Glyph(0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110, 0)
    if letter == ord("P"):
        return _Glyph(0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000, 0)
    if letter == ord("Q"):
        return _Glyph(0b01110, 0b10001, 0b10001, 0b10001, 0b10101, 0b10010, 0b01101, 0)
    if letter == ord("R"):
        return _Glyph(0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001, 0)
    if letter == ord("S"):
        return _Glyph(0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110, 0)
    if letter == ord("T"):
        return _Glyph(0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0)
    if letter == ord("U"):
        return _Glyph(0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110, 0)
    if letter == ord("V"):
        return _Glyph(0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b00100, 0)
    if letter == ord("W"):
        return _Glyph(0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b11011, 0b10001, 0)
    if letter == ord("X"):
        return _Glyph(0b10001, 0b10001, 0b01010, 0b00100, 0b01010, 0b10001, 0b10001, 0)
    if letter == ord("Y"):
        return _Glyph(0b10001, 0b10001, 0b01010, 0b00100, 0b00100, 0b00100, 0b00100, 0)
    if letter == ord("Z"):
        return _Glyph(0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b11111, 0)
    if letter == ord("0"):
        return _Glyph(0b01110, 0b10001, 0b10011, 0b10101, 0b11001, 0b10001, 0b01110, 0)
    if letter == ord("1"):
        return _Glyph(0b00100, 0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110, 0)
    if letter == ord("2"):
        return _Glyph(0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0b01000, 0b11111, 0)
    if letter == ord("3"):
        return _Glyph(0b11110, 0b00001, 0b00001, 0b01110, 0b00001, 0b00001, 0b11110, 0)
    if letter == ord("4"):
        return _Glyph(0b00010, 0b00110, 0b01010, 0b10010, 0b11111, 0b00010, 0b00010, 0)
    if letter == ord("5"):
        return _Glyph(0b11111, 0b10000, 0b10000, 0b11110, 0b00001, 0b00001, 0b11110, 0)
    if letter == ord("6"):
        return _Glyph(0b01110, 0b10000, 0b10000, 0b11110, 0b10001, 0b10001, 0b01110, 0)
    if letter == ord("7"):
        return _Glyph(0b11111, 0b00001, 0b00010, 0b00100, 0b01000, 0b01000, 0b01000, 0)
    if letter == ord("8"):
        return _Glyph(0b01110, 0b10001, 0b10001, 0b01110, 0b10001, 0b10001, 0b01110, 0)
    if letter == ord("9"):
        return _Glyph(0b01110, 0b10001, 0b10001, 0b01111, 0b00001, 0b00001, 0b01110, 0)
    if letter == ord(" "):
        return _Glyph(0, 0, 0, 0, 0, 0, 0, 0)
    if letter == ord("."):
        return _Glyph(0, 0, 0, 0, 0, 0b00110, 0b00110, 0)
    if letter == ord(":"):
        return _Glyph(0, 0b00110, 0b00110, 0, 0b00110, 0b00110, 0, 0)
    if letter == ord("-"):
        return _Glyph(0, 0, 0, 0b01110, 0, 0, 0, 0)
    if letter == ord("/"):
        return _Glyph(0b00001, 0b00001, 0b00010, 0b00100, 0b01000, 0b10000, 0b10000, 0)
    if letter == ord("!"):
        return _Glyph(0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0, 0b00100, 0)
    # A question mark also stands in for unsupported code points.
    return _Glyph(0b01110, 0b10001, 0b00001, 0b00010, 0b00100, 0, 0b00100, 0)
