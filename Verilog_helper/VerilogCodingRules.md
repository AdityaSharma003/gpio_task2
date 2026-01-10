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

### Design Architecture: Why do we want Registered Outputs from any module ?


1. **Timing Isolation (Breaking the Critical Path)**
   - **Without Registers:** If Module A outputs combinational logic and connects to Module B, the synthesis tool sees one giant, long path that stretches through A and into B. This long path might exceed the clock period, causing a timing violation.
   - **With Registers:** The timing path stops at the output of Module A. Module B sees a signal starting fresh from a Flip-Flop. This "isolates" the timing budget of Module A from Module B, making it much easier to meet timing requirements.

2. **Glitch Filtering (Signal Integrity)**
   - **Without Registers:** These glitches are sent out to the next module. If that module uses the signal for something sensitive (like a clock enable or asynchronous reset), the glitches can cause fatal errors.
   - **With Registers:** Output registers act as a filter. They ignore inter-clock transients and only capture data at the clock edge. This ensures that downstream modules receive clean, stable signals, preventing false triggers on sensitive lines (like resets or enables).

3. **Predictable Interface (Fixed Latency)**
   - **Why:** Registered outputs provide a constant **Clock-to-Q** delay.
   - **Benefit:** The output timing becomes deterministic and independent of the complexity of the internal logic cloud. This simplifies system-level integration and static timing analysis (STA).
  
  
### Verilog Generate Block Guidelines

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

**The End.**

