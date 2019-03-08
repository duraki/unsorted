# Creating GIF image data format in pure Crystal
# @see: http://www.onicos.com/staff/iz/formats/gif.html#header
# @see: https://techterms.com/definition/gif
module Gifal
  extend self
  # Default encoding format
  BYTE_ORDER = IO::ByteFormat::LittleEndian

  # Logical screen dimensions
  SCREEN_WIDTH  = 640
  SCREEN_HEIGHT = 480

  enum FormatType : UInt8
    T87A
    T89A
  end

  def build(type : FormatType = FormatType::T89A)
    io = IO::Memory.new
    # Offset   Length   Contents
    #   0      3 bytes  "GIF"
    #   3      3 bytes  "87a" or "89a"
    "GIF89a".chars.each do |char|
      io.write_bytes(char.ord.to_u8, BYTE_ORDER)
    end

    #   6      2 bytes  <Logical Screen Width>
    io << IO::ByteFormat::LittleEndian.encode(SCREEN_WIDTH, io)

    #   8      2 bytes  <Logical Screen Height>
    io << IO::ByteFormat::LittleEndian.encode(SCREEN_HEIGHT, io)

    #  10      1 byte   bit 0:    Global Color Table Flag (GCTF)
    #                   bit 1..3: Color Resolution
    #                   bit 4:    Sort Flag to Global Color Table
    #                   bit 5..7: Size of Global Color Table: 2^(1+n)
    bits = ("00000010").to_i(2)
    io << IO::ByteFormat::LittleEndian.encode(bits, io)

    #  11      1 byte   <Background Color Index>
    io << IO::ByteFormat::LittleEndian.encode(0, io)

    #  12      1 byte   <Pixel Aspect Ratio>
    io << IO::ByteFormat::LittleEndian.encode(1, io)

    #  13      ? bytes  <Global Color Table(0..255 x 3 bytes) if GCTF is one>
    #          ? bytes  <Blocks>

    # :blocks:
    # Offset   Length   Contents
    # 0      1 byte     Image Separator (0x2c)
    io << "\u{2c}"

    #   1      2 bytes  Image Left Position
    io << IO::ByteFormat::LittleEndian.encode(0, io)

    #   3      2 bytes  Image Top Position
    io << IO::ByteFormat::LittleEndian.encode(0, io)

    #   5      2 bytes  Image Width
    io << IO::ByteFormat::LittleEndian.encode(SCREEN_WIDTH, io)

    #   7      2 bytes  Image Height
    io << IO::ByteFormat::LittleEndian.encode(SCREEN_HEIGHT, io)

    #   8      1 byte   bit 0:    Local Color Table Flag (LCTF)
    #                   bit 1:    Interlace Flag
    #                   bit 2:    Sort Flag
    #                   bit 2..3: Reserved
    #                   bit 4..7: Size of Local Color Table: 2^(1+n)
    #          ? bytes  Local Color Table(0..255 x 3 bytes) if LCTF is one
    bits = ("00000100").to_i(2)
    io << IO::ByteFormat::LittleEndian.encode(bits, io)

    #          1 byte   LZW Minimum Code Size
    # io << IO::ByteFormat::LittleEndian.encode(1, io)

    # [ // Blocks
    #          1 byte   Block Size (s)
    # io << IO::ByteFormat::LittleEndian.encode(1, io)

    #         (s)bytes  Image Data
    # ]*
    #          1 byte   Block Terminator(0x00)
    # io << IO::ByteFormat::LittleEndian.encode(0, io)

    #          1 bytes  <Trailer> (0x3b)
    io << "\u{3b}"

    io.close
    io
  end

  def write(io : IO, outfile = "/tmp/gifal.gif")
    pp "File #{outfile} writeable: #{File.writable?(outfile)}"
    File.write(outfile, io.to_s)
  end
end

# usage
byte_data = Gifal.build
Gifal.write(io: byte_data)
pp byte_data.to_s.to_slice.hexdump
