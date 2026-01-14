# Verilog Coding rules

### 1. The "Always" Rule

* **Rule:** If a signal is on the **left** side of an assignment inside an `always` block, it **MUST** be a `reg`.
* **Reason:** The `always` block implies "procedure" or "memory," so the variable must hold its value until the next update.

### 2. The "Assign" Rule

* **Rule:** If a signal is on the **left** side of an `assign` statement, it **MUST** be a `wire`.
* **Reason:** `assign` creates a permanent physical connection (like soldering a wire), not a storage memory.

### 3. The "Child-to-Parent" Rule

* **Rule:** When connecting a submodule's **output** to the parent module, the parent's receiving signal **MUST** be a `wire`.
* **Reason:** The submodule is already "driving" the signal. You cannot plug a hard driver directly into a storage bucket (`reg`).

### 4. The "Wire-then-Reg" Rule (The Fix)

* **Rule:** To store a submodule's output into a `reg`, you must first catch it with a `wire` in the parent's module, then copy it to the `reg` inside an `always` block.
* **Reason:** A `reg` can only have **one master** (the `always` block). If you connected the submodule directly to the `reg`, the submodule would try to fight the `always` block for control, causing a conflict as there is a difference in **who is doing the driving (writing)** versus **who is being read**.

### 5. The "Parent-to-Child" Rule

* **Rule:** When sending a signal **into** a submodule's input, the source can be a `reg` OR a `wire`.
* **Reason:** The submodule just listens to the voltage level; it doesn't care if that voltage comes from a register or a wire.

  
* Important Considerations for this rule shown in table as follows.

| Source of the Signal | Signal Type Needed? | Reason |
| :--- | :--- | :--- |
| **Generated in `always` block** | `reg` | Procedural assignments require storage (memory) to hold the value between events. |
| **Generated in `assign` statement** | `wire` | Continuous assignments represent a permanent physical connection, not storage. |
| **Comes from another submodule** | `wire` | The submodule is the "driver." You must use a wire to catch the signal output. |
| **Comes from Parent Input Port** | `wire` | You cannot write to your own input; you can only read from the wire connecting to the outside world. |

### 6. The "Input Port" Rule

* **Rule:** Inside a module definition, an `input` port is **ALWAYS** a `wire`.
* **Reason:** You cannot write to your own input; you only read from it.

### 7. The "Output Port" Rule

* **Rule:** Inside a module definition, an `output` port can be defined as `wire` (default) OR `reg`.
* **Reason:** Use `wire` if the value comes from combinational logic (`assign`). Use `reg` if the value is calculated in an `always` block.

### The Port connection type diagram for the reference (Samir Palnitkar)

![Port Connection Rule](Port_Connection_Rule.png)

### 8. Command to use for running the simulation of any verilog file
Input file - TOP_module.v 
testbench file - testbench_file.v
  * Compile the Simulation
  ```bash
    iverilog -o soc_sim testbench_file.v TOP_module.v
  ```
  * Run the simulation
  ```bash
    vvp soc_sim
  ```
  * Open the wwaveform file given in the testbench on the line **`$dumpfile("waves.vcd");`**
  ```bash
    gtkwave waves.vcd
  ```

## Design Architecture: Why do we want Registered Outputs from any module ?


1. **Timing Isolation (Breaking the Critical Path)**
   - **Without Registers:** If Module A outputs combinational logic and connects to Module B, the synthesis tool sees one giant, long path that stretches through A and into B. This long path might exceed the clock period, causing a timing violation.
   - **With Registers:** The timing path stops at the output of Module A. Module B sees a signal starting fresh from a Flip-Flop. This "isolates" the timing budget of Module A from Module B, making it much easier to meet timing requirements.

2. **Glitch Filtering (Signal Integrity)**
   - **Without Registers:** These glitches are sent out to the next module. If that module uses the signal for something sensitive (like a clock enable or asynchronous reset), the glitches can cause fatal errors.
   - **With Registers:** Output registers act as a filter. They ignore inter-clock transients and only capture data at the clock edge. This ensures that downstream modules receive clean, stable signals, preventing false triggers on sensitive lines (like resets or enables).

