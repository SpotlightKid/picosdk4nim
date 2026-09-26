import strutils
import picosdk4nim
import picosdk4nim/[gpio, i2c, stdio, time]
import hidecmakelinkerpkg/libconf

writeHideCMakeToFile()


# I2C reserves some addresses for special purposes. We exclude these from the scan.
# These are any addresses of the form 000 0xxx or 111 1xxx
proc reservedAddr(address: I2cAddress): bool =
  return (address.ord and 0x78) == 0 or (address.ord and 0x78) == 0x78


proc main() =
  stdioInitAll()

  # This example will use I2C0 on the default SDA and SCL pins (GP4, GP5 on a Pico)
  discard i2cDefault.init(100_000)
  DefaultI2cSdaPin.setFunction(I2c)
  DefaultI2cSclPin.setFunction(I2c)
  DefaultI2cSdaPin.pullUp()
  DefaultI2cSclPin.pullUp()

  while true:
    echo "I2C Bus Scan"
    echo " 0     1     2     3     4     5     6     7     8     9     A     B     C     D     E     F"

    var ret: int
    var rxdata: uint8

    for address in 0..<(1 shl 7):
      stdout.write(address.toHex(2) & " ")
      stdioFlush()

      # Perform a 1-byte dummy read from the probe address. If a slave
      # acknowledges this address, the function returns the number of bytes
      # transferred. If the address byte is ignored, the function returns
      # -1.

      # Skip over any reserved addresses.
      if reservedAddr(address.I2cAddress):
        ret = -2
      else:
        ret = i2cDefault.readBlocking(address.I2cAddress, rxdata.addr, 1, false)

      stdout.write(if ret < 0: '.' else: '@')
      stdout.write(if address mod 16 == 15: "\n" else: "  ")
      stdioFlush()

    echo "Done"
    sleep(5000)


main()

