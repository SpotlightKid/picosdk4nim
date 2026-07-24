import picosdk4nim
import picosdk4nim/[stdio, gpio, time, flash, platform]
import hidecmakelinkerpkg/libconf

import strutils

writeHideCMakeToFile()

stdioInitAll()

stdio.blockUntilUsbConnected()


echo "XipBase ", XipBase.int

echo "FlashPageSize ", FlashPageSize.int
echo "FlashSectorSize ", FlashSectorSize.int
echo "FlashBlockSize ", FlashBlockSize.int
echo "FlashUniqueIdSizeBytes ", FlashUniqueIdSizeBytes.int


# We're going to erase and reprogram a region 256k from the start of flash.
# Once done, we can access this at XIP_BASE + 256k.
const FLASH_TARGET_OFFSET = (256 * 1024)


proc print_buf(buf: ptr uint8, length: cuint) =
    var msg = ""
    for i  in 0.uint ..< length.uint:
        msg &= cast[ptr uint8](cast[uint](buf) + cast[uint](i))[].int.toHex(2) & " "
        if (i+1) mod 16 < 1:
           echo msg
           msg = ""

var
    data = newSeq[uint8](FlashPageSize)
    

for i in 0 ..< FlashPageSize:
    data[i] =i.uint8;


echo "Generated data:"
print_buf(data[0].addr, FlashPageSize)


echo "Erase Flash"
flashRangeErase(FLASH_TARGET_OFFSET, FlashPageSize)

echo "Write Flash"
flashRangeProgram(FLASH_TARGET_OFFSET, data[0].addr, FlashPageSize)


var
    mismatch = false
    msg = ""

for i in 0 ..< FLASH_PAGE_SIZE:
    var
        value = cast[ptr uint8](cast[uint](XipBase) + cast[uint](i) + FLASH_TARGET_OFFSET)[]

    msg &= value.int.toHex(2) & " "
    if (i+1) mod 16 < 1:
       echo msg
       msg = ""

    if (data[i] != value):
        mismatch = true

if mismatch:
    echo "Programming failed!\n"
else:
    echo "Programming successful!\n"



DefaultLedPin.init()
DefaultLedPin.setDir(Out)

while true:
  for i in 0..4:
    DefaultLedPin.put(Low)
    sleep(100)
    DefaultLedPin.put(High)
    sleep(100)
  echo "Test message from pico"
  sleep(1000)
