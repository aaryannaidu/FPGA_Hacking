# Linked List FPGA Implementation

## Overview

This project implements a hardware-linked list data structure on FPGA. The implementation uses on-chip memory (registers) to simulate a linked list with support for insertion, deletion, and traversal operations. The design includes a 7-segment display interface for visualizing list contents during traversal.

## Features

- **Insert at Head**: Add a new node at the beginning of the list
- **Insert at Tail**: Add a new node at the end of the list
- **Delete Node**: Remove a node by searching for its data value
- **Traverse List**: Display all list elements sequentially on the 7-segment display
- **Overflow/Underflow Detection**: Flags for full list and empty list conditions
- **Visual Feedback**: 7-segment display shows current data during traversal
- **Free Node Management**: Efficient allocation/deallocation using bitmap

## Architecture

The implementation consists of three main modules:

1. **`linked_list`**: Core linked list module with operation state machines
2. **`linked_list_top`**: Top-level wrapper for FPGA board integration
3. **`linked_list_tb`**: Testbench for verification

## Module Descriptions

### linked_list Module

The core linked list module that implements all operations using state machines.

#### Parameters

- `MAX_NODES` (default: 32): Maximum number of nodes in the list
- `ADDR_WIDTH` (default: 5): Address width for node pointers (log2(MAX_NODES))

#### Ports

**Inputs:**
- `clk`: System clock
- `rst`: Active-high reset signal
- `data_in[7:0]`: 8-bit data value for insertion/deletion
- `operation[2:0]`: Operation code (see Operation Codes below)

**Outputs:**
- `overflow`: Flag set when list is full
- `underflow`: Flag set when list is empty or operation fails
- `seg[6:0]`: 7-segment display segments (cathodes)
- `an[3:0]`: 7-segment display anodes (digit select)
- `dp`: Decimal point (currently unused)

#### Internal Data Structures

- `data_mem[0:MAX_NODES-1]`: Array storing 8-bit data for each node
- `next_ptr[0:MAX_NODES-1]`: Array storing next node pointers
- `free_list[MAX_NODES-1:0]`: Bitmap indicating which nodes are free (1=free, 0=used)
- `head`: Pointer to the first node in the list
- `count`: Current number of nodes in the list
- `list_empty`: Flag indicating if list is empty

#### Operation Codes

| Code | Operation | Description |
|------|-----------|-------------|
| `3'b000` | `OP_IDLE` | No operation |
| `3'b100` | `OP_INSERT_HEAD` | Insert node at head |
| `3'b101` | `OP_INSERT_TAIL` | Insert node at tail |
| `3'b110` | `OP_DELETE` | Delete node with matching data |
| `3'b111` | `OP_TRAVERSE` | Traverse and display list |

#### State Machines

**Main State Machine:**
- `MAIN_IDLE`: Waiting for operation
- `MAIN_INSERT_HEAD`: Inserting at head
- `MAIN_INSERT_TAIL_FIND`: Finding tail node
- `MAIN_INSERT_TAIL_LINK`: Linking new tail node
- `MAIN_DELETE_SEARCH`: Searching for node to delete
- `MAIN_DELETE_UNLINK`: Removing node from list

**Traverse State Machine:**
- `TRAV_IDLE`: Not traversing
- `TRAV_DISPLAY`: Displaying current node
- `TRAV_WAIT`: Waiting delay for display
- `TRAV_NEXT`: Moving to next node

### linked_list_top Module

Top-level module for FPGA board integration (designed for Xilinx Basys3/Artix-7).

#### Ports

**Inputs:**
- `clk`: 100MHz system clock
- `btnC`: Center button (reset)
- `sw[15:0]`: 16 switches for input
  - `sw[7:0]`: Data input (8-bit)
  - `sw[15:13]`: Operation code (3-bit)

**Outputs:**
- `led[15:0]`: LEDs
  - `led[0]`: Overflow flag
  - `led[1]`: Underflow flag
  - `led[15:2]`: Unused
- `seg[6:0]`: 7-segment display segments
- `an[3:0]`: 7-segment display anodes
- `dp`: Decimal point

#### Features

- Button debouncing for reset
- Operation edge detection (triggers on operation change)
- Reset display ("-rSt") shown for 5 seconds after reset

## Operation Details

### Insert at Head

1. Check if list is full (overflow check)
2. Find first free node using `find_free_node()` function
3. Allocate node: mark as used in `free_list`
4. Store data in `data_mem[new_node]`
5. Set `next_ptr[new_node]` to current head
6. Update `head` to new node
7. Increment `count`

**Time Complexity:** O(1) - Single clock cycle after allocation

### Insert at Tail

1. Check if list is full (overflow check)
2. If list is empty, same as insert at head
3. Find first free node
4. Traverse list to find tail (follow `next_ptr` until NULL)
5. Allocate node and link to tail
6. Set new node's `next_ptr` to NULL
7. Increment `count`

