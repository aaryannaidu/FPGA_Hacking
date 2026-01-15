# Vector Addition with Memory 🧬

A hardware-based vector addition system implemented on FPGA. This project manages three memory blocks (ROM for Vector A, RAM for Vector B, and RAM for Vector C) to perform and store real-time vector additions.

## 🎮 Overview

The project implements a memory-mapped calculator that computes `Vector C = Vector A + Vector B`. 
- **Vector A**: Stored in a ROM (Read-Only Memory).
- **Vector B**: Stored in a RAM (Random Access Memory), allowing user updates.
- **Vector C**: Stored in a RAM, automatically updated whenever Vector B is modified to maintain the invariant `C = A + B`.

Each vector consists of **1024 elements** (10-bit addressing), where each element in A and B is **4 bits** wide, and elements in C are **5 bits** wide to accommodate the carry bit.

---

## 🛠️ System Architecture

### 1. Memory Configuration
- **ROM A**: `1024 x 4-bit` - Constant values for the first vector.
- **RAM B**: `1024 x 4-bit` - Modifiable values for the second vector.
- **RAM C**: `1024 x 5-bit` - Accumulator storage for the result of `A + B`.

### 2. Operation Modes (`sw[15:14]`)
The system behavior is controlled by the two most significant switches:

| Mode (Binary) | Description | Action |
| :--- | :--- | :--- |
| `00` | **IDLE** | System wait state. |
| `01` | **READ** | Displays values of A, B, and C at `addr` on the 7-segment display. |
| `10` | **WRITE** | Writes `sw[3:0]` into RAM B at `addr` and updates RAM C. |
| `11` | **INCREMENT** | Increments the current value of RAM B at `addr` and updates RAM C. |

### 3. Initialization Logic
Upon system reset or startup (`btnc`), the system enters an automatic initialization phase:
1. It iterates through all addresses from `0` to `1023`.
2. For each address, it fetches `A` and `B`, calculates `A + B`, and stores the result in `RAM C`.
3. During this phase or immediately after reset, the 7-segment display shows a `rSt` message for approximately 5 seconds.

---

## 🕹️ Controls & Hardware Mapping

| Input | Description |
| :--- | :--- |
| **`sw[15:14]`** | Operation Mode Select. |
| **`sw[13:4]`** | 10-bit Memory Address (`0` to `1023`). |
| **`sw[3:0]`** | 4-bit Input Data (used in WRITE mode). |
| **`btnc`** | Reset System / Trigger Re-initialization. |

### 📊 7-Segment Display (READ Mode)
When in **READ mode (`01`)**, the 4-digit display shows:
- **Digit 3 & 2**: Result of Vector C (Hexadecimal).
- **Digit 1**: Current value of Vector B (Hexadecimal).
- **Digit 0**: Current value of Vector A (Hexadecimal).

---

## 📁 Project Structure

- `top-2.v`: The main module containing memory instantiations, FSM logic for write/inc pulses, and initialization routines.
- `display_7seg`: Sub-module for multiplexed 7-segment display control and hex-to-segment decoding.
- `debouncer`: Handles mechanical button bounce for the reset signal.
- `vector_a_rom.v/xci`: IP core for the read-only memory of Vector A (not included in root but referenced).
- `vector_b_ram.v/xci`: IP core for the read-write memory of Vector B.
- `vector_c_ram.v/xci`: IP core for the read-write memory of Vector C.
- `tb_top.v`: Simulation testbench to verify memory operations and addition logic.
- `schematic_diagram.pdf`: Hardware architectural diagram.