3. **Predictable Interface (Fixed Latency)**
   - **Why:** Registered outputs provide a constant **Clock-to-Q** delay.
   - **Benefit:** The output timing becomes deterministic and independent of the complexity of the internal logic cloud. This simplifies system-level integration and static timing analysis (STA).
  
  
## Verilog Generate Block Guidelines

##  Overview

The `generate` construct allows you to create **variable hardware structures** at compile-time (elaboration time). It is used to:

1.  **Instantiate multiple copies** of a module (e.g., an array of adders).
2.  **Conditionally include/exclude logic** based on parameters (e.g., `if (FAST_MODE)`).

> **Crucial Concept:** Generate blocks work during **Elaboration**, not Simulation. You are telling the tool *what to build*, not telling the chip *what to do* while running.

---

## 5 Golden Rules

### 1. `genvar` is Mandatory
You cannot use a standard `integer` or `reg` for loop iterators. You must explicitly declare a `genvar`.
* **Right:** `genvar i;`
* **Wrong:** `integer i;`

### 2. Labels are Critical (Naming Scope)
Every `begin` block inside a generate loop **must** have a label name (after the colon).
* **Why?** The synthesis tool uses this label to name the physical instances in the hierarchy.
* **Without label:** `Error: generate loop block must have a name.`
* **With label:** Instance becomes `my_loop[0].unit`, `my_loop[1].unit`.

### 3. Strictly Outside `always` Blocks
A `generate` block defines hardware structure. An `always` block defines runtime behavior.
* **Never** put `generate` inside `always`.
* **You CAN** put `always` inside `generate`.

### 4. Conditions Must Be Constants
The conditions in `if` or `case` generate statements must be **Parameters** or **Constants** known at compile time.
* **Right:** `if (WIDTH > 8)`
* **Wrong:** `if (input_signal == 1'b1)` (Hardware cannot physically appear/disappear based on a runtime signal).

### 5. Local Scope Variables
Variables declared *inside* a generate block are local to that specific iteration.
* If you declare `wire x;` inside a loop running 8 times, you create 8 distinct wires named `loop[0].x`, `loop[1].x`, etc.

---

## Syntax Templates

### 1. Loop Generate (Multiple Instances)
Use this to create arrays of modules or logic.

```verilog
genvar i; // 1. Declare iterator

generate
    for (i = 0; i < 8; i = i + 1) begin : bit_slice // 2. MANDATORY LABEL
        
        // 3. Logic to replicate
        full_adder fa_inst (
            .a(a[i]),
            .b(b[i]),
            .sum(sum[i])
        );
        
    end
endgenerate
```

## MUX vs. Priority Encoder: A Digital Design Guide

In RTL design, the choice between `if-else` and `case` statements directly impacts the physical hardware synthesized by the tools. The resulting hardware is typically either a **Multiplexer (MUX)** or a **Priority Encoder**, depending on whether the conditions are **mutually exclusive**.

---

## 1. Core Synthesis Principles

| Logic Structure | Condition Nature | Synthesized Hardware | Hardware Behavior |
| :--- | :--- | :--- | :--- |
| **`case` statement** | Inherently Mutually Exclusive | **Multiplexer (MUX)** | Parallel evaluation; all inputs have equal weight. |
| **`if-else` (Exclusive)** | Mutually Exclusive | **Multiplexer (MUX)** | The tool recognizes only one condition can be true at a time. |
| **`if-else` (Overlapping)**| Not Mutually Exclusive | **Priority Encoder** | Chained logic; the first true condition inhibits the rest. |

---

## 2. The Multiplexer (MUX)

A MUX is synthesized when selection conditions are **mutually exclusive**—meaning only one condition can be true at any given time. This results in parallel logic that is generally faster (better timing) and more area-efficient.

### A. Using `case` Statements
In Verilog, a `case` statement naturally describes a MUX because the case expression can only match one branch at a time.

