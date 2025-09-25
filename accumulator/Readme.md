# Accumulator in FPGA (The Pillars for Neurons)

This project implements an **Accumulator Module** designed for FPGA boards. The accumulator is a fundamental building block for neural networks and other digital signal processing applications. It performs the dot product of two vectors, which is a key operation in many computational tasks.

## Features

- **Dot Product Calculation**: Computes the dot product of two 4-element vectors (A and B).
- **Overflow Detection**: Detects and handles overflow conditions when the result exceeds the 16-bit range.
- **7-Segment Display**: Displays the result, vector elements, or error messages on a 7-segment display.
- **Debounced Inputs**: Includes debouncing logic for stable button inputs.
- **Simulation Support**: A testbench is provided for functional verification.

## File Structure

- `dot_prod.v`: Verilog implementation of the accumulator module.
- `tb_dot_prod.v`: Testbench for simulating and verifying the functionality of the module.
- `README.md`: Documentation for the project.

## How It Works

1. **Input Vectors**: The module takes two 4-element vectors (A and B) as inputs. Each element is a 10-bit value.
2. **Dot Product Calculation**: The module computes the dot product of the two vectors:
   \[
   \text{Dot Product} = A[0] \times B[0] + A[1] \times B[1] + A[2] \times B[2] + A[3] \times B[3]
   \]
3. **Overflow Detection**: If the result exceeds the 16-bit range, an overflow flag is set.
4. **Output**: The result is displayed on the FPGA's LEDs and 7-segment display.

## Usage

### Inputs

- **Switches (`sw`)**:
  - `sw[9:0]`: Represents the binary value of the vector elements.
  - `sw[10]` to `sw[13]`: Enable switches for writing vector elements A[0] to A[3] and B[0] to B[3].
- **Buttons**:
  - `btnc`: Resets the module.

### Outputs

- **LEDs**: Display the result of the dot product.
- **7-Segment Display**: Shows the result, vector elements, or error messages.

### Simulation

To simulate the module:
1. Open the `tb_dot_prod.v` file in your simulation tool.
2. Run the simulation to verify the functionality of the module.

### Synthesis

1. Synthesize the `dot_prod.v` file using Vivado or another FPGA design tool.
2. Load the synthesized bitstream onto your FPGA board.

## Applications

- Neural networks and machine learning accelerators.
- Digital signal processing (DSP) applications.
- Educational purposes for understanding vector operations.

## Requirements

- **FPGA Board**: Any FPGA board with a 7-segment display and LEDs.
- **Tools**: Vivado (or any compatible FPGA design tool).

## Author

This module was designed to demonstrate the functionality of an accumulator for educational and practical purposes on FPGA boards.
