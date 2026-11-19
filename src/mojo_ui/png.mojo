"""A minimal RGBA PNG encoder using uncompressed DEFLATE blocks."""

from std.io.file import FileHandle

from .color import Color


def _append_u32(mut bytes: List[UInt8], value: UInt32):
    """Append a big-endian integer, as used by PNG and the Adler checksum."""
    bytes.append(UInt8(value >> 24))
    bytes.append(UInt8(value >> 16))
    bytes.append(UInt8(value >> 8))
    bytes.append(UInt8(value))


def _crc32_step(previous: UInt32, byte: UInt8) -> UInt32:
    var crc = previous ^ UInt32(byte)
    for _ in range(8):
        var low_bit = crc & 1
        crc >>= 1
        if low_bit != 0:
            crc ^= 0xEDB88320  # Reflected CRC-32 polynomial used by PNG.
    return crc


def _write_chunk(
    mut file: FileHandle, name: String, data: Span[UInt8, _]
) raises:
    var header = List[UInt8](capacity=8)
    _append_u32(header, UInt32(len(data)))
    var crc: UInt32 = 0xFFFFFFFF
    for byte in name.as_bytes():
        header.append(byte)
        crc = _crc32_step(crc, byte)
    for byte in data:
        crc = _crc32_step(crc, byte)

    var checksum = List[UInt8](capacity=4)
    _append_u32(checksum, crc ^ 0xFFFFFFFF)
    file.write_bytes(header)
    if len(data) > 0:
        file.write_bytes(data)
    file.write_bytes(checksum)


def _zlib_store(data: List[UInt8]) -> List[UInt8]:
    """Wrap scanlines in a zlib stream with stored blocks and Adler-32."""
    var stream: List[UInt8] = [0x78, 0x01]
    var offset = 0
    var sum1: UInt32 = 1
    var sum2: UInt32 = 0
    while offset < len(data):
        var count = min(65535, len(data) - offset)
        var end = offset + count
        # A stored block starts on a byte boundary. Bit zero marks the last one.
        stream.append(UInt8(1 if end == len(data) else 0))
        var complement = 65535 - count
        stream.append(UInt8(count))
        stream.append(UInt8(count >> 8))
        stream.append(UInt8(complement))
        stream.append(UInt8(complement >> 8))
        for index in range(offset, end):
            var byte = data[index]
            stream.append(byte)
            sum1 = (sum1 + UInt32(byte)) % 65521
            sum2 = (sum2 + sum1) % 65521
        offset = end

    _append_u32(stream, (sum2 << 16) | sum1)
    return stream^


def _write_png(
    path: String, width: Int, height: Int, pixels: List[Color]
) raises:
    var scanlines = List[UInt8](capacity=(1 + width * 4) * height)
    for y in range(height):
        scanlines.append(0)  # PNG filter type 0 keeps the row bytes as-is.
        for x in range(width):
            var color = pixels[y * width + x]
            scanlines.append(color.r)
            scanlines.append(color.g)
            scanlines.append(color.b)
            scanlines.append(color.a)

    var signature: List[UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    var header = List[UInt8](capacity=13)
    _append_u32(header, UInt32(width))
    _append_u32(header, UInt32(height))
    header.append(8)  # Bits per channel.
    header.append(6)  # RGBA color type.
    header.append(0)  # DEFLATE compression.
    header.append(0)  # Standard PNG filter method.
    header.append(0)  # No interlacing.

    var compressed = _zlib_store(scanlines)
    if len(compressed) > 0x7FFFFFFF:
        raise Error("PNG data exceeds the single-chunk size limit")
    var empty = List[UInt8]()
    with open(path, "w") as file:
        file.write_bytes(signature)
        _write_chunk(file, "IHDR", header)
        _write_chunk(file, "IDAT", compressed)
        _write_chunk(file, "IEND", empty)
