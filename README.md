# Real-Time Digital Clock (SystemVerilog)

A hardware-implemented real-time digital clock system designed in SystemVerilog. The project features customizable time configuration, runtime-switchable 12-hour/24-hour display tracking, and an optimized, multiplexed 6-digit seven-segment display pipeline.

Targeted and fully optimized for the **Altera/Terasic DE1-SoC Development Board** (Cyclone V FPGA).

---

## Hardware Features & UI Mapping

The project utilizes the onboard peripherals of the DE1-SoC board mapped as follows:

*   **`CLOCK_50` (50 MHz Oscillator):** System clock input.
*   **`KEY[0]` (Push Button):** Active-Low asynchronous global reset.
*   **`KEY[2]` (Push Button):** `OkPulse` — State machine transition trigger used to cycle through configuration modes.
*   **`KEY[3]` (Push Button):** `AddPulse` — Increments the time value during configuration.
*   **`SW[9]` (Toggle Switch):** Runtime 12/24 Hour Format Switch.
    *   **High (Up):** 24-hour display format.
    *   **Low (Down):** 12-hour display format (dynamically formats `00` to `12` and PM hours accordingly).
*   **`HEX0` to `HEX5`:** Displays time as `HH:MM:SS` from left to right.

---

## Finite State Machine (FSM)

The control logic centers around a 4-state Finite State Machine allowing the system to shift seamlessly between standard counting and configuration modes. You can advance through the states sequentially by pressing **`KEY[2]` (`OkPulse`)**:

1.  **`COUNT` (Default State):** The clock increments sequentially, tracked via a 1 Hz edge-detection pulse generated from the master clock divider.
2.  **`HOURS` (Configuration State):** Pressing `KEY[3]` increments internal hours (`0-23`). The display updates dynamically in real-time to your 12/24hr format switch (`SW[9]`).
3.  **`MINS` (Configuration State):** Pressing `KEY[3]` increments internal minutes (`0-59`).
4.  **`SECS` (Configuration State):** Pressing `KEY[3]` increments internal seconds (`0-59`). Pressing `KEY[2]` while in this state saves adjustments and returns the system back to the `COUNT` state.

![Image of FSM](state_machine.jpg)

---

## Project Architecture & Hierarchy

The project implements a modular hardware hierarchy to handle clock frequency dividing, binary-to-BCD conversion, and display multiplexing:

*   **`main.sv`**: The main top-level module. Contains state-machine logic, input edge-detectors, internal counters, and structural component mappings.
    *   **`ClockDivide.sv` (Instance: `clock_divider`)**: Parameterized clock scaler that safely steps down the high-speed 50 MHz input to lower working frequencies.
    *   **`SevenSegDriver.sv` (Instance: `display_driver`)**: High-frequency scanning module that loops through each seven-segment display, outputting specific data segments using a fast 1 MHz scanning clock.
        *   **`BinToBCD.sv`**: A highly efficient pipelined implementation of the Add-3 (Double-Dabble) binary-to-BCD architecture.
        *   **`ClockDivide.sv`**: Handles the display refresh rate timing.
        *   **`DigitDriver.sv`**: Maps 4-bit nibbles into active-low outputs required to display alphanumeric representations (`0-9`) safely on the DE1-SoC platform.

---

## Setup Instructions (Quartus Prime Lite)

Follow these instructions to compile and flash the repository directly onto your hardware:

### 1. Create a New Project
1. Open **Quartus Prime Lite Edition**.
2. Navigate to **File** -> **New Project Wizard**.
3. Set your working directory and name the project top-level entity exactly as `main`.

### 2. Import Source Files
1. Copy all `.sv` project source files into your local directory.
2. Inside Quartus, go to **Project** -> **Add/Remove Files in Project**.
3. Select and add the following files:
   * `main.sv`
   * `ClockDivide.sv`
   * `SevenSegDriver.sv`
   * `BinToBCD.sv`
   * `DigitDriver.sv`

### 3. Target Device Selection
When prompted to select your hardware target, select the exact chip layout for the DE1-SoC board:
*   **Family:** Cyclone V
*   **Device:** 5CSEMA5F31C6

### 4. Apply Pin Assignments
To skip manually configuring pins, map the hardware assignments instantly using the Terasic board layout settings provided in the repository:
1. Go to **Tools** -> **Tcl Scripts...**
2. Look for the project configuration file (or import the pin structure text as a `.tcl` execution string) and run the script. This configures standard pin rules for `CLOCK_50`, `HEX[0-5]`, `KEY[0-3]`, and `SW[0-9]` instantly.

### 5. Compile & Program
1. Double-click **Start Compilation** in the tasks view dashboard.
2. Connect your **DE1-SoC Board** via a USB Blaster cable and power it up.
3. Open the **Programmer tool**, select the compiled `.sof` binary file from your `output_files/` directory, and click **Start** to run the real-time clock directly on your hardware!
