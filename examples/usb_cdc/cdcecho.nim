## Configure Pico into a USB serial device, which echos back anything it receives

import std/os
import picosdk4nim
import picosdk4nim/[gpio, time, tusb]
import hidecmakelinkerpkg/libconf


# CMake config generation
static:
  const srcDir = currentSourcePath().parentDir()
  config(initLibParams(
    cmakeStmts = [
      # Tell cmake to add "usb_descriptors.c" in the same directory as this file to sources
      initCMakeCmdWithTarget("target_sources(#target PRIVATE " & (srcDir / "usb_descriptors.c") & ")"),
      # And add the directory to include directories, so tinyusb can find "tusb_config.h"
      initCMakeCmdWithTarget("target_include_directories(#target PRIVATE " & srcDir & ")")
    ]
  ))

writeHideCMakeToFile()


# Types & Globals

type TimestampMicros = uint64

const
  LedBlinkIntervalNotMounted = 250'u64
  LedBlinkIntervalMounted = 1000'u64
  LedBlinkIntervalSuspended = 2500'u64

  # We have 1 serial (CDC) interface
  usbser = 0.UsbSerialInterface

var ledBlinkInterval: uint64 # ms


# USB Callbacks

# Set the LED blink based on USB state.
mountCallback:
  ledBlinkInterval = LedBlinkIntervalMounted

unmountCallback:
  ledBlinkInterval = LedBlinkIntervalNotMounted

suspendCallback(wakeUpEnabled):
  ledBlinkInterval = LedBlinkIntervalSuspended

resumeCallback:
  ledBlinkInterval = LedBlinkIntervalMounted

# Device descriptor callback must be defined
setDeviceDescriptor:
  UsbDeviceDescriptor(
    len: sizeof(UsbDeviceDescriptor).uint8,
    descType: UsbDescriptorType.device,
    binCodeUsb: 0x0200,

    # These class/subclass/protocol values required for CDC
    # See TinyUSB examples for more info.
    class: UsbDeviceClass.misc,
    subclass: UsbMiscSubclass.common,
    protocol: UsbMiscProtocol.iad,

    maxPacketSize: 64'u8,  # Must match CFG_TUD_ENDPOINT0_SIZE value in tusb_config.h
    vendorId: 0xCAFE,
    productId: 0x4005,
    binaryCodeDev: 0x0100,
    manufacturer: 1,       # index of manufacturer name in string descriptors array
    product: 2,            # index of product name in string descriptors array
    serialNumber: 3,       # index of serial no. in string descriptors array
    numConfigurations: 1
  )


# Tasks

proc blinkLedTask(elapsed: TimestampMicros) =
  var
    nextChange {.global.} = ledBlinkInterval * 1000
    ledState {.global.}: bool

  if nextChange > elapsed:
    nextChange = nextChange - elapsed
  else:
    DefaultLedPin.put (if ledState: Low else: High)
    ledState = not ledState
    nextChange = ledBlinkInterval * 1000


proc cdcEchoTask(elapsed: TimestampMicros) =
  if usbser.available > 0:
    let s = usbser.readString(256)
    if s.len > 0:
      usbser.writeLine("echo: " & s)


# Initialization

proc setup() =
  ledBlinkInterval = LedBlinkIntervalNotMounted

  DefaultLedPin.init()
  DefaultLedPin.setDir(Out)

  # TinyUSB initialization
  boardInit()
  usbInit()


# Main function

proc main() =
  setup()

  var prevTime: TimestampMicros = 0

  while true:
    # Need to call this often to respond to USB events
    usbDeviceTask()

    let
      now = timeUs64()
      dt = now - prevTime
    prevTime = now

    blinkLedTask(dt)
    cdcEchoTask(dt)


main()
