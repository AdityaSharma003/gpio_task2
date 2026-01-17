# Verilog Coding rules

## 1. The "Always" Rule

* **Rule:** If a signal is on the **left** side of an assignment inside an `always` block, it **MUST** be a `reg`.
* **Reason:** The `always` block implies "procedure" or "memory," so the variable must hold its value until the next update.
  
---

## 2. The "Assign" Rule

* **Rule:** If a signal is on the **left** side of an `assign` statement, it **MUST** be a `wire`.
* **Reason:** `assign` creates a permanent physical connection (like soldering a wire), not a storage memory.

---

## 3. The "Child-to-Parent" Rule

* **Rule:** When connecting a submodule's **output** to the parent module, the parent's receiving signal **MUST** be a `wire`.
* **Reason:** The submodule is already "driving" the signal. You cannot plug a hard driver directly into a storage bucket (`reg`).
---
## 4. The "Wire-then-Reg" Rule (The Fix)

* **Rule:** To store a submodule's output into a `reg`, you must first catch it with a `wire` in the parent's module, then copy it to the `reg` inside an `always` block.
* **Reason:** A `reg` can only have **one master** (the `always` block). If you connected the submodule directly to the `reg`, the submodule would try to fight the `always` block for control, causing a conflict as there is a difference in **who is doing the driving (writing)** versus **who is being read**.
---
## 5. The "Parent-to-Child" Rule

* **Rule:** When sending a signal **into** a submodule's input, the source can be a `reg` OR a `wire`.
* **Reason:** The submodule just listens to the voltage level; it doesn't care if that voltage comes from a register or a wire.

* Important Considerations for this rule shown in table as follows.

| Source of the Signal | Signal Type Needed? | Reason |
| :--- | :--- | :--- |
| **Generated in `always` block** | `reg` | Procedural assignments require storage (memory) to hold the value between events. |
| **Generated in `assign` statement** | `wire` | Continuous assignments represent a permanent physical connection, not storage. |
| **Comes from another submodule** | `wire` | The submodule is the "driver." You must use a wire to catch the signal output. |
| **Comes from Parent Input Port** | `wire` | You cannot write to your own input; you can only read from the wire connecting to the outside world. |

## 6. The "Input Port" Rule

* **Rule:** Inside a module definition, an `input` port is **ALWAYS** a `wire`.
* **Reason:** You cannot write to your own input; you only read from it.

## 7. The "Output Port" Rule

* **Rule:** Inside a module definition, an `output` port can be defined as `wire` (default) OR `reg`.
* **Reason:** Use `wire` if the value comes from combinational logic (`assign`). Use `reg` if the value is calculated in an `always` block.

### The Port connection type diagram for the reference (Samir Palnitkar)

![Port Connection Rule](Port_Connection_Rule.png)

## 8. Command to use for running the simulation of any verilog file
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
---

## 9. Design Architecture: Why do we want Registered Outputs from any module ?


1. **Timing Isolation (Breaking the Critical Path)**
   - **Without Registers:** If Module A outputs combinational logic and connects to Module B, the synthesis tool sees one giant, long path that stretches through A and into B. This long path might exceed the clock period, causing a timing violation.
   - **With Registers:** The timing path stops at the output of Module A. Module B sees a signal starting fresh from a Flip-Flop. This "isolates" the timing budget of Module A from Module B, making it much easier to meet timing requirements.

2. **Glitch Filtering (Signal Integrity)**
   - **Without Registers:** These glitches are sent out to the next module. If that module uses the signal for something sensitive (like a clock enable or asynchronous reset), the glitches can cause fatal errors.
   - **With Registers:** Output registers act as a filter. They ignore inter-clock transients and only capture data at the clock edge. This ensures that downstream modules receive clean, stable signals, preventing false triggers on sensitive lines (like resets or enables).

3. **Predictable Interface (Fixed Latency)**
   - **Why:** Registered outputs provide a constant **Clock-to-Q** delay.
   - **Benefit:** The output timing becomes deterministic and independent of the complexity of the internal logic cloud. This simplifies system-level integration and static timing analysis (STA).
  
