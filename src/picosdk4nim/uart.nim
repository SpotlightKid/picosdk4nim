import hidecmakelinkerpkg/libconf
import bitops
import ./gpio

initLibParams(linkLibraries = ["hardware_uart"]).config()

{.push header: "hardware/uart.h".}

type
  UartInst* {.importc: "uart_inst_t".} = object

let
  uart0* {.importc: "uart0".}: ptr UartInst
  uart1* {.importc: "uart1".}: ptr UartInst


#/**
# * \def UART_FUNCSEL_NUM(uart, gpio)
# * \ingroup hardware_uart
# * \hideinitializer
# * \brief Returns \ref gpio_function_t needed to select the UART function for the given UART instance on the given GPIO number.
# *
# * Note this macro is intended to resolve at compile time, and does no parameter checking
# */
#ifndef UART_FUNCSEL_NUM
#if PICO_RP2040
#define UART_FUNCSEL_NUM(uart, gpio) GPIO_FUNC_UART
#else
#define UART_FUNCSEL_NUM(uart, gpio) ((gpio) & 0x2 ? GPIO_FUNC_UART_AUX : GPIO_FUNC_UART)
#endif
#endif
#proc UART_FUNCSEL_NIM*(uart: ptr UartInst, pin: Gpio): GpioFunction =
#  if testBit(cast[int](pin), 1):
#    return UART_AUX
#  else:
#    return UART


proc getIndex*(uart: ptr UartInst): cuint {.importc: "uart_get_index".}
proc init*(uart: ptr UartInst; baudrate: cuint) {.importc: "uart_init".}
proc deinit*(uart: ptr UartInst) {.importc: "uart_deinit".}
proc setIrqEnables*(uart: ptr UartInst; rx_has_data, tx_needs_data: bool) {.importc: "uart_set_irq_enables".}
proc isEnabled*(uart: ptr UartInst): bool {.importc: "uart_is_enabled".}
proc isWritable*(uart: ptr UartInst): bool {.importc: "uart_is_writable".}
proc isReadable*(uart: ptr UartInst): bool {.importc: "uart_is_readable".}
proc isReadableWithinUS*(uart: ptr UartInst; us: uint32): bool {.importc: " uart_is_readable_within_us".}
proc writeBlocking*(uart: ptr UartInst; dst: ptr uint8; len: csize_t) {.importc: "uart_write_blocking".}
proc readBlocking*(uart: ptr UartInst; dst: ptr uint8; len: csize_t) {.importc: "uart_read_blocking".}
proc putcRaw*(uart: ptr UartInst; c: cchar) {.importc: "uart_putc_raw".}
proc putc*(uart: ptr UartInst; c: cchar) {.importc: "uart_putc".}
proc puts*(uart: ptr UartInst; s: cstring) {.importc: "uart_puts".}
proc getc*(uart: ptr UartInst): cchar {.importc: "uart_getc".}

# Wait for the default UART'S TX fifo to be drained.
proc defaultTxWaitBlocking*(){.importC: "uart_default_tx_wait_blocking".} 

{.pop.}