```verilog
module mux_example (
    input [1:0] sel,      // The explicit control signal
    input [3:0] in_data,
    output reg out_data
);

    // MUX Logic: Synthesis tool sees 'sel' can only have ONE value at a time.
    always @(*) begin
        case (sel)
            2'b11:   out_data = in_data[3];
            2'b10:   out_data = in_data[2];
            2'b01:   out_data = in_data[1];
            2'b00:   out_data = in_data[0];
            default: out_data = 1'b0;
        endcase
    end
endmodule
```

### B. Mutually Exclusive if-else

If the tool can prove the conditions are mutually exclusive (e.g., checking different values of the same signal), it optimizes the logic into a MUX rather than a priority chain.
```Verilog
// Even though this is if-else, the tool knows 'sel' cannot be 00 and 01 simultaneously.
// RESULT: MUX (Parallel Logic)
always @(*) begin
    if (sel == 2'b00)      out = a;
    else if (sel == 2'b01) out = b;
    else if (sel == 2'b10) out = c;
    else                   out = d;
end
```

## 3. The Priority Encoder

A Priority Encoder is synthesized when conditions are not mutually exclusive. The hardware must evaluate conditions in the specific order they are written, creating a **priority chain** where the first true condition **wins** and blocks the others.

### A. Request-Based Priority
When handling multiple independent signals where more than one can be active at once, a priority encoder selects the highest-priority signal.

```verilog
module priority_encoder (
    input [3:0] req,      // Multiple requests can be 1 at the same time
    output reg [1:0] encoder_out
);

    // Priority Logic: 'req[3]' is checked first. It "inhibits" the others.
    always @(*) begin
        if (req[3])           // Priority 1 (Highest)
            encoder_out = 2'b11;
        else if (req[2])      // Priority 2
            encoder_out = 2'b10;
        else if (req[1])      // Priority 3
            encoder_out = 2'b01;
        else                  // Priority 4 (Lowest)
            encoder_out = 2'b00;
    end
endmodule
```

### B. Functional Overlap

In this scenario, if both turbo_mode and power_save are TRUE, the hardware must build logic to ensure turbo_mode takes precedence because it was checked first in the if block.

```Verilog
// RESULT: Priority Encoder (Serial/Chained Logic)
always @(*) begin
    if (turbo_mode)       speed = 100; // Priority 1
    else if (power_save)  speed = 10;  // Priority 2
    else                  speed = 50;  // Default
end
```
## Reset Bridge (Reset synchronizers for the asynchronous reset insertion and de-insertion)

## 1. The Circuit Structure
It consists of two Flip-Flops (FF) connected in a chain.

* **Clock:** Connected to the system clock.
* **Async Reset Input:** Connected directly to the Clear (CLR) or Preset (PRE) pins of both flip-flops.
* **Data Input (D):** The first flip-flop's D input is tied permanently to Logic '1' (VCC).
* **Output:** The output of the second flip-flop is your "Safe Reset."

## 2. Step-by-Step Operation
Let's trace exactly what happens to the electrons when you press and release the button.

## Scenario A: You PRESS the Reset Button (Assertion)
* **Action:** The external reset signal goes LOW (0).
* **Physics:** This 0 hits the asynchronous CLR pin of the flip-flops.
* **Reaction:** The flip-flops do not care about the clock. When the CLR pin is hit, they force their output Q to 0 instantly.
* **Result:** The entire system resets immediately. No waiting.

## Scenario B: You RELEASE the Reset Button (De-assertion)
* **Action:** The external reset signal goes back to HIGH (1).
* **The Danger Zone:** This release could happen at any random nanosecond. It might happen 0.01ns before a clock edge (Setup Violation) or 0.01ns after (Hold Violation). If we sent this raw signal to the 256 modules, half might see a '1' and half might see a '0'. Corruption!
* **The Bridge's Job:**
  * The CLR pin is released (goes High). The flip-flops are no longer forced to 0.
  * BUT, the output Q stays at 0. Why? Because a Flip-Flop only updates its output when the Clock ticks.
  * The Flip-Flop is currently "holding" the reset active (Low), waiting for permission to release it.
