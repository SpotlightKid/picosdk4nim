# SSD1306 OLED Display Driver
#
# Port of https://github.com/daschr/pico-ssd1306 to Nim
#
# Uses I2C for communication with SSD1306 OLED displays

import i2c

# SSD1306 Command Constants
const
  SetContrast* = 0x81'u8
  SetEntireOn = 0xA4'u8
  SetNormInv = 0xA6'u8
  SetDisp = 0xAE'u8
  SetDispClkDiv = 0xD5'u8
  SetMuxRatio = 0xA8'u8
  SetDispOffset = 0xD3'u8
  SetDispStartLine = 0x40'u8
  SetChargePump = 0x8D'u8
  SetMemAddr = 0x20'u8
  SetColAddr = 0x21'u8
  SetPageAddr = 0x22'u8
  SetSegRemap = 0xA1'u8
  SetComOutDir = 0xC8'u8
  SetComPinCfg = 0xDA'u8
  SetPrecharge = 0xD9'u8
  SetVcomDesel = 0xDB'u8

type
  Ssd1306* = object
    ## SSD1306 OLED display object
    i2c*: ptr I2cInst
    address*: I2cAddress
    width*: uint16
    height*: uint16
    pages*: uint16
    bufsize*: uint
    buffer*: ptr UncheckedArray[uint8]
    externalVcc*: bool


proc sendCmd(display: Ssd1306, cmd: uint8): cint {.inline, discardable.}


proc init*(
    display: var Ssd1306;
    width: uint16;
    height: uint16;
    address: I2cAddress;
    i2cInstance: ptr I2cInst;
    externalVcc: bool = false
  ): bool =
  ## Initialize the SSD1306 display.
  ##
  ## Parameters:
  ##   display: Display object to initialize
  ##   width: Display width in pixels
  ##   height: Display height in pixels
  ##   address: I2C address of the display (usually 0x3C.I2cAddress or 0x3D.I2cAddress)
  ##   i2cInstance: I2C instance to use (i2c0 or i2c1)
  ##   externalVcc: Whether external VCC is used (default: false for internal charge pump)
  ##
  ## Returns: true if initialization successful, false otherwise

  display.width = width
  display.height = height
  display.pages = height div 8
  display.address = address
  display.i2c = i2cInstance
  display.externalVcc = externalVcc

  display.bufsize = uint(display.pages) * uint(display.width)

  # Allocate buffer with extra byte for data prefix
  let buf = cast[ptr UncheckedArray[uint8]](alloc0(display.bufsize + 1))
  if buf == nil:
    display.bufsize = 0
    return false

  # Offset buffer pointer by 1 to leave room for command prefix
  display.buffer = cast[ptr UncheckedArray[uint8]](cast[uint](buf) + 1)

  # Initialize display with command sequence
  let cmds = [
    SetDisp,
    SetDispClkDiv,
    0x80,
    SetMuxRatio,
    uint8(height - 1),
    SetDispOffset,
    0x00,
    SetDispStartLine,
    SetChargePump,
    uint8(if externalVcc: 0x10 else: 0x14),
    SetSegRemap or 0x01,
    SetComOutDir or 0x08,
    SetComPinCfg,
    uint8(if width > 2 * height: 0x02 else: 0x12),
    SetContrast,
    0xFF,
    SetPrecharge,
    uint8(if externalVcc: 0x22 else: 0xF1),
    SetVcomDesel,
    0x30,
    SetEntireOn,
    SetNormInv,
    SetDisp or 0x01,
    SetMemAddr,
    0x00,
  ]

  for cmd in cmds:
    display.sendCmd(cmd)

  return true


proc sendCmd(display: Ssd1306, cmd: uint8): cint =
  let data = [0.uint8, cmd]
  display.i2c.writeBlocking(display.address, cast[ptr uint8](data[0].addr), 2, false)


proc deinit*(display: var Ssd1306) =
  ## Deinitialize and free the display buffer.
  if display.buffer != nil:
    dealloc(cast[pointer](cast[uint](display.buffer) - 1))
    display.buffer = nil


proc powerOff*(display: var Ssd1306) =
  ## Turn off the display.
  display.sendCmd(SetDisp)


proc powerOn*(display: var Ssd1306) =
  ## Turn on the display.
  display.sendCmd(SetDisp or 1)


proc setContrast*(display: var Ssd1306; value: uint8) =
  ## Set the display contrast.
  ##
  ## Parameters:
  ##   value: Contrast value (0-255)
  display.sendCmd(SetContrast)
  display.sendCmd(value)


