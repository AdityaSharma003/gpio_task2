## RISC-V RV32I Instruction Set Architecture

This processor implements the **RV32I** (Base Integer) instruction set. The instructions are fixed at 32 bits wide and are classified into six basic formats.

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
    * *Note:* The immediate is complexly scrambled to optimize hardware fanout.
* **U-Type (Upper):** `imm[31:12]` | `rd` | `opcode`
    * *Usage:* Used for LUI and AUIPC (Upper 20 bits).
* **J-Type (Jump):** `imm[20|10:1|11|19:12]` | `rd` | `opcode`
    * *Usage:* Used for JAL (Unconditional Jump).

---

### 3. Complete Instruction List

#### A. Integer Computational (Math & Logic)
*Operations using registers or small constants. Result is stored in `rd`.*

| Instruction | Type | Description | Operation |
| :--- | :---: | :--- | :--- |
| **ADD** | R | Add | `rd = rs1 + rs2` |
| **SUB** | R | Subtract | `rd = rs1 - rs2` |
| **SLL** | R | Shift Left Logical | `rd = rs1 << rs2` |
| **SLT** | R | Set Less Than (Signed) | `rd = (rs1 < rs2) ? 1 : 0` |
| **SLTU** | R | Set Less Than Unsigned | `rd = (rs1 < rs2) ? 1 : 0` |
| **XOR** | R | Exclusive OR | `rd = rs1 ^ rs2` |
| **SRL** | R | Shift Right Logical | `rd = rs1 >> rs2` |
| **SRA** | R | Shift Right Arithmetic | `rd = rs1 >> rs2` (Sign Extended) |
| **OR** | R | OR | `rd = rs1 \| rs2` |
| **AND** | R | AND | `rd = rs1 & rs2` |
| **ADDI** | I | Add Immediate | `rd = rs1 + imm` |
| **SLTI** | I | Set Less Than Imm (Signed) | `rd = (rs1 < imm) ? 1 : 0` |
| **SLTIU** | I | Set Less Than Imm Unsigned | `rd = (rs1 < imm) ? 1 : 0` |
| **XORI** | I | XOR Immediate | `rd = rs1 ^ imm` |
| **ORI** | I | OR Immediate | `rd = rs1 \| imm` |
| **ANDI** | I | AND Immediate | `rd = rs1 & imm` |
| **SLLI** | I | Shift Left Logical Imm | `rd = rs1 << imm` |
| **SRLI** | I | Shift Right Logical Imm | `rd = rs1 >> imm` |
| **SRAI** | I | Shift Right Arithmetic Imm | `rd = rs1 >> imm` (Sign Extended) |

#### B. Load & Store (Memory Access)
*Transfer data between registers and memory. Address = `rs1 + imm`.*

| Instruction | Type | Description | Operation |
| :--- | :---: | :--- | :--- |
| **LB** | I | Load Byte | `rd = Mem[Addr][7:0]` (Sign Ext) |
| **LH** | I | Load Halfword | `rd = Mem[Addr][15:0]` (Sign Ext) |
| **LW** | I | Load Word | `rd = Mem[Addr][31:0]` |
| **LBU** | I | Load Byte Unsigned | `rd = Mem[Addr][7:0]` (Zero Ext) |
| **LHU** | I | Load Halfword Unsigned | `rd = Mem[Addr][15:0]` (Zero Ext) |
| **SB** | S | Store Byte | `Mem[Addr][7:0] = rs2[7:0]` |
| **SH** | S | Store Halfword | `Mem[Addr][15:0] = rs2[15:0]` |
| **SW** | S | Store Word | `Mem[Addr][31:0] = rs2` |

#### C. Control Transfer (Jumps & Branches)
*Modifying the Program Counter (PC).*

| Instruction | Type | Description | Operation |
| :--- | :---: | :--- | :--- |
| **JAL** | J | Jump and Link | `rd = PC+4; PC += imm` |
| **JALR** | I | Jump and Link Register | `rd = PC+4; PC = rs1 + imm` |
| **BEQ** | B | Branch Equal | `if(rs1 == rs2) PC += imm` |
| **BNE** | B | Branch Not Equal | `if(rs1 != rs2) PC += imm` |
| **BLT** | B | Branch Less Than (Signed) | `if(rs1 < rs2) PC += imm` |
| **BGE** | B | Branch Greater/Equal (Signed) | `if(rs1 >= rs2) PC += imm` |
| **BLTU** | B | Branch Less Than (Unsigned) | `if(rs1 < rs2) PC += imm` |
| **BGEU** | B | Branch Greater/Equal (Unsigned) | `if(rs1 >= rs2) PC += imm` |

#### D. Upper Immediate
*Building large constants.*

| Instruction | Type | Description | Operation |
| :--- | :---: | :--- | :--- |
| **LUI** | U | Load Upper Immediate | `rd = imm << 12` |
| **AUIPC** | U | Add Upper Imm to PC | `rd = PC + (imm << 12)` |

#### E. System
*Synchronization and Operating System traps.*

| Instruction | Type | Description |
| :--- | :---: | :--- |
| **ECALL** | I | Environment Call (System Call) |
| **EBREAK** | I | Environment Break (Debugger) |
| **FENCE** | I | Memory Ordering Fence |

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