---
  
## 10. Verilog Generate Block Guidelines

###  Overview

The `generate` construct allows you to create **variable hardware structures** at compile-time (elaboration time). It is used to:

1.  **Instantiate multiple copies** of a module (e.g., an array of adders).
2.  **Conditionally include/exclude logic** based on parameters (e.g., `if (FAST_MODE)`).

> **Crucial Concept:** Generate blocks work during **Elaboration**, not Simulation. You are telling the tool *what to build*, not telling the chip *what to do* while running.

---

### 5 Golden Rules

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

### Syntax Templates

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

---

## 11. MUX vs. Priority Encoder: A Digital Design Guide

In RTL design, the choice between `if-else` and `case` statements directly impacts the physical hardware synthesized by the tools. The resulting hardware is typically either a **Multiplexer (MUX)** or a **Priority Encoder**, depending on whether the conditions are **mutually exclusive**.

---

### 1. Core Synthesis Principles

| Logic Structure | Condition Nature | Synthesized Hardware | Hardware Behavior |
| :--- | :--- | :--- | :--- |
| **`case` statement** | Inherently Mutually Exclusive | **Multiplexer (MUX)** | Parallel evaluation; all inputs have equal weight. |
| **`if-else` (Exclusive)** | Mutually Exclusive | **Multiplexer (MUX)** | The tool recognizes only one condition can be true at a time. |
| **`if-else` (Overlapping)**| Not Mutually Exclusive | **Priority Encoder** | Chained logic; the first true condition inhibits the rest. |

---

### 2. The Multiplexer (MUX)

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

### 3. The Priority Encoder

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

---

## 12. Reset Bridge (Reset synchronizers for the asynchronous reset insertion and de-insertion)

### 1. The Circuit Structure
It consists of two Flip-Flops (FF) connected in a chain.

* **Clock:** Connected to the system clock.
* **Async Reset Input:** Connected directly to the Clear (CLR) or Preset (PRE) pins of both flip-flops.
* **Data Input (D):** The first flip-flop's D input is tied permanently to Logic '1' (VCC).
* **Output:** The output of the second flip-flop is your "Safe Reset."

### 2. Step-by-Step Operation
Let's trace exactly what happens to the electrons when you press and release the button.

### Scenario A: You PRESS the Reset Button (Assertion)
* **Action:** The external reset signal goes LOW (0).
* **Physics:** This 0 hits the asynchronous CLR pin of the flip-flops.
* **Reaction:** The flip-flops do not care about the clock. When the CLR pin is hit, they force their output Q to 0 instantly.
* **Result:** The entire system resets immediately. No waiting.

### Scenario B: You RELEASE the Reset Button (De-assertion)
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

### 3. Why Two Flip-Flops? (The "Metastability" Guard)
You might ask, "Why not just use one flip-flop?"
If you release the reset button exactly at the same moment the clock ticks, the first flip-flop gets confused. It enters a state called **Metastability** (it vibrates between 0 and 1, or settles to a random value).

* **If we had 1 FF:** This garbage signal would go to your 256 modules. Some would reset, some wouldn't. Crash.
* **With 2 FFs:** If FF1 goes metastable, it usually settles down to a stable '0' or '1' within one clock cycle. By the time the next clock edge hits FF2, the signal is stable. FF2 sends a clean '0' or '1' to the system.

### Summary Checklist
* **Button Pressed:** Async pins force output Low immediately. (Fast)
* **Button Released:** Async pins let go, but FFs wait. (Pause)
* **Clock Ticks:** FFs clock in a '1'. (Sync)
* **Output:** The '1' travels to the Reset Tree perfectly aligned with the system clock.

### 4. The Reset Tree (The "Delivery System") **This topic comes when i want to provide reset to the 256 submodules from the top modules**

This concept is same for the **`asynchronous reset`** as well as the **`synchronous reset`**.
Once the Reset Bridge has created a clean, safe signal, we face a physical problem: **Distribution**.

