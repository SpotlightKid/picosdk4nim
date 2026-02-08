import hidecmakelinkerpkg/libconf

initLibParams(linkLibraries = ["pico_platform"]).config()

{.push header: "pico/platform.h".}


#/*! \brief Helper method to busy-wait for at least the given number of cycles
# *  \ingroup pico_platform
# *
# * This method is useful for introducing very short delays.
# *
# * This method busy-waits in a tight loop for the given number of system clock cycles. The total wait time is only accurate to within 2 cycles,
# * and this method uses a loop counter rather than a hardware timer, so the method will always take longer than expected if an
# * interrupt is handled on the calling core during the busy-wait; you can of course disable interrupts to prevent this.
# *
# * You can use \ref clock_get_hz(clk_sys) to determine the number of clock cycles per second if you want to convert an actual
# * time duration to a number of cycles.
# *
# * \param minimum_cycles the minimum number of system clock cycles to delay for
# */
proc busyWaitAtLeastCycles*(minimum_cycles: uint32) {.importC: "busy_wait_at_least_cycles".}

