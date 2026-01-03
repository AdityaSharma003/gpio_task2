## RISC-V RV32I Instruction Set Architecture

This processor implements the **RV32I** (Base Integer) instruction set. The instructions are fixed at 32 bits wide.

### 1. Instruction Fields
The following fields are used across the different instruction formats:

* **opcode (7 bits):** Determines the basic operation type.
* **rd (5 bits):** Destination Register (where the result goes).
* **funct3 (3 bits):** A 3-bit code to distinguish instructions sharing the same opcode.
* **rs1 (5 bits):** Source Register 1.
* **rs2 (5 bits):** Source Register 2.
* **funct7 (7 bits):** A 7-bit code for further distinction (used in R-Type).
* **imm:** Immediate value (constant data embedded in the instruction).

### 2. Instruction Format Structures
The arrangement of bits for each format is as follows (from MSB to LSB):

* **R-Type (Register):** `funct7` | `rs2` | `rs1` | `funct3` | `rd` | `opcode`
    * *Usage:* Math and logic operations between two registers.
* **I-Type (Immediate):** `imm[11:0]` | `rs1` | `funct3` | `rd` | `opcode`
    * *Usage:* Loading values, small constants, and JALR.
* **S-Type (Store):** `imm[11:5]` | `rs2` | `rs1` | `funct3` | `imm[4:0]` | `opcode`
    * *Note:* The immediate is split into two parts.
* **B-Type (Branch):** `imm[12|10:5]` | `rs2` | `rs1` | `funct3` | `imm[4:1|11]` | `opcode`
    * *Note:* The immediate is scrambled to optimize hardware fanout.
* **U-Type (Upper):** `imm[31:12]` | `rd` | `opcode`
    * *Usage:* LUI and AUIPC (Upper 20 bits).
* **J-Type (Jump):** `imm[20|10:1|11|19:12]` | `rd` | `opcode`
    * *Usage:* JAL (Unconditional Jump).

---

### 3. Complete Instruction List

#### A. Integer Computational (Math & Logic)
*Operations using registers or small constants. Result is stored in `rd`.*
*(Example Registers: x1=rd, x2=rs1, x3=rs2)*

| Instruction | Type | Description | Operation | Example Assembly | Machine Code (Hex) |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **ADD** | R | Add | `rd = rs1 + rs2` | `add x1, x2, x3` | `003100B3` |
| **SUB** | R | Subtract | `rd = rs1 - rs2` | `sub x1, x2, x3` | `403100B3` |
| **SLL** | R | Shift Left Logical | `rd = rs1 << rs2` | `sll x1, x2, x3` | `003110B3` |
| **SLT** | R | Set Less Than (Signed) | `rd = (rs1 < rs2) ? 1 : 0` | `slt x1, x2, x3` | `003120B3` |
| **SLTU** | R | Set Less Than Unsigned | `rd = (rs1 < rs2) ? 1 : 0` | `sltu x1, x2, x3` | `003130B3` |
| **XOR** | R | Exclusive OR | `rd = rs1 ^ rs2` | `xor x1, x2, x3` | `003140B3` |
| **SRL** | R | Shift Right Logical | `rd = rs1 >> rs2` | `srl x1, x2, x3` | `003150B3` |
| **SRA** | R | Shift Right Arithmetic | `rd = rs1 >> rs2` (Sign Ext) | `sra x1, x2, x3` | `403150B3` |
| **OR** | R | OR | `rd = rs1 \| rs2` | `or x1, x2, x3` | `003160B3` |
| **AND** | R | AND | `rd = rs1 & rs2` | `and x1, x2, x3` | `003170B3` |
| **ADDI** | I | Add Immediate | `rd = rs1 + imm` | `addi x1, x2, 10` | `00A10093` |
| **SLTI** | I | Set Less Than Imm (Signed) | `rd = (rs1 < imm) ? 1 : 0` | `slti x1, x2, -5` | `FFB12093` |
| **SLTIU** | I | Set Less Than Imm Uns. | `rd = (rs1 < imm) ? 1 : 0` | `sltiu x1, x2, 10` | `00A13093` |
| **XORI** | I | XOR Immediate | `rd = rs1 ^ imm` | `xori x1, x2, 15` | `00F14093` |
| **ORI** | I | OR Immediate | `rd = rs1 \| imm` | `ori x1, x2, 15` | `00F16093` |
| **ANDI** | I | AND Immediate | `rd = rs1 & imm` | `andi x1, x2, 15` | `00F17093` |
| **SLLI** | I | Shift Left Logical Imm | `rd = rs1 << imm` | `slli x1, x2, 2` | `00211093` |
| **SRLI** | I | Shift Right Logical Imm | `rd = rs1 >> imm` | `srli x1, x2, 2` | `00215093` |
| **SRAI** | I | Shift Right Arith Imm | `rd = rs1 >> imm` (Sign Ext) | `srai x1, x2, 2` | `40215093` |

