# 5-Stage Pipelined Processor (VHDL)

## Project Overview
This repository contains the design and implementation of a **custom 5-stage pipelined RISC-like processor** developed as part of the **Computer Architecture course** at the **Faculty of Engineering, Cairo University**.

The processor follows a **Von-Neumann architecture** with a shared instruction/data memory and is implemented **entirely in VHDL**, starting from ISA definition up to full pipeline integration, hazard handling, and verification.

The goal of the project was not only to make the processor functional, but to make it **cycle-accurate, pipelined, and robust against real architectural hazards**.

---

## Processor Architecture

### Pipeline Stages
The processor is divided into the classic 5 pipeline stages:

1. **IF – Instruction Fetch**
   - Fetches instruction from memory
   - Updates PC
   - Handles immediate fetching when required

2. **ID – Instruction Decode**
   - Decodes opcode and operands
   - Reads register file
   - Generates control signals
   - Immediate sign extension

3. **EX – Execute**
   - ALU operations
   - Branch condition evaluation
   - Effective address calculation
   - Forwarding selection

4. **MEM – Memory Access**
   - Load / Store operations
   - Stack operations (PUSH, POP, CALL, INT)
   - Interrupt handling

5. **WB – Write Back**
   - Writes ALU or memory results back to registers
   - Updates output port when required

Pipeline registers exist between all stages to preserve data and control flow.

---

## Instruction Set Architecture (ISA)

### Registers
- **8 General Purpose Registers**: `R0 – R7` (32-bit)
- **Special Registers**:
  - Program Counter (PC)
  - Stack Pointer (SP)
  - Condition Code Register (CCR):  
    - `Z` (Zero)  
    - `N` (Negative)  
    - `C` (Carry)

### Instruction Categories
#### 1. Arithmetic & Logical
- `ADD`, `SUB`, `AND`
- `IADD`
- `INC`, `NOT`
- `SETC`

#### 2. Data Movement
- `MOV`
- `SWAP`
- `IN`, `OUT`

#### 3. Memory Operations
- `LDM` (Load Immediate)
- `LDD`, `STD`
- `PUSH`, `POP`

#### 4. Control Flow
- `JMP`
- `JZ`, `JN`, `JC`
- `CALL`, `RET`

#### 5. Interrupts
- `INT`
- `RTI`

#### 6. System
- `NOP`
- `HLT`

 Some instructions occupy **multiple memory locations**, especially immediate-based instructions.

---

## Pipeline Hazard Handling

A major focus of this project was **correct pipeline behavior** under all hazard scenarios.

### Data Hazards
- **ALU → ALU forwarding**
- **MEM → ALU forwarding**
- Forwarding applied to:
  - ALU operands
  - Store data

### Load-Use Hazards
- Detected using source/destination register comparison
- Pipeline response:
  - PC Stall
  - IF/ID Stall
  - ID/EX Flush

### Control Hazards
- Branch and jump instructions handled via:
  - Pipeline flushing
  - Correct PC redirection
- CALL, RET, and RTI supported with stack-based control flow

### Structural & Special Hazards
- Shared instruction/data memory conflicts
- Immediate-fetch hazard handling
- Multi-cycle `SWAP` instruction:
  - Controlled stalling for correct execution
- Stack pointer hazards during PUSH/POP/CALL/INT

All hazards are handled using a dedicated **Hazard Detection Unit** and **Forwarding Unit**.

---

## Interrupt Handling
- Supports **non-maskable interrupts**
- On interrupt:
  - Current PC is pushed onto the stack
  - Control jumps to interrupt handler address
- `RTI` instruction:
  - Restores PC and flags
  - Resumes normal program execution

Corner cases (e.g., interrupts during branching) are handled correctly.

---

## Assembler
A custom assembler was implemented to:
- Translate assembly programs into machine code
- Generate memory initialization files
- Support all ISA instructions and addressing modes

This allows writing and testing real assembly programs on the processor.

---



## 🙏 Acknowledgments
Special thanks to the course instructors and teaching assistants for their guidance, feedback, and continuous support throughout the project.