proc invert*(display: var Ssd1306; inverted: bool) =
  ## Set inverted display mode.
  ##
  ## Parameters:
  ##   inverted: true for inverted, false for normal
  display.sendCmd(SetNormInv or uint8(if inverted: 1 else: 0))


proc clear*(display: var Ssd1306) =
  ## Clear the display buffer.
  zeroMem(display.buffer, display.bufsize)


proc drawPixel*(display: var Ssd1306; x: uint32; y: uint32) =
  ## Draw a pixel at the specified coordinates.
  ##
  ## Parameters:
  ##   x: X coordinate (0 to width-1)
  ##   y: Y coordinate (0 to height-1)
  if x >= uint32(display.width) or y >= uint32(display.height):
    return

  let offset = x + uint32(display.width) * (y shr 3)
  display.buffer[offset] = display.buffer[offset] or uint8(1 shl (y and 0x07))


proc clearPixel*(display: var Ssd1306; x: uint32; y: uint32) =
  ## Clear a pixel at the specified coordinates.
  ##
  ## Parameters:
  ##   x: X coordinate (0 to width-1)
  ##   y: Y coordinate (0 to height-1)
  if x >= uint32(display.width) or y >= uint32(display.height):
    return

  let offset = x + uint32(display.width) * (y shr 3)
  display.buffer[offset] = display.buffer[offset] and uint8(not (1 shl (y and 0x07)))


proc drawLine*(display: var Ssd1306; x1, y1, x2, y2: int32) =
  ## Draw a line from (x1, y1) to (x2, y2).
  var x1 = x1
  var x2 = x2
  var y1 = y1
  var y2 = y2

  if x1 > x2:
    swap(x1, x2)
    swap(y1, y2)

  if x1 == x2:
    if y1 > y2:
      swap(y1, y2)
    for i in y1 .. y2:
      display.drawPixel(uint32(x1), uint32(i))
    return

  let m = float(y2 - y1) / float(x2 - x1)

  for i in x1 .. x2:
    let y = m * float(i - x1) + float(y1)
    display.drawPixel(uint32(i), uint32(y))


proc drawSquare*(display: var Ssd1306; x, y, width, height: uint32) =
  ## Draw a filled square.
  ##
  ## Parameters:
  ##   x, y: Top-left corner coordinates
  ##   width, height: Dimensions in pixels
  for i in 0 ..< width:
    for j in 0 ..< height:
      display.drawPixel(x + i, y + j)


proc clearSquare*(display: var Ssd1306; x, y, width, height: uint32) =
  ## Clear a filled square area.
  ##
  ## Parameters:
  ##   x, y: Top-left corner coordinates
  ##   width, height: Dimensions in pixels
  for i in 0 ..< width:
    for j in 0 ..< height:
      display.clearPixel(x + i, y + j)


proc drawEmptySquare*(display: var Ssd1306; x, y, width, height: uint32) =
  ## Draw a hollow square (outline only).
  ##
  ## Parameters:
  ##   x, y: Top-left corner coordinates
  ##   width, height: Dimensions in pixels
  display.drawLine(int32(x), int32(y), int32(x + width), int32(y))
  display.drawLine(int32(x), int32(y + height), int32(x + width), int32(y + height))
  display.drawLine(int32(x), int32(y), int32(x), int32(y + height))
  display.drawLine(int32(x + width), int32(y), int32(x + width), int32(y + height))


proc drawCharWithFont*(
    display: var Ssd1306;
    x, y: uint32;
    scale: uint32;
    font: openArray[uint8];
    c: char
  ) =
  ## Draw a character using the specified font.
  ##
  ## Parameters:
  ##   x, y: Position to draw the character
  ##   scale: Scale factor for the character (1 = original size)
  ##   font: Font data array (format: height, width, spacing, firstChar, lastChar, data...)
  ##   c: Character to draw

  let charCode = uint32(ord(c))
  if charCode < uint32(font[3]) or charCode > uint32(font[4]):
    return

  let fontHeight = uint32(font[0])
  let fontWidth = uint32(font[1])
  let partsPerLine = (fontHeight shr 3) + (if (fontHeight and 7) > 0: 1'u32 else: 0'u32)

  for w in 0 ..< fontWidth:
    let pp = (charCode - uint32(font[3])) * fontWidth * partsPerLine + w * partsPerLine + 5'u32
    for lp in 0 ..< partsPerLine:
      var line = font[pp + lp]
      for j in 0 ..< 8:
        if (line and 1) != 0:
          display.drawSquare(x + w * scale, y + ((lp shl 3) + uint32(j)) * scale, scale, scale)
        line = line shr 1


