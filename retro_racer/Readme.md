# Retro Racer 🏎️

A high-speed, arcade-style racing game built entirely on FPGA (Basys 3) using Verilog. Navigate your car through traffic, avoid obstacles, and survive as long as you can!

## 🎮 Overview

Retro Racer is a hardware-accelerated 2D racing game that features smooth background scrolling, randomized rival car spawning, and real-time collision detection. The game is designed to run on the **Basys 3 FPGA board**, outputting high-quality VGA graphics.

---

## 🛠️ Technical Implementation

### 1. Pseudo-Random Number Generation (LFSR)
To ensure dynamic gameplay, an **8-bit Linear Feedback Shift Register (LFSR)** module (`lfsr_8bit`) handles randomness.
- **Mechanism**: Uses a feedback polynomial (XOR of bits 7, 5, 4, and 3).
- **Initialization**: Seeded with `LFSR_SEED` (derived from kerberos IDs).
- **Function**: Generates a new pseudo-random 8-bit value (`random_value`) on every enabled clock cycle, providing unpredictable horizontal positioning for rival cars.

### 2. Rival Car Mechanics
The rival cars are the primary obstacle in the game, featuring intelligent spawning and movement logic:
- **Spawning**: When the game starts or resets, a rival car is initialized at the top of the track (`rival_y_pos = 150`).
- **Randomized X-Position**: A `scale_random` function maps the LFSR's 8-bit output (0–255) to a valid horizontal road range (`44` to `104`). This ensures the rival car always stays within the bounds of the road.
- **Controlled Movement**: A frame counter (`rival_frame_count`) regulates speed. The car moves down 2 pixels (`RIVAL_Y_STEP`) every 15 frames, creating a consistent downward flow.
- **Respawning**: Once a rival car reaches the bottom of the screen, it is automatically respawned at the top with a fresh random X-coordinate.

### 3. Sprite and Display Specifications
The game uses custom-designed sprites stored in ROM:
- **Playable Car**: 14x16 pixels.
- **Rival Car**: 14x16 pixels.
- **Background**: 160x240 pixels (scrolled vertically to create movement).
- **VGA Resolution**: Standard 640x480 @ 60Hz (with active game area centered).

### 4. Real-Time Collision Detection
Safety is handled by a dedicated `main_rival_collision` wire which implements a **2D bounding-box check**.
- **Logic**: If the hitboxes of the player's car and the rival car overlap at any point, the collision signal is pulled high.
- **Hitbox Implementation**:
  ```verilog
  assign main_rival_collision = rival_active &&
                               (car_x_pos < rival_x_pos + rival_car_width) &&
                               (car_x_pos + main_car_width > rival_x_pos) &&
                               (car_y_pos < rival_y_pos + rival_car_height) &&
                               (car_y_pos + main_car_height > rival_y_pos);
  ```

### 5. Finite State Machine (FSM)
The game logic is governed by a robust FSM with the following transitions:
- **IDLE, RIGHT_CAR, LEFT_CAR**: These states handle movement logic while continuously monitoring for `main_rival_collision`.
- **COLLIDE State**: Triggered instantly upon collision.
- **Freeze Logic**: In the `COLLIDE` state, all movement logic (background scrolling and rival car movement) is paused, effectively "freezing" the game to signify a crash.

---

## 🕹️ Controls & Hardware

| Input | FPGA Component | Action |
| :--- | :--- | :--- |
| **Move Left** | `BTNL` (Button Left) | Moves the car to the left lane |
| **Move Right** | `BTNR` (Button Right) | Moves the car to the right lane |
| **Start / Reset** | `BTNC` (Button Center) | Starts the game or Resets after a crash |
| **Video Out** | VGA Port | Connect to any VGA-compatible monitor |

---

## 🚀 Getting Started

To run the game on your Basys 3 board, you can directly flash the pre-compiled bitstream file.

### 📥 Download Bit File
[**Download Display_sprite.bit**](./Display_sprite.bit)

---

## 📁 Project Structure

- `Display_sprite-2.v`: The top-level module containing the game logic, FSM, and sprite rendering.
- `VGA_driver.v`: Handles VGA timing signals (HS/VS) and pixel coordinates.
- `clk_divider.v`: Generates the required pixel clock for the VGA display.
- `lfsr_8bit.v`: Pseudo-random number generator for obstacle placement.
- `basys3-3.xdc`: Hardware constraint file for pin mappings.
