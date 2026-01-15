# FPGA Hacking 🚀

Welcome to **FPGA Hacking**! This repository is a curated collection of Verilog projects ranging from fundamental digital logic to complex hardware-accelerated systems, all designed for the **Basys 3 FPGA (Artix-7)**.

Whether you are just starting your journey into the world of Hardware Description Languages (HDL) or looking for interesting implementations like hardware-based linked lists or VGA games, this repo has something for you.

---

## 🏁 Starting with FPGAs?

Unlike traditional programming (C++, Python), where instructions are executed sequentially by a CPU, **FPGAs (Field Programmable Gate Arrays)** allow you to design the actual physical circuitry.

### Why FPGAs are awesome:
- **Massive Parallelism**: You can do thousands of operations simultaneously.
- **Low Latency**: Perfect for real-time signal processing and high-speed control.
- **Hardware-Level Control**: You are the architect of the data path.

**Tools used here:**
- **Language**: Verilog HDL
- **Hardware**: Basys 3 Trainer Board
- **Software**: Xilinx Vivado Design Suite

---

## 📁 Project Directory

Explore the folders below to see various implementations:

### 🎮 Games & Graphics
*   **[Retro Racer](./retro_racer)**: A full VGA-based racing game. Features smooth background scrolling, random obstacle generation using LFSR, and real-time collision detection.

### 🧠 Computational Logic
*   **[Vector Add Mem](./vector_add_mem)**: Implements `C = A + B` using dual-port RAM and ROM. Demonstrates how to manage memory addresses and data synchronization in hardware.
*   **[Dot Product](./dot_product)**: Hardware-accelerated dot product calculation, optimized for high-performance arithmetic.
*   **[Accumulator](./accumulator)**: A fundamental Multiply-Accumulate (MAC) unit, the building block of DSP and Neural Networks.

### ⛓️ Data Structures in Hardware
*   **[Linked List](./linked_list)**: A rare and fascinating implementation of a dynamic-like linked list structure purely in hardware logic.

### 🔢 Display & Basics
*   **[Num Display](./num_disply)**: Master the 7-segment display! Contains logic for multiplexing and binary-to-hex decoding.

---

## 🛠️ How to Run
1.  Clone this repository.
2.  Open **Xilinx Vivado**.
3.  Create a new project and add the `.v` source files and the `.xdc` constraint file from the specific project folder.
4.  Generate bitstream and program your **Basys 3** board!

Happy Hacking! 🛠️⚡
