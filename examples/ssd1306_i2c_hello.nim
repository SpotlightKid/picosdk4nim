## Example: Display "Hello Pico!" on SSD1306 OLED display
##
## Connects to an SSD1306 OLED display via I2C bus 0 at address 0x3C.
## Displays "Hello Pico" text with a border around it.
##
## Wiring (for Raspberry Pi Pico):
##   - SDA: GPIO 4 (I2C0 SDA)
##   - SCL: GPIO 5 (I2C0 SCL)
##   - VCC: 3.3V
##   - GND: GND

import picosdk4nim
import picosdk4nim/[gpio, i2c, ssd1306_i2c, time]
import hidecmakelinkerpkg/libconf
import ./font8x5

writeHideCMakeToFile()


# I2C and display configuration
const
  I2cFreq = 400_000  # 400 kHz
  DisplayAddress = 0x3C.I2cAddress
  DisplayWidth = 128
  DisplayHeight = 64
  Message = "Hello Pico"


proc main() =
  # Initialize I2C bus 0
  i2c0.init(I2cFreq)
  DefaultI2cSdaPin.setFunction(I2c)
  DefaultI2cSclPin.setFunction(I2c)
  DefaultI2cSdaPin.pullUp()
  DefaultI2cSclPin.pullUp()

  # Initialize display
  var display: Ssd1306
  if not display.init(
    DisplayWidth.uint16,
    DisplayHeight.uint16,
    DisplayAddress,
    i2c0,
    externalVcc = false
  ):
    # Initialization failed
    while true:
      discard

  # Clear the display
  # Superfluous directly after display initialization
  #display.clear()

  # Draw a border (hollow square)
  display.drawEmptySquare(0, 0, DisplayWidth.uint32 - 1, DisplayHeight.uint32 - 1)

  # Draw some decorative lines
  display.drawLine(10, 15, 117, 15)
  display.drawLine(10, 48, 117, 48)

  # Draw "Hello Pico!" with scale 2
  # Font is 8 pixels tall, scale 2 makes it 16 pixels tall
  # Position it in the center area
  display.drawStringWithFont(uint32(DisplayWidth / 2 - (Message.len * 12 / 2)), 26, 2, Font8x5, Message)

  # Display the buffer on screen
  display.show()

  # Keep the display running
  while true:
    sleep(100)


main()