**Time Complexity:** O(n) - Requires traversal to tail

### Delete Node

1. Check if list is empty (underflow check)
2. Search for node with matching `data_in` value
3. Maintain `prev_ptr` during search
4. If found:
   - If deleting head: update `head` to `next_ptr[curr_ptr]`
   - Otherwise: update `next_ptr[prev_ptr]` to `next_ptr[curr_ptr]`
5. Free node: mark as free in `free_list`
6. Decrement `count`
7. If `count` becomes 0, set `list_empty = 1`

**Time Complexity:** O(n) - Worst case traversal

### Traverse List

1. Check if list is empty (underflow check)
2. Start from `head`
3. For each node:
   - Display data on 7-segment display (hex format)
   - Wait 1 second (100,000,000 cycles at 100MHz)
   - Move to next node via `next_ptr`
4. Continue until NULL pointer reached

**Display Format:** Two hex digits on rightmost 7-segment displays

## Usage Guide

### Simulation (Testbench)

1. Compile the testbench:
   ```bash
   iverilog -o linked_list_tb linked_list.v lisked_list_tb.v
   ```

2. Run simulation:
   ```bash
   ./linked_list_tb
   ```

3. View waveforms:
   ```bash
   gtkwave linked_list_tb.vcd
   ```

The testbench includes comprehensive tests:
- Insert at head
- Insert at tail
- Delete operations (head, middle, tail)
- Overflow/underflow conditions
- Reset functionality
- Traverse visualization

### FPGA Implementation

1. **Synthesis**: Create project in Vivado/ISE and add:
   - `linked_list.v`
   - `linked_list_top.v` (or combine both in one file)

2. **Pin Constraints**: Map ports to FPGA board pins:
   - Clock: System clock pin
   - Switches: `sw[15:0]` to switch pins
   - Buttons: `btnC` to center button
   - LEDs: `led[15:0]` to LED pins
   - 7-segment: `seg[6:0]`, `an[3:0]`, `dp` to display pins

3. **Operation**:
   - Set data value on `sw[7:0]`
   - Set operation code on `sw[15:13]`
   - Operation triggers on edge (change from previous value)
   - Watch LEDs for overflow/underflow flags
   - During traverse, data appears on 7-segment display

### Example Operations

**Insert 0x5A at head:**
- Set `sw[7:0] = 8'h5A`
- Set `sw[15:13] = 3'b100` (OP_INSERT_HEAD)
- Change operation to trigger (e.g., 3'b000 → 3'b100)

**Delete node with value 0x5A:**
- Set `sw[7:0] = 8'h5A`
- Set `sw[15:13] = 3'b110` (OP_DELETE)
- Change operation to trigger

**Traverse list:**
- Set `sw[15:13] = 3'b111` (OP_TRAVERSE)
- Change operation to trigger
- Watch 7-segment display for sequential data display

## Design Considerations

### Memory Management

- Uses static allocation with `MAX_NODES` nodes
- Free node bitmap (`free_list`) enables O(1) allocation
- NULL pointer = `{ADDR_WIDTH{1'b1}}` (all 1s)

### Timing

- Insert at head: 1 clock cycle
- Insert at tail: n+1 clock cycles (n = current list length)
- Delete: m+1 clock cycles (m = position of node)
- Traverse: Continuous until end (1 second per node)

### Limitations

- Fixed maximum size (parameterizable)
- 8-bit data values only
- Sequential operations (one at a time)
- No concurrent operations

### Display Details

- **Reset Display**: Shows "-rSt" for 5 seconds after reset
- **Normal Display**: Shows hex value of current node during traverse
- **Display Multiplexing**: 4-digit display, uses 2 rightmost digits
- **Refresh Rate**: Updates every ~2.6ms (100MHz / 2^20)

## File Structure

```
linked_list/
├── linked_list.v          # Main linked list module and top wrapper
├── lisked_list_tb.v       # Testbench (note: typo in filename)
└── README.MD              # This file
```

## Testing

The testbench verifies:

1. ✅ Insert at head operations
2. ✅ Insert at tail operations  
3. ✅ Delete operations (head, middle, tail nodes)
4. ✅ Delete non-existent node (underflow)
5. ✅ Overflow condition (full list)
6. ✅ Traverse operation
7. ✅ Reset functionality
8. ✅ Empty list operations

Run the testbench and check console output for PASS/FAIL status.

## Future Enhancements

Possible improvements:
- Support for larger data widths (16-bit, 32-bit)
- Multiple simultaneous lists
- Priority-based insertion
- Search operation (without deletion)
- Display list count on 7-segment
- Serial interface for PC communication

## Notes

- The NULL pointer value is `{ADDR_WIDTH{1'b1}}` (e.g., `5'h1F` for 32 nodes)
- Operations trigger on edge detection (change from previous operation)
- Flags (overflow/underflow) remain high briefly after operation completes
- The traverse operation is independent and can run while other operations are idle