proc drawStringWithFont*(
    display: var Ssd1306;
    x, y: uint32;
    scale: uint32;
    font: openArray[uint8];
    s: string
  ) =
  ## Draw a string using the specified font.
  ##
  ## Parameters:
  ##   x, y: Starting position
  ##   scale: Scale factor for the text (1 = original size)
  ##   font: Font data array
  ##   s: String to draw

  var xPos = x
  for c in s:
    display.drawCharWithFont(xPos, y, scale, font, c)
    xPos += (uint32(font[1]) + uint32(font[2])) * scale


proc bmpGetVal(data: openArray[uint8]; offset: uint32; size: uint8): uint32 =
  ## Extract a multi-byte value from BMP data.
  case size
  of 1:
    return uint32(data[offset])
  of 2:
    return uint32(data[offset]) or (uint32(data[offset + 1]) shl 8)
  of 4:
    return uint32(data[offset]) or
           (uint32(data[offset + 1]) shl 8) or
           (uint32(data[offset + 2]) shl 16) or
           (uint32(data[offset + 3]) shl 24)
  else:
    return 0


proc showImageWithOffset*(
    display: var Ssd1306;
    data: openArray[uint8];
    xOffset: uint32 = 0;
    yOffset: uint32 = 0
  ) =
  ## Display a monochrome BMP image with offset.
  ##
  ## Parameters:
  ##   data: BMP file data (complete file including header)
  ##   xOffset: Horizontal offset in pixels
  ##   yOffset: Vertical offset in pixels

  if data.len < 54:
    return  # Data smaller than BMP header

  let bfOffBits = bmpGetVal(data, 10, 4)
  let biSize = bmpGetVal(data, 14, 4)
  let biWidth = bmpGetVal(data, 18, 4)
  let biHeight = int32(bmpGetVal(data, 22, 4))
  let biBitCount = uint16(bmpGetVal(data, 28, 2))
  let biCompression = bmpGetVal(data, 30, 4)

  if biBitCount != 1:
    return  # Image not monochrome

  if biCompression != 0:
    return  # Image compressed

  let tableStart = 14 + biSize
  var colorVal: uint8 = 0

  for i in 0.uint32 ..< 2.uint32:
    if not (((uint32(data[tableStart + i * 4]) shl 16) or
             (uint32(data[tableStart + i * 4 + 1]) shl 8) or
             uint32(data[tableStart + i * 4 + 2])) != 0):
      colorVal = uint8(i)
      break

  var bytesPerLine = (biWidth div 8) + (if (biWidth and 7) != 0: 1'u32 else: 0'u32)
  if (bytesPerLine and 3) != 0:
    bytesPerLine = (bytesPerLine xor (bytesPerLine and 3)) + 4

  var imgDataOffset = uint32(bfOffBits)

  let step = if biHeight > 0: -1'i32 else: 1'i32
  let border = if biHeight > 0: -1'i32 else: -biHeight

  var y = if biHeight > 0: uint32(biHeight - 1) else: 0'u32
  while y != uint32(border):
    for x in 0 ..< biWidth:
      if ((data[imgDataOffset + (x shr 3)] shr (7 - (x and 7))) and 1) == colorVal:
        display.drawPixel(xOffset + x, yOffset + y)
    imgDataOffset += bytesPerLine
    y = uint32(int32(y) + step)


proc showImage*(
    display: var Ssd1306;
    data: openArray[uint8]
  ) =
  ## Display a monochrome BMP image.
  ##
  ## Parameters:
  ##   data: BMP file data (complete file including header)
  display.showImageWithOffset(data, 0, 0)


proc show*(display: var Ssd1306) =
  ## Update the physical display with the buffer contents.
  var payload = [
    SetColAddr,
    0.uint8,
    uint8(display.width - 1),
    SetPageAddr,
    0.uint8,
    uint8(display.pages - 1)
  ]

  if display.width == 64:
    payload[1] += 32
    payload[2] += 32

  for cmd in payload:
    display.sendCmd(cmd)

  # Set data prefix and send entire buffer
  let bufPtr = cast[ptr uint8](cast[uint](display.buffer) - 1)
  bufPtr[] = 0x40  # Data prefix

  discard display.i2c.writeBlocking(
    display.address,
    bufPtr,
    display.bufsize + 1,
    false
  )

