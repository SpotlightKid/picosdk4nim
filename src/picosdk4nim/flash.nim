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
initLibParams(linkLibraries = ["pico_flash"]).config()

{.push header: "hardware/flash.h".}


let tFlashBinaryStart {.importc: "__flash_binary_start".}: cchar
let tFlashBinaryEnd {.importc: "__flash_binary_end".}: cchar
template FlashBinaryStart*: untyped = cast[cuint](tFlashBinaryStart.unsafeAddr)
template FlashBinaryEnd*: untyped = cast[cuint](tFlashBinaryEnd.unsafeAddr)


let
  FlashPageSize* {.importc: "FLASH_PAGE_SIZE".}: cuint
  FlashSectorSize* {.importc: "FLASH_SECTOR_SIZE".}: cuint
  FlashBlockSize* {.importc: "FLASH_BLOCK_SIZE".}: cuint
  FlashUniqueIdSizeBytes* {.importc: "FLASH_UNIQUE_ID_SIZE_BYTES".}: cuint

proc flashRangeErase*(flashOffs: uint32; count: cuint) {.importc: "flash_range_erase".}
  ## Erase areas of flash
  ##
  ## \param flash_offs Offset into flash, in bytes, to start the erase. Must be aligned to a 4096-byte flash sector.
  ## \param count Number of bytes to be erased. Must be a multiple of 4096 bytes (one sector).
  ##
  ## @note Erasing a flash sector sets all the bits in all the pages in that sector to one.
  ## You can then "program" flash pages in the sector to turn some of the bits to zero.
  ## Once a bit is set to zero it can only be changed back to one by erasing the whole sector again.

proc flashRangeProgram*(flashOffs: uint32; data: ptr uint8; count: cuint) {.importc: "flash_range_program".}
  ## Program flash
  ##
  ## \param flash_offs Flash address of the first byte to be programmed. Must be aligned to a 256-byte flash page.
  ## \param data Pointer to the data to program into flash
  ## \param count Number of bytes to program. Must be a multiple of 256 bytes (one page).
  ##
  ## @note: Programming a flash page effectively changes some of the bits from one to zero.
  ## The only way to change a zero bit back to one is to "erase" the whole sector that the page resides in.
  ## So you may need to make sure you have called flash_range_erase before calling flash_range_program.


proc flashGetUniqueId*(idOut: ptr uint8) {.importc: "flash_get_unique_id".}
  ## Get flash unique 64 bit identifier
  ##
  ## Use a standard 4Bh RUID instruction to retrieve the 64 bit unique
  ## identifier from a flash device attached to the QSPI interface. Since there
  ## is a 1:1 association between the MCU and this flash, this also serves as a
  ## unique identifier for the board.
  ##
  ## \param id_out Pointer to an 8-byte buffer to which the ID will be written

proc flashDoCmd*(txbuf: ptr uint8; rxbuf: ptr uint8; count: cuint) {.importc: "flash_do_cmd".}
  ## Execute bidirectional flash command
  ##
  ## Low-level function to execute a serial command on a flash device attached
  ## to the QSPI interface. Bytes are simultaneously transmitted and received
  ## from txbuf and to rxbuf. Therefore, both buffers must be the same length,
  ## count, which is the length of the overall transaction. This is useful for
  ## reading metadata from the flash chip, such as device ID or SFDP
  ## parameters.
  ##
  ## The XIP cache is flushed following each command, in case flash state
  ## has been modified. Like other hardware_flash functions, the flash is not
  ## accessible for execute-in-place transfers whilst the command is in
  ## progress, so entering a flash-resident interrupt handler or executing flash
  ## code on the second core concurrently will be fatal. To avoid these pitfalls
  ## it is recommended that this function only be used to extract flash metadata
  ## during startup, before the main application begins to run: see the
  ## implementation of pico_get_unique_id() for an example of this.
  ##
  ## \param txbuf Pointer to a byte buffer which will be transmitted to the flash
  ## \param rxbuf Pointer to a byte buffer where data received from the flash will be written. txbuf and rxbuf may be the same buffer.
  ## \param count Length in bytes of txbuf and of rxbuf

proc flashFlushCache*() {.importc: "flash_flush_cache".}

{.pop.}


{.push header: "pico/flash.h".}

type
  FlashSafetyHelper* {.importc: "flash_safety_helper_t".} = object
    coreInitDeinit* {.importc: "core_init_deinit".}: proc (init: bool): bool
    enterSafeZoneTimeoutMs* {.importc: "enter_safe_zone_timeout_ms".}: proc (timeoutMs: uint32): cint
    exitSafeZoneTimeoutMs* {.importc: "exit_safe_zone_timeout_ms".}: proc (timeoutMs: uint32): cint

proc flashSafeExecuteCoreInit*(): bool {.importc: "flash_safe_execute_core_init".}
  ## Initialize a core such that the other core can lock it out during \ref flash_safe_execute.
  ##
  ## \note This is not necessary for FreeRTOS SMP, but should be used when launching via \ref multicore_launch_core1
  ## \return true on success; there is no need to call \ref flash_safe_execute_core_deinit() on failure.

proc flashSafeExecuteCoreDeinit*(): bool {.importc: "flash_safe_execute_core_deinit".}
  ## De-initialize work done by \ref flash_safe_execute_core_init
  ##
  ## \return true on success

proc flashSafeExecute*(`func`: proc (param: pointer) {.cdecl.}; param: pointer; enterExitTimeoutMs: uint32): cint {.importc: "flash_safe_execute".}
  ## Execute a function with IRQs disabled and with the other core also not executing/reading flash
  ##
  ## \param func the function to call
  ## \param param the parameter to pass to the function
  ## \param enter_exit_timeout_ms the timeout for each of the enter/exit phases when coordinating with the other core
  ##
  ## \return PICO_OK on success (the function will have been called).
  ##         PICO_TIMEOUT on timeout (the function may have been called).
  ##         PICO_ERROR_NOT_PERMITTED if safe execution is not possible (the function will not have been called).
  ##         PICO_ERROR_INSUFFICIENT_RESOURCES if the method fails due to dynamic resource exhaustion (the function will not have been called)
  ## \note if \ref PICO_FLASH_ASSERT_ON_UNSAFE is 1, this function will assert in debug mode vs returning
  ##       PICO_ERROR_NOT_PERMITTED

proc getFlashSafetyHelper*(): ptr FlashSafetyHelper {.importc: "get_flash_safety_helper".}
  ## Internal method to return the flash safety helper implementation.
  ##
  ## Advanced users can provide their own implementation of this function to perform
  ## different inter-core coordination before disabling XIP mode.
  ##
  ## @return the \ref flash_safety_helper_t

{.pop.}
