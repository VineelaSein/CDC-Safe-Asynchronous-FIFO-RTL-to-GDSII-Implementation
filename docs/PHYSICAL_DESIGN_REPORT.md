# Physical Design Report — CDC-Safe Async FIFO

## Flow
OpenLane 2 (Classic flow), SkyWater SKY130 PDK, `sky130_fd_sc_hd` standard cell library, run inside Docker.

## Multi-clock handling
This design has two independent, asynchronous clocks (`wclk`, `rclk`). A custom SDC file (`fifo.sdc`) defines both clocks and explicitly marks them as an asynchronous clock group:

\`\`\`
create_clock -name wclk -period 10 [get_ports wclk]
create_clock -name rclk -period 7  [get_ports rclk]
set_clock_groups -asynchronous -group {wclk} -group {rclk}
\`\`\`

This tells the static timing analyzer not to attempt (meaningless) timing checks between the two domains — correctness across the boundary is guaranteed structurally by the 2-flop synchronizers, not by timing closure.

## Results

| Stage | Result |
|---|---|
| Synthesis | Clean, 0 lint errors |
| Floorplan | Die 130.3 × 141.0 µm, 55.65% core utilization |
| Placement | 709 standard cells, 0 macros |
| Clock Tree Synthesis | Independent trees for wclk and rclk, worst skew ≤0.016ns |
| Global + Detailed Routing | 13,858 µm total wirelength, 0 DRC errors (converged from 235 in iteration 1) |
| Static Timing Analysis | 0 setup violations, 0 hold violations, across all 9 PVT corners |
| Antenna Check | 0 violations |
| LVS | Clean match — layout electrically identical to source netlist |
| Power | 3.60 mW total (2.44mW internal, 1.16mW switching, negligible leakage) |

## Interpretation
- Positive setup slack (+2.0ns worst-case) at the specified clock periods indicates timing margin — the design could likely be clocked faster if required.
- Sub-20ps worst-case clock skew on both domains reflects effective clock tree balancing by OpenROAD's CTS engine, run independently per clock domain.
- Zero DRC/LVS/antenna violations confirms the GDSII output (`async_fifo.gds`) is a genuinely manufacturable layout under the SKY130 process rules.

## Files
- `config.json` — OpenLane flow configuration
- `fifo.sdc` — custom timing constraints (dual async clocks)
- `runs/<run-id>/final/gds/async_fifo.gds` — final manufacturable layout (not committed to git — large binary artifact, regenerate via `openlane --dockerized config.json`)
- `runs/<run-id>/final/metrics.csv` — full metrics dump from the flow
xs