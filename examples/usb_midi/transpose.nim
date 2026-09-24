## Configure Pico into a USB MIDI device, which echos received MIDI notes transposed by one octave up

import std/os
import picosdk4nim
import picosdk4nim/[gpio, stdio, time, tusb]
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


# Globals

type TimestampMicros = uint64

const
  LedBlinkIntervalNotMounted = 250'u64
  LedBlinkIntervalMounted = 1000'u64
  LedBlinkIntervalSuspended = 2500'u64
  midi = 0.MidiInterface
  cable = 0.MidiCable
  transpose: uint8 = 12

var ledBlinkInterval: uint64 # ms
var notes: array[128, uint16]


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

    class: UsbDeviceClass.unspecified,
    subclass: UsbMiscSubclass.none,
    protocol: UsbMiscProtocol.none,

    maxPacketSize: 64'u8,  # Must match CFG_TUD_ENDPOINT0_SIZE value in tusb_config.h
    vendorId: 0xCAFE,
    productId: 0x4006,
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


proc midiTask(elapsed: TimestampMicros) =
  var packet: array[4, uint8]

  while midi.available() > 0:
    if midi.readPacket(packet):
      echo "RECV: " & $packet
      let status = packet[1] and 0xF0

      case status
      of 0x80..0xA0:
        let
          note = clamp(packet[2] + transpose, 0, 127)
          channel = packet[1] and 0xF

        if (status == 0x80 and (notes[note] and (1.uint16 shl channel.uint16)) == 0) or (
            status == 0x90 and (notes[note] and (1.uint16 shl channel.uint16)) == 1):
          return

        if status == 0x80:
          notes[note] = notes[note] and not (1.uint16 shl channel.uint16)
        elif status == 0x90:
          notes[note] = notes[note] or (1.uint16 shl channel.uint16)

        midi.write(packet[1], note, packet[3], cable)
      else:
        discard


# Initialization

proc setup() =
  ledBlinkInterval = LedBlinkIntervalNotMounted

  DefaultLedPin.init()
  DefaultLedPin.setDir(Out)

  # TinyUSB initialization
  boardInit()
  usbInit()

  stdioInitAll()

  for i in 0..notes.high:
    notes[i] = 0


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
    midiTask(dt)


main()