* **The Problem (High Fanout):** A single Flip-Flop (the output of the Bridge) cannot electrically drive 256 wires. The signal would be too weak, rising slowly like a tired runner.
* **The Consequence (Skew):** If you try to drive everyone at once, the module closest to the bridge will get the reset at `Time = 0.1ns`, but the module at the far end of the chip might get it at `Time = 2.0ns`. This time difference is called **Skew**.
* **The Failure:** If the skew is larger than the clock period, different parts of your chip will be in different states (some reset, some running). This causes system failure.

### The Solution: The Buffer Pyramid
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

### When to Use a Reset Tree?
You generally need a reset tree when:
1.  **High Fanout:** You are driving more than ~20-50 flip-flops (varies by technology node).
2.  **Large Area:** Your modules are physically spread far apart on the silicon.
3.  **High Frequency:** At high speeds (GHz), even small delays (picoseconds) matter, so balancing the path is critical.

*Note: In modern EDA tools (Vivado/Design Compiler), you often don't write the tree in Verilog manually. You set a constraint called "Max Fanout," and the tool builds this tree for you automatically during synthesis.*

### Summary Checklist
* **Problem:** One signal cannot drive 256 loads (Fanout).
* **Risk:** The signal arrives at different times (Skew), causing crashes.
* **Solution:** A Pipelined Tree of buffers splits the load.
* **Outcome:** All 256 modules receive the reset signal at the **same time** with full signal strength.
---
## 13. Difference between usage of blocking and non-blocking assignment in verilog

This is the "secret engine" of Verilog. To understand why we pick `=` vs `<=`, you have to understand exactly what happens inside a single **Time Step**.

A "Time Step" in Verilog (like T=10ns) is not a single instant. It is a bucket of prioritized to-do lists.

### Part 1: Anatomy of a Time Step (The Event Queue)

When the simulator reaches a specific time (e.g., 10ns), it pauses the clock and performs tasks in a strict order. This order is called the **Stratified Event Queue**.

Think of it as a **3-Phase Process** happening instantly at T=10ns:

### Phase 1: The Active Region (Calculation)
* This is where **Blocking Assignments (`=`)** happen.
* This is where **Logic Calculation** happens (Evaluating RHS of equations).
* The simulator runs everything here until there is nothing left to do.

### Phase 2: The Inactive Region
* Rarely used, mostly for `#0` delays.

### Phase 3: The NBA Region (Update)
* **NBA** stands for Non-Blocking Assignment.
* This is where the updates scheduled by **`<=`** finally happen.
* **Crucially:** This happens **after** all calculations in Phase 1 are finished.

> **"End of the Time Step"** simply means: Phase 1, 2, and 3 are all empty. The simulator is now allowed to advance the clock to T=11ns.

---

### Part 2: Why Blocking (`=`) for Combinational Logic?

**The Goal:** We want "Chain Reactions." If I change A, B should change instantly so C can use it.

### The Code:
```verilog
always @(*) begin
    b = a + 1;  // Line 1
    c = b + 1;  // Line 2
end
```

### How it executes in the Time Step:
**Active Region (Phase 1):**
1. **Execute Line 1:** `b` is updated to `a+1` immediately.
2. **Execute Line 2:** The simulator reads the new value of `b` and updates `c`.

**Result:** Correct. `c` equals `a+2`. This mimics electricity flowing through gates.

---

### What if we used Non-Blocking (<=)?
```verilog
always @(*) begin
    b <= a + 1; // Schedule update for Phase 3
    c <= b + 1; // Read OLD 'b' (from Phase 1)
end
```
### How it executes in the Time Step:

