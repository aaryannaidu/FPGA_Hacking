# 4-Digit Number Display Module for FPGA

This project implements a **4-Digit Number Display Module** designed for FPGA boards. The module drives a 7-segment display to show a 4-digit number, with each digit controlled independently.

## Features

- **4-Digit Display**: Displays a 4-digit number using a multiplexed 7-segment display.
- **Independent Digit Control**: Each digit can be updated independently using specific switches.
- **Anode Control**: Activates the appropriate anode for each digit in a time-multiplexed manner.
- **Clock-Based Refresh**: Uses a clock signal to refresh the display at a rate imperceptible to the human eye.

## File Structure

- `top_module.v`: Contains the Verilog implementation of the 4-digit display module.
- `top_module_tb.v`: Testbench for simulating and verifying the functionality of the module.

## Usage

### Inputs

- **Switches (`sw`)**:
  - `sw[9:0]`: Represents the binary value of the digit to be displayed.
  - `sw[10]`: Enable switch for digit 0.
  - `sw[11]`: Enable switch for digit 1.
  - `sw[12]`: Enable switch for digit 2.
  - `sw[13]`: Enable switch for digit 3.
- **Clock (`clk`)**: Drives the internal logic and refreshes the display.

### Outputs

- **Anodes (`an`)**: Controls which digit is active on the 7-segment display.
- **Segments (`seg`)**: Drives the segments of the active digit to display the corresponding value.

### How It Works

1. **Digit Storage**: Each digit's value is stored in an internal register (`dataout0`, `dataout1`, `dataout2`, `dataout3`) when its corresponding enable switch (`sw[10]` to `sw[13]`) is activated.
2. **Time Multiplexing**: The module cycles through the digits using a counter, activating one anode at a time and displaying the corresponding digit.
3. **7-Segment Encoding**: The binary value of each digit is converted to the appropriate 7-segment pattern.

### Simulation

To simulate the module:
1. Open the `top_module_tb.v` file in your simulation tool.
2. Run the simulation to verify the functionality of the module.

### Synthesis

1. Synthesize the `top_module.v` file using Vivado or another FPGA design tool.
2. Load the synthesized bitstream onto your FPGA board.

## Requirements

- **FPGA Board**: Any FPGA board with a 4-digit 7-segment display.
- **Tools**: Vivado (or any compatible FPGA design tool).

## Author

This module was designed to demonstrate the functionality of a 4-digit number display for educational and practical purposes on FPGA boards.