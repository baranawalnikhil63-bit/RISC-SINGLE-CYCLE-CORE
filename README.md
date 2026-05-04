# RISC-SINGLE-CYCLE-CORE

A fully functional 32-bit single cycle RISC-V processor implemented in Verilog HDL, supporting a subset of the RV32I instruction set. Designed and simulated using Icarus Verilog and GTKWave.

---

## Table of Contents

- [Overview](#overview)
- [Supported Instructions](#supported-instructions)
- [Architecture](#architecture)
- [Module Description](#module-description)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Simulation Results](#simulation-results)
- [Waveform Signals](#waveform-signals)
- [Tools Used](#tools-used)

---

## Overview

This project implements a single cycle RISC-V processor where every instruction completes in exactly one clock cycle. The datapath includes an ALU, register file, instruction memory, data memory, control unit, sign extender, and all necessary multiplexers and adders. Branch instructions are fully supported with a dedicated branch adder and PC mux.

---

## Supported Instructions

| Type | Instructions | Opcode |
|---|---|---|
| R-type | ADD, SUB, AND, OR, SLT | `0110011` |
| I-type (Load) | LW | `0000011` |
| S-type (Store) | SW | `0100011` |
| B-type (Branch) | BEQ | `1100011` |

---

## Architecture

```
        ┌─────────────────────────────────────────────────────────┐
        │                                                         │
  ┌─────▼──────┐    ┌──────────┐    ┌─────────────┐             │
  │     PC     │───►│  Instr   │───►│   Control   │             │
  └─────┬──────┘    │  Memory  │    │    Unit     │             │
        │           └──────────┘    └──────┬──────┘             │
        │                                  │                     │
  ┌─────▼──────┐    ┌──────────┐    ┌──────▼──────┐             │
  │   PC + 4   │    │  Register│◄───│  Sign       │             │
  │  (Adder)   │    │   File   │    │  Extend     │             │
  └─────┬──────┘    └────┬─────┘    └─────────────┘             │
        │                │                                       │
        │           ┌────▼─────┐    ┌─────────────┐             │
        │           │  ALU Src │───►│    ALU      │             │
        │           │   Mux    │    └──────┬──────┘             │
        │           └──────────┘           │                     │
        │                           ┌──────▼──────┐             │
        │                           │    Data     │             │
  ┌─────▼──────┐                    │   Memory    │             │
  │  Branch    │                    └──────┬──────┘             │
  │  Adder     │                           │                     │
  └─────┬──────┘                    ┌──────▼──────┐             │
        │                           │  Result Mux │─────────────┘
  ┌─────▼──────┐                    └─────────────┘
  │   PC Mux   │
  └────────────┘
```

---

## Module Description

### `ALU.v`
Performs all arithmetic and logic operations. Takes two 32-bit inputs and a 3-bit control signal. Supports ADD, SUB, AND, OR, and SLT. Produces four status flags: Zero, Negative, Carry, and OverFlow.

| ALUControl | Operation |
|---|---|
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `101` | SLT (Set Less Than) |

### `Main_Decoder.v`
Decodes the 7-bit opcode and generates all datapath control signals: RegWrite, ALUSrc, MemWrite, ResultSrc, Branch, ImmSrc, and ALUOp.

### `ALU_Decoder.v`
Takes ALUOp from Main_Decoder along with funct3 and funct7 fields to generate the final 3-bit ALUControl signal for the ALU.

### `Control_Unit_Top.v`
Top-level control module that instantiates both Main_Decoder and ALU_Decoder, providing a single interface for the entire control path.

### `Sign_Extend.v`
Sign-extends 12-bit or 13-bit immediate values to 32 bits. Handles three immediate formats:
- **I-type**: bits [31:20]
- **S-type**: bits [31:25] and [11:7]
- **B-type**: bits [31], [7], [30:25], [11:8] with LSB forced to 0

### `Register_File.v`
Contains 32 general-purpose 32-bit registers (x0–x31). Supports two simultaneous read ports and one write port. Reads are asynchronous; writes are synchronous on the rising clock edge.

### `Instruction_Memory.v`
Read-only memory that stores the program. Uses word addressing (`A[31:2]`). Program is loaded from `memfile.hex` at simulation start.

### `Data_Memory.v`
Read/write memory for load and store instructions. Uses word-aligned addressing (`A[11:2]`). Writes are synchronous; reads are asynchronous.

### `PC_Module.v`
Holds the current program counter. Updates on every rising clock edge to `PC_Next`. Resets to zero on active-low reset.

### `PC_Adder.v`
Simple 32-bit adder used in two places: computing PC+4 for sequential execution, and computing the branch target address PC+Immediate.

### `Mux.v`
2-to-1 multiplexer used throughout the datapath for selecting between register and immediate (ALUSrc), PC+4 and branch target (PC mux), and ALU result and memory data (ResultSrc).

### `Single_Cycle_Top.v`
Top-level datapath module. Instantiates and interconnects all modules. Contains no logic of its own — only wiring.

---

## Project Structure

```
Single_Cycle_RISCV/
│
├── ALU.v                  # Arithmetic Logic Unit
├── ALU_Decoder.v          # ALU control decoder
├── Main_Decoder.v         # Main control decoder
├── Control_Unit_Top.v     # Control unit wrapper
├── Sign_Extend.v          # Immediate sign extender
├── Register_File.v        # 32 x 32-bit register file
├── Instruction_Memory.v   # Program memory (ROM)
├── Data_Memory.v          # Data memory (RAM)
├── PC_Module.v            # Program counter register
├── PC_Adder.v             # PC increment and branch adder
├── Mux.v                  # 2-to-1 multiplexer
├── Single_Cycle_Top.v     # Top-level datapath
├── Single_Cycle_Top_Tb.v  # Testbench
└── memfile.hex            # Program in hex format
```

---

## Getting Started

### Prerequisites

- [Icarus Verilog](http://bleyer.org/icarus/) — Verilog compiler and simulator
- [GTKWave](http://gtkwave.sourceforge.net/) — Waveform viewer
- [VS Code](https://code.visualstudio.com/) with the **Verilog HDL** extension by mshr-h (optional, for editing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Single-Cycle-RISCV.git
cd Single-Cycle-RISCV
```

2. Make sure `memfile.hex` is in the same directory as the `.v` files.

### Compilation

```bash
iverilog -o simulation.out Single_Cycle_Top_Tb.v
```

> The testbench includes `Single_Cycle_Top.v` via `` `include ``, which in turn includes all other modules. So only the testbench needs to be passed to iverilog.

### Run Simulation

```bash
vvp simulation.out
```

Expected output:
```
Simulation started
Simulation finished
```

### View Waveforms

```bash
gtkwave Single_Cycle.vcd
```

In GTKWave, expand the hierarchy in the SST panel and drag signals into the wave window.

---

## Simulation Results

The default `memfile.hex` contains two instructions to verify correct operation:

```
@00000000
0062E3B3    → OR  x7, x5, x6
0062F433    → AND x8, x5, x6
```

With the register file initialized as:
```
x5 = 0x00000005  (decimal 5)
x6 = 0x00000004  (decimal 4)
```

Expected results after simulation:

| Instruction | Operation | Expected Result |
|---|---|---|
| `OR x7, x5, x6` | `5 \| 4` = `0101 \| 0100` | `x7 = 0x00000005` |
| `AND x8, x5, x6` | `5 & 4` = `0101 & 0100` | `x8 = 0x00000004` |

---

## Waveform Signals

Key signals to observe in GTKWave after simulation:

| Signal | Description |
|---|---|
| `clk` | Clock signal toggling every 50ns |
| `rst` | Active-low reset, goes high at 150ns |
| `PC_Top` | Program counter — advances 0 → 4 → 8 |
| `RD_Instr` | Raw instruction word fetched from memory |
| `ALUControl_Top` | 3-bit signal selecting ALU operation |
| `ALUResult` | Output of the ALU |
| `Result` | Final value written to register file |
| `RegWrite` | High when a register is being written |
| `MemWrite` | High when data memory is being written |
| `Branch` | High for branch instructions |
| `Zero` | High when ALU result is zero (used by branch) |

---

## Tools Used

| Tool | Purpose |
|---|---|
| Icarus Verilog v10+ | Compilation and simulation |
| GTKWave v3.3+ | Waveform visualization |
| VS Code | Code editing with Verilog HDL extension |

---

## Notes

- The processor uses an **active-low reset** — hold `rst = 0` to reset, set `rst = 1` to run.
- Instruction memory uses **word addressing** (`mem[A[31:2]]`), consistent with RISC-V byte-addressed memory.
- Data memory also uses **word-aligned addressing** (`mem[A[11:2]]`).
- Register `x0` is not hardwired to zero in this implementation — avoid writing to it.
- Only a subset of RV32I is supported. I-type ALU instructions (ADDI, ANDI, ORI) are not included.

---

## License

This project is open source and available under the [MIT License](LICENSE).

