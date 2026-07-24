# Synthesis Report — Async FIFO

## Result: 112 cells, zero errors

| Cell type | Count |
|---|---|
| Flip-flops (`$_DFF_PN0_`, `$_DFF_P_`) | 46 |
| Memory (`$memrd`/`$memwr_v2`) | 1 (128 bits = 16×8) |
| Multiplexers | 12 |
| AND/OR/NOT/XOR | 52 |

## Per-module breakdown
- `gray_ptr` (×2 instances): 23 cells each — dominated by XOR (Gray conversion) and DFFs (pointer registers)
- `sync2ff` (×2 instances): 10 cells each — pure flip-flops, no combinational logic (as expected for a synchronizer)
- `dual_port_mem` (×1): 22 cells — the inferred RAM plus registered read-output flops

## Interpretation
Yosys correctly inferred the storage array as a proper memory primitive rather than expanding it into individual flip-flops — confirms the design describes RAM-like storage in a synthesis-friendly way. Zero inferred latches confirms fully synchronous, clean logic throughout.