# slightly modified code from https://github.com/daniel-j/picostdlib
# which has the following licence:
#  BSD-3-Clause License
# Copyright (c) 2021 Jason Beetham
# Copyright (c) 2022-2023 Daniel Jönsson

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
# following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
#    disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
#    disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
#    derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import hidecmakelinkerpkg/libconf

initLibParams(linkLibraries = ["pico_platform"]).config()

{.push header: "pico/platform.h".}

let
  XipBase* {.importc: "XIP_BASE".}: uint32
  XipMainBase* {.importc: "XIP_MAIN_BASE".}: uint32
  XipNoallocBase* {.importc: "XIP_NOALLOC_BASE".}: uint32
  XipNocacheBase* {.importc: "XIP_NOCACHE_BASE".}: uint32
  XipNocacheNoallocBase* {.importc: "XIP_NOCACHE_NOALLOC_BASE".}: uint32

proc breakpoint*() {.importc: "__breakpoint".}
  ## Execute a breakpoint instruction

proc compilerMemoryBarrier*() {.importc: "__compiler_memory_barrier".}
  ## Ensure that the compiler does not move memory access across this method call
  ##
  ## For example in the following code:
  ##
  ##    some_memory_location = var_a;
  ##     __compiler_memory_barrier();
  ##     uint32_t var_b =some_other_memory_location
  ##
  ## The compiler will not move the load from some_other_memory_location above the memory barrier (which it otherwise
  ## might - even above the memory store!)

proc panicUnsupported*() {.importc: "panic_unsupported".}
  ## Panics with the message "Unsupported"
  ## \see panic

proc panic*(fmt: cstring) {.importc: "panic", varargs.}
  ## Displays a panic message and halts execution
  ##
  ## An attempt is made to output the message to all registered STDOUT drivers
  ## after which this method executes a BKPT instruction.
  ##
  ## @param fmt format string (printf-like)
  ## @param ...  printf-like arguments

proc rp2040ChipVersion*(): uint8 {.importc: "rp2040_chip_version".}
  ## Returns the RP2040 chip revision number
  ## @return the RP2040 chip revision number (1 for B0/B1, 2 for B2)

proc rp2040RomVersion*(): uint8 {.importc: "rp2040_rom_version".}
  ## Returns the RP2040 rom version number
  ## @return the RP2040 rom version number (1 for RP2040-B0, 2 for RP2040-B1, 3 for RP2040-B2)

proc tightLoopContents*() {.importc: "tight_loop_contents".}
  ## No-op function for the body of tight loops
  ##
  ## No-op function intended to be called by any tight hardware polling loop. Using this ubiquitously
  ## makes it much easier to find tight loops, but also in the future \#ifdef-ed support for lockup
  ## debugging might be added

proc mulInstruction*(a: int32; b: int32): int32 {.importc: "__mul_instruction".}
  ## Multiply two integers using an assembly MUL instruction
  ##
  ## This multiplies a by b using multiply instruction using the ARM mul instruction regardless of values (the compiler
  ## might otherwise choose to perform shifts/adds), i.e. this is a 1 cycle operation.
  ##
  ## \param a the first operand
  ## \param b the second operand
  ## \return a b

proc picoGetCurrentException*(): cuint {.importc: "__get_current_exception".}
  ## Get the current exception level on this core
  ##
  ## \return the exception number if the CPU is handling an exception, or 0 otherwise

proc busyWaitAtLeastCycles*(minimumCycles: uint32) {.importc: "busy_wait_at_least_cycles".}
  ## Helper method to busy-wait for at least the given number of cycles
  ##
  ## This method is useful for introducing very short delays.
  ##
  ## This method busy-waits in a tight loop for the given number of system clock cycles. The total wait time is only accurate to within 2 cycles,
  ## and this method uses a loop counter rather than a hardware timer, so the method will always take longer than expected if an
  ## interrupt is handled on the calling core during the busy-wait; you can of course disable interrupts to prevent this.
  ##
  ## You can use \ref clock_get_hz(clk_sys) to determine the number of clock cycles per second if you want to convert an actual
  ## time duration to a number of cycles.
  ##
  ## \param minimum_cycles the minimum number of system clock cycles to delay for

proc getCoreNum*(): cuint {.importc: "get_core_num".}
  ## Get the current core number
  ##
  ## \return The core number the call was made from
  ## 

{.pop.}