#### B. Load & Store (Memory Access)
*Transfer data between registers and memory. Address = `rs1 + imm`.*
*(Example Registers: x1=rd/src, x2=base)*

| Instruction | Type | Description | Operation | Example Assembly | Machine Code (Hex) |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **LB** | I | Load Byte | `rd = Mem[Addr][7:0]` | `lb x1, 4(x2)` | `00410083` |
| **LH** | I | Load Halfword | `rd = Mem[Addr][15:0]` | `lh x1, 4(x2)` | `00411083` |
| **LW** | I | Load Word | `rd = Mem[Addr][31:0]` | `lw x1, 4(x2)` | `00412083` |
| **LBU** | I | Load Byte Unsigned | `rd = Mem[Addr][7:0]` (Zero) | `lbu x1, 4(x2)` | `00414083` |
| **LHU** | I | Load Halfword Unsigned | `rd = Mem[Addr][15:0]` (Zero) | `lhu x1, 4(x2)` | `00415083` |
| **SB** | S | Store Byte | `Mem[Addr][7:0] = rs2` | `sb x1, 4(x2)` | `00110223` |
| **SH** | S | Store Halfword | `Mem[Addr][15:0] = rs2` | `sh x1, 4(x2)` | `00111223` |
| **SW** | S | Store Word | `Mem[Addr][31:0] = rs2` | `sw x1, 4(x2)` | `00112223` |

#### C. Control Transfer (Jumps & Branches)
*Modifying the Program Counter (PC).*

| Instruction | Type | Description | Operation | Example Assembly | Machine Code (Hex) |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **JAL** | J | Jump and Link | `rd = PC+4; PC += imm` | `jal x1, 16` | `010000EF` |
| **JALR** | I | Jump and Link Register | `rd = PC+4; PC = rs1 + imm` | `jalr x1, 0(x2)` | `00010067` |
| **BEQ** | B | Branch Equal | `if(rs1 == rs2) PC += imm` | `beq x1, x2, 8` | `00208463` |
| **BNE** | B | Branch Not Equal | `if(rs1 != rs2) PC += imm` | `bne x1, x2, 8` | `00209463` |
| **BLT** | B | Branch Less Than (S) | `if(rs1 < rs2) PC += imm` | `blt x1, x2, 8` | `0020C463` |
| **BGE** | B | Branch Greater/Equal (S) | `if(rs1 >= rs2) PC += imm` | `bge x1, x2, 8` | `0020D463` |
| **BLTU** | B | Branch Less Than (U) | `if(rs1 < rs2) PC += imm` | `bltu x1, x2, 8` | `0020E463` |
| **BGEU** | B | Branch Greater/Equal (U) | `if(rs1 >= rs2) PC += imm` | `bgeu x1, x2, 8` | `0020F463` |

#### D. Upper Immediate & System
*Large constants and System interactions.*

| Instruction | Type | Description | Operation | Example Assembly | Machine Code (Hex) |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **LUI** | U | Load Upper Immediate | `rd = imm << 12` | `lui x5, 0x20000` | **`200002B7`** |
| **AUIPC** | U | Add Upper Imm to PC | `rd = PC + (imm << 12)` | `auipc x1, 0x10000` | `10000097` |
| **ECALL** | I | Environment Call | Trap to OS | `ecall` | `00000073` |
| **EBREAK** | I | Environment Break | Trap to Debugger | `ebreak` | `00100073` |
| **FENCE** | I | Memory Fence | Memory Ordering | `fence` | `0FF0000F` |