**Active Region (Phase 1):**
* **Line 1:** Calculate `a+1`, but wait. Do not update `b` yet.
* **Line 2:** Calculate `b+1` using the **OLD** value of `b` (because `b` hasn't changed yet!). Schedule `c`.

**NBA Region (Phase 3):**
* Now update `b` and `c`.

**The Problem:** `c` was calculated using stale data. The simulator now sees `b` changed, so it triggers the `always` block again (**Delta Cycle**). It eventually fixes itself, but it’s slow and error-prone.

---

### Part 3: Why Non-Blocking (<=) for Sequential Logic?

**The Goal:** We want "Snapshots." All Flip-Flops must change together using data from the start of the clock cycle.

```verilog
always @(posedge clk) begin
    q2 <= q1; // Capture q1
    q1 <= in; // Capture in
end
```

### How it executes in the Time Step:

**Active Region (Phase 1):**
1. **Execute Line 1:** Read `q1`'s current value. Calculate the result. Do not write to `q2` yet. Throw the result into the **NBA bucket**.
2. **Execute Line 2:** Read `in`'s current value. Do not write to `q1` yet. Throw result into **NBA bucket**.

**NBA Region (Phase 3):**
* All calculations are done. Now, dump the buckets.
* Update `q2` with the old `q1`.
* Update `q1` with `in`.

**Result:** **Perfect Shift.** `q2` got the old `q1` before `q1` was overwritten.

---

### What if we used Blocking (=)?

```verilog
always @(posedge clk) begin
    q1 = in; // Update q1 IMMEDIATELY in Phase 1
    q2 = q1; // Read the NEW q1 immediately
end
```

**Active Region (Phase 1):**
* **Line 1:** `q1` becomes `in` right now.
* **Line 2:** `q2` reads `q1`. Since `q1` just changed, `q2` becomes `in` too.

**Result:** **Race Condition / Logic Error.** You wanted to shift `in -> q1 -> q2`. Instead, you short-circuited `in -> q2`. You lost data.

---

### Summary Visualization

| Assignment | Logic Type | Phase executed in | Why? |
| :--- | :--- | :--- | :--- |
| **Blocking (=)** | Combinational | **Phase 1 (Active)** | We need immediate results for the next line of code (like a continuous wire). |
| **Non-Blocking (<=)** | Sequential | **Phase 3 (NBA)** | We need to "read first, write later" to safely swap data between registers without races. |

## 14. The Simulation-Synthesis Mismatch

A mismatch occurs when the behavior of your **RTL Simulation** does not match the behavior of the **Physical Hardware** produced by synthesis. This is a critical failure because your "verified" design will break when programmed onto an FPGA or chip.

### Example: The Blocking Race Condition
If you use blocking assignments (`=`) in a sequential block, you create a disaster.

```verilog
always @(posedge clk) begin
    B = A; 
    C = B; 
end
```

| Environment | Behavior | Result |
| :--- | :--- | :--- |
| **Simulation** | Executes line-by-line. B updates, then C immediately reads the **new** B. | Data moves from A to C in **1 clock cycle**. |
| **Synthesis** | Hardware is parallel. C captures the **old** value of B because of physical setup/hold requirements. | Data moves from A to C in **2 clock cycles**. |



---

### Misuse of Non-Blocking Assignments in Combinational Logic
Using non-blocking assignments (`<=`) in combinational blocks creates "Delta Cycle" delays that don't exist in real wires.
```verilog
// BAD CODE: Using NBA in combinational logic
always @(*) begin
    temp <= a & b;    // Scheduled for NBA Region
    out  <= temp | c; // Reads OLD value of temp
end
```
#### The Mismatch Breakdown
* **In Simulation**: When `a` changes, `temp` is scheduled to update at the end of the time step. The second line reads the **old** value of `temp` that existed before the change. The simulator then has to trigger the block a second time to settle on the right value.
* **In Synthesis**: The tool creates a direct gate-level connection. It assumes `temp` and `out` update as fast as the electrons can move through the gates. It does not implement a "wait until the end of the step" mechanism.
* **Result**: Simulation might show a temporary "glitch" or a delayed response that the physical hardware does not have.

*That's why it's better to use `=` blocking assignment in the **combinational procedural block** and `<=` non-blocking assignment in the **sequential procedural block**.*

**The End.**

