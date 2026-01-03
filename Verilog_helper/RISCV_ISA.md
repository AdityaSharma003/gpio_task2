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