---

### 4. Verilog Decoding Logic
The processor decodes these instructions by checking the 7-bit `opcode` field (`instr[6:0]`).

```verilog
wire isALUreg = (instr[6:0] == 7'b0110011); // R-Type
wire isALUimm = (instr[6:0] == 7'b0010011); // I-Type (Math)
wire isLoad   = (instr[6:0] == 7'b0000011); // I-Type (Load)
wire isStore  = (instr[6:0] == 7'b0100011); // S-Type
wire isBranch = (instr[6:0] == 7'b1100011); // B-Type
wire isJAL    = (instr[6:0] == 7'b1101111); // J-Type
wire isJALR   = (instr[6:0] == 7'b1100111); // I-Type (Jump)
wire isLUI    = (instr[6:0] == 7'b0110111); // U-Type
wire isAUIPC  = (instr[6:0] == 7'b0010111); // U-Type
wire isSYSTEM = (instr[6:0] == 7'b1110011); // I-Type (System)
```
### 5. Immediate Decoding Logic (Bit Scrambling)

In RISC-V, the Immediate values (constants) are embedded inside the 32-bit instruction. However, to keep the hardware simple, the bits are often "scrambled" or split into different positions.

The processor must unscramble these bits and **sign-extend** them to 32 bits before using them.

Here is the Verilog logic used to reconstruct the full 32-bit immediate from the `instr` bits:

| Type | Verilog Decoding Logic | Explanation |
| :--- | :--- | :--- |
| **U-Type** | `Uimm = {instr[31], instr[30:12], {12{1'b0}}};` | **Upper 20 bits.** <br>Places the top 20 bits into the MSBs and fills the lower 12 bits with zeros. Used for `LUI`. |
| **I-Type** | `Iimm = {{21{instr[31]}}, instr[30:20]};` | **12-bit Sign Extended.** <br>Takes the top 12 bits `instr[31:20]` and repeats the sign bit (bit 31) to fill the upper 20 bits. |
| **S-Type** | `Simm = {{21{instr[31]}}, instr[30:25], instr[11:7]};` | **Split 12-bit.** <br>The immediate is split into two chunks in the instruction (`[30:25]` and `[11:7]`) but combined here to form a standard 12-bit value. |
| **B-Type** | `Bimm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};` | **Scrambled Branch Offset.** <br>Similar to S-Type, but the bits are rotated to optimize hardware paths. <br>**Note:** Ends with `1'b0` because jump targets must be 2-byte aligned. |
| **J-Type** | `Jimm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};` | **Scrambled Jump Offset.** <br>A complex shuffle of the top 20 bits. Also ends with `1'b0` for alignment. |

**Key Concept: Sign Extension `{{N{instr[31]}}`**
* Because immediates can be negative (e.g., jumping backwards ` -4`), we must fill the empty upper bits with the sign bit (`0` for positive, `1` for negative).
* Example: If the 12-bit immediate is `-1` (`111...1`), the 32-bit result must be `0xFFFFFFFF`, not `0x00000FFF`.


---


### Detailed Instruction Execution Logic 

This section explains exactly what happens inside the processor for each instruction type through the help of the examples.

### 1. R-Type (Register Operations)
*Used for arithmetic and logic between two registers.*

* **Instruction:** `ADD x1, x2, x3`
* **Logic:** `x1 = x2 + x3`
* **Why?** The core calculation engine. It takes two known values, computes a result, and saves it.

**Example Scenario:**
Assume `x2` holds `5` and `x3` holds `7`.
1.  **Fetch:** Processor reads `ADD x1, x2, x3`.
2.  **Read Regs:** It reads the values `5` (from x2) and `7` (from x3).
3.  **Execute:** ALU calculates `5 + 7 = 12`.
4.  **Write Back:** The value `12` is written into register `x1`.



