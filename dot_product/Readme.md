# Accumulator Module for Basys3 FPGA

This project implements an **Accumulator Module** designed for the Basys3 FPGA board. The module performs dot product calculations on two 4-element vectors, with additional features such as overflow detection and a 7-segment display interface.

## Features

- **Dot Product Calculation**: Computes the dot product of two 4-element vectors (A and B).
- **Overflow Detection**: Indicates when the result exceeds the 16-bit range.
- **7-Segment Display**: Displays the result, vector elements, or error messages.
- **Debouncing**: Includes a debouncer for stable button inputs.
- **Simulation Support**: Testbench provided for functional verification.

## File Structure

- `dot_prod.v`: Contains the Verilog implementation of the accumulator module and its submodules.
- `tb_dot_prod.v`: Testbench for simulating and verifying the functionality of the module.
- `Readme.md`: Documentation for the project.

## Usage

1. **Synthesis**: Synthesize the `dot_prod.v` file using Vivado or another FPGA design tool.
2. **Programming**: Load the synthesized bitstream onto the Basys3 FPGA board.
3. **Inputs**:
   - Use switches (`sw`) to input vector elements.
   - Use the center button (`btnc`) to reset the module.
4. **Outputs**:
   - The result of the dot product is displayed on the LEDs.
   - The 7-segment display shows the result, vector elements, or error messages.

## Simulation

To simulate the module:
1. Open the `tb_dot_prod.v` file in your simulation tool.
2. Run the simulation to verify the functionality of the module.

## Requirements

- **FPGA Board**: Basys3
- **Tools**: Vivado (or any compatible FPGA design tool)