* **Clock Edge Arrives (Tick):**
  * **FF1:** Captures the permanent '1' at its input.
  * **FF2:** Captures the output of FF1.
* **Output:** The Q of FF2 goes to 1.
* **Result:** The reset signal transitions from 0 to 1 exactly aligned with the clock edge.

## 3. Why Two Flip-Flops? (The "Metastability" Guard)
You might ask, "Why not just use one flip-flop?"
If you release the reset button exactly at the same moment the clock ticks, the first flip-flop gets confused. It enters a state called **Metastability** (it vibrates between 0 and 1, or settles to a random value).

* **If we had 1 FF:** This garbage signal would go to your 256 modules. Some would reset, some wouldn't. Crash.
* **With 2 FFs:** If FF1 goes metastable, it usually settles down to a stable '0' or '1' within one clock cycle. By the time the next clock edge hits FF2, the signal is stable. FF2 sends a clean '0' or '1' to the system.

## Summary Checklist
* **Button Pressed:** Async pins force output Low immediately. (Fast)
* **Button Released:** Async pins let go, but FFs wait. (Pause)
* **Clock Ticks:** FFs clock in a '1'. (Sync)
* **Output:** The '1' travels to the Reset Tree perfectly aligned with the system clock.

## 4. The Reset Tree (The "Delivery System") **This topic comes when i want to provide reset to the 256 submodules from the top modules**

This concept is same for the **`asynchronous reset`** as well as the **`synchronous reset`**.
Once the Reset Bridge has created a clean, safe signal, we face a physical problem: **Distribution**.

* **The Problem (High Fanout):** A single Flip-Flop (the output of the Bridge) cannot electrically drive 256 wires. The signal would be too weak, rising slowly like a tired runner.
* **The Consequence (Skew):** If you try to drive everyone at once, the module closest to the bridge will get the reset at `Time = 0.1ns`, but the module at the far end of the chip might get it at `Time = 2.0ns`. This time difference is called **Skew**.
* **The Failure:** If the skew is larger than the clock period, different parts of your chip will be in different states (some reset, some running). This causes system failure.

## The Solution: The Buffer Pyramid
Instead of one big wire, we build a tree structure using **Buffers** (amplifiers).

### How to Build It (The Logic)
Imagine a pyramid structure:
1.  **Level 1 (The Root):** The Reset Bridge drives **4 Buffers**.
2.  **Level 2 (The Branches):** Each of those 4 buffers drives **4 more buffers** (Total 16).
3.  **Level 3 (The Twigs):** Each of those 16 buffers drives **4 more** (Total 64).
4.  **Level 4 (The Leaves):** Each of those 64 buffers drives **4 Modules** (Total 256).

### Why This Works
* **Strength:** Each buffer only has to drive 4 loads, so the signal stays sharp and strong (fast rise time).
* **Timing Balance:** Because every path goes through the exact same number of stages (4 stages), the delay to reach Module #1 is almost identical to the delay to reach Module #256.
* **Result:** The skew is minimized to near zero.

## When to Use a Reset Tree?
You generally need a reset tree when:
1.  **High Fanout:** You are driving more than ~20-50 flip-flops (varies by technology node).
2.  **Large Area:** Your modules are physically spread far apart on the silicon.
3.  **High Frequency:** At high speeds (GHz), even small delays (picoseconds) matter, so balancing the path is critical.

*Note: In modern EDA tools (Vivado/Design Compiler), you often don't write the tree in Verilog manually. You set a constraint called "Max Fanout," and the tool builds this tree for you automatically during synthesis.*

## Summary Checklist
* **Problem:** One signal cannot drive 256 loads (Fanout).
* **Risk:** The signal arrives at different times (Skew), causing crashes.
* **Solution:** A Pipelined Tree of buffers splits the load.
* **Outcome:** All 256 modules receive the reset signal at the **same time** with full signal strength.

**The End.**

