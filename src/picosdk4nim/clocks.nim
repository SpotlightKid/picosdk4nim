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

initLibParams(linkLibraries = ["pico_stdlib"]).config()


{.push header: "hardware/clocks.h".}

proc setSysClock48mhz*() {.importc: "set_sys_clock_48mhz".}
  ## Initialise the system clock to 48MHz
  ##
  ## Set the system clock to 48MHz, and set the peripheral clock to match.

proc setSysClockPll*(vcoFreq: uint32; postDiv1, postDiv2: cuint) {.importc: "set_sys_clock_pll".}
  ## Initialise the system clock
  ##
  ## \param vco_freq The voltage controller oscillator frequency to be used by the SYS PLL
  ## \param post_div1 The first post divider for the SYS PLL
  ## \param post_div2 The second post divider for the SYS PLL.
  ##
  ## See the PLL documentation in the datasheet for details of driving the PLLs.

proc checkSysClockKhz*(freqKhz: uint32; vcoFreqOut, postDiv1Out, postDiv2Out: ptr cuint): bool {.importc: "check_sys_clock_khz".}
  ## Check if a given system clock frequency is valid/attainable
  ##
  ## \param freq_khz Requested frequency
  ## \param vco_freq_out On success, the voltage controlled oscillator frequency to be used by the SYS PLL
  ## \param post_div1_out On success, The first post divider for the SYS PLL
  ## \param post_div2_out On success, The second post divider for the SYS PLL.
  ## @return true if the frequency is possible and the output parameters have been written.

proc setSysClockKhz*(freqKhz: uint32; required: bool): bool {.importc: "set_sys_clock_khz".}
  ## Attempt to set a system clock frequency in khz
  ##
  ## Note that not all clock frequencies are possible; it is preferred that you
  ## use src/rp2_common/hardware_clocks/scripts/vcocalc.py to calculate the parameters
  ## for use with set_sys_clock_pll
  ##
  ## \param freq_khz Requested frequency
  ## \param required if true then this function will assert if the frequency is not attainable.
  ## \return true if the clock was configured

{.pop.}
