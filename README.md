# CDC-Safe Asynchronous FIFO

A parameterized asynchronous FIFO safely bridging two independent, unrelated clock domains using Gray-coded pointers and 2-flip-flop synchronizers.

## Why this project

Real chips constantly move data between blocks running at different, unrelated clock frequencies (e.g., a 100MHz CPU writing to a 33MHz sensor interface). Doing this safely — without metastability corrupting data — is one of the most fundamental and most-interviewed topics in digital design.

## Architecture

Write domain (wclk)              Read domain (rclk)
    write pointer   ──gray code──▶  2FF synchronizer (empty check)
    (Gray-coded)

    2FF synchronizer (full check)  ◀──gray code──  read pointer
                                                    (Gray-coded)

                both sides share: dual-port memory


## Key design decisions (interview talking points)

- **Why Gray code, not binary, for the pointers?** A binary counter can change multiple bits at once on a single increment (e.g. `011→100`). If a synchronizer samples mid-transition, it could catch a corrupted mix of old and new bits. Gray code guarantees exactly one bit changes per increment.
- **Why 2 flip-flops, not 1?** The first flop may go metastable sampling a signal with no fixed timing relationship to its clock. The second flop, one cycle later, samples the (by-then-resolved) output — trading 2 cycles of latency for guaranteed safety.
- **Why is the pointer one bit wider than needed to address the memory?** Without it, "full" and "empty" look numerically identical (write pointer == read pointer in both cases). The extra MSB distinguishes "nothing written" from "write pointer wrapped exactly once more than read pointer."
- **Registered memory read**: costs 1 cycle of latency but matches real SRAM/BRAM behavior and avoids read-during-write glitches.

## Verification

Tested with **two genuinely unrelated clock periods** (`wclk`=10ns, `rclk`=7ns) to realistically stress the CDC logic: filled the FIFO completely (confirmed `wfull`), confirmed writes ignored while full, drained all 16 entries from the independent read domain with every value correct and in order, confirmed `rempty` after drain. **18/18 checks pass.**

## How to run

\`\`\`bash
iverilog -o sim/fifo_sim.vvp rtl/gray_ptr.v rtl/sync2ff.v rtl/dual_port_mem.v rtl/async_fifo.v tb/async_fifo_tb.v
vvp sim/fifo_sim.vvp
\`\`\`

## Synthesis

Synthesized cleanly with Yosys: 112 cells total (46 flip-flops, 1 inferred 128-bit memory, 12 muxes, remainder combinational). See `docs/SYNTHESIS_REPORT.md`.

## Files
- `rtl/gray_ptr.v` — binary + Gray-code pointer generator
- `rtl/sync2ff.v` — 2-flip-flop CDC synchronizer
- `rtl/dual_port_mem.v` — dual-port FIFO storage
- `rtl/async_fifo.v` — top-level module
- `tb/async_fifo_tb.v` — testbench with two independent clocks
- `synth/synth.ys` — Yosys synthesis script               