---

### 2. I-Type (Immediate Operations)
*Used for math with constants or loading data.*

#### Case A: Arithmetic (`ADDI`)
* **Instruction:** `ADDI x1, x2, 10`
* **Logic:** `x1 = x2 + 10`
* **Why?** Often used to increment counters (i++) or set initial values.

**Example Scenario:**
Assume `x2` holds `5`.
1.  **Execute:** ALU calculates `5 + 10 = 15`.
2.  **Write Back:** `15` is written to `x1`.

#### Case B: Loads (`LW`)
* **Instruction:** `LW x1, 4(x2)`
* **Logic:** `x1 = Memory[x2 + 4]`
* **Why?** To bring data from RAM into the CPU so we can work on it.

**Example Scenario:**
Assume `x2` points to RAM address `1000`. Memory at `1004` contains the value `99`.
1.  **Calculate Addr:** ALU adds Base (`1000`) + Offset (`4`) = `1004`.
2.  **Mem Read:** Processor asks RAM for the value at address `1004`.
3.  **Write Back:** RAM returns `99`. Processor writes `99` into `x1`.



---

### 3. S-Type (Store Operations)
*Used to save data from a register back to memory.*

* **Instruction:** `SW x1, 8(x2)`
* **Logic:** `Memory[x2 + 8] = x1`
* **Why?** To save your results (like saving a file) or controlling peripherals (like turning on an LED).

**Example Scenario:**
Assume `x1` holds value `0xFF` (Result) and `x2` is `2000` (Base Address).
1.  **Calculate Addr:** ALU adds `2000 + 8 = 2008`.
2.  **Mem Write:** Processor sends the address `2008` and the data `0xFF` to the memory bus.
3.  **Update:** The RAM cell at `2008` is overwritten with `0xFF`. Registers are *not* changed.

---

### 4. B-Type (Conditional Branch)
*Used for `if` statements and `loops`.*

* **Instruction:** `BEQ x1, x2, 16`
* **Logic:** `if (x1 == x2) PC = PC + 16`
* **Why?** Allows the program to make decisions based on data.

**Example Scenario (Taken):**
`PC` is currently `100`. `x1` is `5`, `x2` is `5`.
1.  **Compare:** ALU subtracts `x1 - x2`. result is `0` (Equal).
2.  **Decision:** Since they are equal, the branch is **Taken**.
3.  **Update PC:** `PC` becomes `100 + 16 = 116`. Execution jumps.

**Example Scenario (Not Taken):**
`x1` is `5`, `x2` is `9`.
1.  **Compare:** ALU finds they are not equal.
2.  **Decision:** Branch is **Not Taken**.
3.  **Update PC:** `PC` becomes `100 + 4` (Just goes to the very next instruction).

---

### 5. U-Type (Upper Immediate)
*Used to build large numbers (20 bits at a time).*

* **Instruction:** `LUI x1, 0x12345`
* **Logic:** `x1 = 0x12345 << 12`
* **Why?** Instructions are only 32 bits. You can't fit a 32-bit constant inside a 32-bit instruction. U-Type handles the top half.

**Example Scenario:**
1.  **Shift:** The immediate `0x12345` is shifted left by 12 bits -> `0x12345000`.
2.  **Write Back:** `x1` becomes `0x12345000`.
3.  *(Usually followed by an `ADDI` to fill in the lower 12 bits).*

---

### 6. J-Type (Jump and Link)
*Used for Function Calls.*

* **Instruction:** `JAL x1, 400`
* **Logic:** `x1 = PC + 4; PC = PC + 400`
* **Why?** "Jump" to a function, but "Link" (save a bookmark) so we know how to return.

**Example Scenario:**
Current `PC` is `1000`. We want to call a function at `1400`.
1.  **Link (Bookmark):** Save `1000 + 4 = 1004` into `x1`. (This is where we will return later).
2.  **Jump:** Add `1000 + 400 = 1400`. Set `PC` to `1400`.
3.  **Result:** The processor is now executing code at `1400`, but `x1` remembers we came from `1000`.

---

**The End**
