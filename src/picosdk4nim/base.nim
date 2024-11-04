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

initLibParams(linkLibraries = ["hardware_base"]).config()

{.push header: "hardware/address_mapped.h".}

type
  IoRw32* {.importc: "io_rw_32".} = uint32
  IoRo32* {.importc: "io_ro_32".} = uint32
  IoWo32* {.importc: "io_wo_32".} = uint32
  IoRw16* {.importc: "io_rw_16".} = uint16
  IoRo16* {.importc: "io_ro_16".} = uint16
  IoWo16* {.importc: "io_wo_16".} = uint16
  IoRw8* {.importc: "io_rw_8".} = uint8
  IoRo8* {.importc: "io_ro_8".} = uint8
  IoWo8* {.importc: "io_wo_8".} = uint8

proc hwSetBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_set_bits".}
  ## Atomically set the specified bits to 1 in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to set
  ## =========  ======

proc hwClearBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_clear_bits".}
  ## Atomically clear the specified bits to 0 in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to clear
  ## =========  ======

proc hwXorBits*(`addr`: ptr IoRw32, mask: uint32) {.importc: "hw_xor_bits".}
  ## Atomically flip the specified bits in a HW register
  ##
  ## **Parameters:**
  ##
  ## =========  ======
  ## **addr**    Address of writable register
  ## **mask**    Bit-mask specifying bits to invert
  ## =========  ======

proc hwWriteMasked*(`addr`: ptr IoRw32, values: uint32, writeMask: uint32) {.importc: "hw_write_masked".}
  ## Set new values for a sub-set of the bits in a HW register
  ##
  ## Sets destination bits to values specified in `values`, if and only if corresponding bit in `writeMask` is set
  ##
  ## Note: this method allows safe concurrent modification of *different* bits of
  ## a register, but multiple concurrent access to the same bits is still unsafe.
  ##
  ## **Parameters:**
  ##
  ## ==============  ======
  ## **addr**         Address of writable register
  ## **values**       Bits values
  ## **writeMask**    Mask of bits to change
  ## ==============  ======

{.pop.}