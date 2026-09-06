# CNN_AI_Chip
# CNN-Based Image Recognition Digital Chip (RTL v0.1)

A synthesizable SystemVerilog RTL implementation of a convolutional neural network (CNN) inference engine for image classification (e.g., 13×13 handwritten-digit-like patterns). The design realizes a single-chip, serial-input pipeline: **serial I/O → convolution → quantization → max pooling → fully-connected layer → output quantization → 8-bit result**. Both network weights and input images are streamed into the chip through a 9-bit constrained port.

## Highlights

- **Network topology**: 13×13×9-bit input → 3×3 convolution (stride = 2) → 6×6 feature map → quantization (truncation + saturation + ReLU) → 2×2 max pooling (stride = 2) → 3×3 feature map → fully-connected layer (3 output neurons) → quantization → 8-bit signed result
- **Serial input constraint**: only 9 bits can be driven into the chip per clock cycle; a full 169-pixel image therefore requires at least 169 cycles to load
- **Weight provisioning**: 58 bytes of 8-bit weights streamed serially (27 convolution weights + 3 convolution biases + 27 FC weights + 1 FC bias)
- **Resource-efficient datapath**: convolution and FC MAC units are time-multiplexed (register-/combinational-shared arithmetic), targeting a compact silicon footprint
- **IP-free, synthesizable RTL** with no third-party dependencies

## Top-Level Interface (`top_AI`)

| Signal | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | System clock |
| `RSTN` | input | 1 | Asynchronous reset, active-low |
| `mode` | input | 1 | `0` = weight-loading mode, `1` = image-loading mode |
| `input_pin_0..7` | input | 8 | Form the 8-bit weight byte during weight loading (LSB first) |
| `input_pin_0..8` | input | 9 | Form the 9-bit signed pixel during image loading |
| `result` | output | 8 | Classification result, signed |
| `out_data_flag` | output | 1 | Result-valid strobe (single-cycle pulse) |

## Usage / Operational Flow

1. Assert `mode = 0` and stream the 58 weight bytes sequentially in the following order:
   - 27 convolution weights → 3 convolution biases → 27 FC weights → 1 FC bias;
2. Assert `mode = 1` and stream the 169 9-bit pixels of the image, row by row (13 per row);
3. The pipeline autonomously executes convolution, quantization, pooling, FC, and output quantization;
4. When `out_data_flag` is asserted, sample `result` — the classification outcome for the current image.

## Architecture & Data Flow

```
                 ┌──────────────────────────────────────────────┐
                 │             control (pipeline scheduler)     │
                 └──────┬──────┬──────┬──────┬──────┬───────────┘
                        ▼      ▼      ▼      ▼      ▼
 read → ConvU → quanti → MAX_Pool → fc → fc_reg → fc_result → quanti_fc → result
(serial  (3×3 conv  (qnt.+   (2×2 max   (FC dot  (3-result  (sum + FC   (final     + out_data_flag
 input)   stride 2)  ReLU)    pooling)  product) buffer)    bias)        qnt.)
```

### Module Description

| File | Module | Function |
|---|---|---|
| `top_AI.sv` | `top_AI` | Top level; instantiates and interconnects all submodules |
| `read.sv` | `read` | Serial I/O controller: weight/image acquisition, convolution revisit row shifting, weight-slice rotation |
| `control.sv` | `control` | Pipeline scheduler; cascades per-stage `done` signals into downstream `start` enables |
| `ConvU.sv` | `ConvU` | 3×3 convolution unit (stride = 2); 9 multiply-accumulates plus bias; 20-bit accumulation |
| `quanti.sv` | `quanti` | Intermediate quantization: truncation of the 20-bit accumulator, saturation to [-128, 127], negative clamping to 0 (ReLU) |
| `MAX_Pool.sv` | `MAX_Pool` | 2×2 max pooling (stride = 2); 6×6 → 3×3 |
| `fc.sv` | `fc` | Fully-connected dot product: 9 pooled values × 9 weights; 21-bit accumulation |
| `fc_reg.sv` | `fc_reg` | Sequentially latches the three FC results (three output neurons) |
| `fc_result.sv` | `fc_result` | Sums the three neuron results and adds the FC bias |
| `quanti_fc.sv` | `quanti_fc` | Final quantization: truncation, saturation, and negative clamping of the 21-bit value to 8-bit |

## Numerical Precision Chain

```
9-bit image → 20-bit conv accumulation → 8-bit quantize → 8-bit pool
           → 21-bit FC accumulation → 8-bit final quantize (result)
```

## Repository Layout

```
.
├── top_AI.sv      # Top level
├── read.sv        # Serial input controller
├── control.sv     # Pipeline scheduling
├── ConvU.sv       # Convolution unit
├── quanti.sv      # Post-convolution quantization
├── MAX_Pool.sv    # Max pooling
├── fc.sv          # Fully-connected layer
├── fc_reg.sv      # FC result buffer
├── fc_result.sv   # FC accumulation & bias
├── quanti_fc.sv   # Final quantization
└── README.md
```

## Simulation & Synthesis

- **Language**: SystemVerilog (synthesizable subset)
- **Simulators**: Vivado Simulator / ModelSim / QuestaSim / Verilator / Icarus Verilog
- **Synthesis flow**: Vivado / Quartus / Design Compiler (FPGA or standard-cell ASIC flow at 65 nm-class nodes)
- **Verification checkpoint**: sample `result` when `out_data_flag` is asserted; cross-check against a fixed-point reference model (e.g., MATLAB/Python end-to-end float → fixed-point simulation)

> Note: testbench and golden reference vectors are not included in this repository yet; they will be added in subsequent revisions.

## Version Notes (v0.1 — Initial Release)

- The full functional chain is in place (weight loading → inference → result output) and matches the stated interface specification;
- Known items targeted for improvement (none blocks functional bring-up at this revision):
  - Per-stage `start` signals in `control` are generated through combinational cascades of `done` flags; the resulting timing path is long and will be re-timed with register buffering;
  - Several modules contain boundary indices / reset-timing concerns;
  - Compute parallelism and pipeline depth will be iterated for PPA optimization, guided by the 169-cycle-per-image throughput target implied by the serial input constraint.

## License

Not yet specified.
