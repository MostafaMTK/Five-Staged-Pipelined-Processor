#!/usr/bin/env python3
"""
RISC Processor Assembler - Complete System
Converts assembly code to machine code (.mem format)
Compatible with VHDL memory loader

Author: Architecture Project
Date: 2025
"""

import re
import sys
from typing import Dict, List, Tuple, Optional

class RISCAssembler:
    def __init__(self):
        # Instruction opcodes (5 bits)
        self.opcodes = {
            # Type 1 - One Operand
            'NOP': '00000',
            'HLT': '00001',
            'SETC': '00010',
            'NOT': '00011',
            'INC': '00100',
            'OUT': '00101',
            'IN': '00110',
            
            # Type 2 - Two Operands
            'MOV': '01000',
            'SWAP': '01001',
            'ADD': '01010',
            'SUB': '01011',
            'AND': '01100',
            'IADD': '01101',
            
            # Type 3 - Memory Operations
            'PUSH': '10000',
            'POP': '10001',
            'LDM': '10010',
            'LDD': '10011',
            'STD': '10100',
            
            # Type 4 - Branch and Control
            'JZ': '11000',
            'JN': '11001',
            'JC': '11010',
            'JMP': '11011',
            'CALL': '11100',
            'RET': '11101',
            'INT': '11110',
            'RTI': '11111'
        }
        
        # Register mapping (3 bits)
        self.registers = {
            'R0': '000', 'R1': '001', 'R2': '010', 'R3': '011',
            'R4': '100', 'R5': '101', 'R6': '110', 'R7': '111'
        }
        
        # Instruction classification
        self.type1_no_op = ['NOP', 'HLT', 'SETC']
        self.type1_one_op = ['NOT', 'INC', 'IN']
        self.type1_one_op_special = ['OUT']
        self.type2_two_op = ['MOV', 'SWAP']
        self.type2_three_op = ['ADD', 'SUB', 'AND']
        self.type2_imm = ['IADD']
        self.type3_single = ['PUSH', 'POP']
        self.type3_imm = ['LDM']
        self.type3_offset = ['LDD', 'STD']
        self.type4_imm = ['JZ', 'JN', 'JC', 'JMP', 'CALL']
        self.type4_no_op = ['RET', 'RTI']
        self.type4_index = ['INT']
        
        self.memory_size = 2**18
        self.labels: Dict[str, int] = {}
        self.current_address = 0
        
    def clean_line(self, line: str) -> str:
        """Remove comments and extra whitespace"""
        for comment_char in ['#', ';']:
            if comment_char in line:
                line = line[:line.index(comment_char)]
        return line.strip()
    
    def parse_register(self, reg: str) -> str:
        """Parse register name to 3-bit binary"""
        reg = reg.strip().upper().replace(',', '')
        if reg not in self.registers:
            raise ValueError(f"Invalid register: {reg}")
        return self.registers[reg]
    
    def parse_immediate(self, imm: str, bits: int = 16, allow_labels: bool = False) -> str:
        """Parse immediate value to binary.
        Defaults to hexadecimal (all numbers in test cases are hexadecimal).
        """
        imm = imm.strip().replace(',', '')
        
        if allow_labels and imm in self.labels:
            value = self.labels[imm]
        else:
            if imm.upper().startswith('0X'):
                value = int(imm, 16)
            elif imm.upper().startswith('0B'):
                value = int(imm, 2)
            else:
                # Default to hexadecimal (all numbers in test cases are hexadecimal)
                # Fallback to decimal only if hex parsing fails (invalid hex characters)
                try:
                    value = int(imm, 16)
                except ValueError:
                    value = int(imm, 10)
        
        if value < 0:
            value = (1 << bits) + value
        
        return format(value & ((1 << bits) - 1), f'0{bits}b')
    
    def parse_data_value(self, value_str: str) -> int:
        """Parse a data value (32-bit) supporting binary, hex, and decimal.
        Defaults to hexadecimal (all numbers in test cases are hexadecimal).
        """
        value_str = value_str.strip().replace(',', '')
        
        if value_str.upper().startswith('0X'):
            return int(value_str, 16)
        elif value_str.upper().startswith('0B'):
            return int(value_str, 2)
        else:
            # Default to hexadecimal (all numbers in test cases are hexadecimal)
            # Fallback to decimal only if hex parsing fails (invalid hex characters)
            try:
                return int(value_str, 16)
            except ValueError:
                return int(value_str, 10)
    
    def parse_offset_register(self, operand: str) -> Tuple[str, str]:
        """Parse offset(register) format"""
        match = re.match(r'(.+)\((.+)\)', operand.strip())
        if not match:
            raise ValueError(f"Invalid offset(register) format: {operand}")
        
        offset_str = match.group(1).strip()
        reg_str = match.group(2).strip()
        
        offset = self.parse_immediate(offset_str, 16)
        reg = self.parse_register(reg_str)
        
        return offset, reg
    
    def get_instruction_size(self, mnemonic: str) -> int:
        """Return number of words this instruction occupies"""
        mnemonic = mnemonic.upper()
        
        two_word_instructions = (
            self.type2_imm + self.type3_imm + 
            self.type3_offset + self.type4_imm + self.type4_index
        )
        
        if mnemonic in two_word_instructions:
            return 2
        else:
            return 1
    
    def first_pass(self, lines: List[str]) -> List[Tuple[int, str, int, bool]]:
        """First pass: collect labels and calculate addresses
        Returns: List of (address, line, line_num, is_data_value)
        is_data_value=True means it's a plain number to store, not an instruction
        """
        processed_lines = []
        self.current_address = 0
        expect_data_value = False  # Track if next line should be a data value
        
        for line_num, line in enumerate(lines, 1):
            original_line = line
            line = self.clean_line(line)
            
            if not line:
                continue
            
            if line.upper().startswith('.ORG'):
                parts = line.split()
                if len(parts) != 2:
                    raise ValueError(f"Line {line_num}: Invalid .ORG directive: {original_line}")
                
                addr_str = parts[1]
                # Parse address - default to hexadecimal (all numbers in test cases are hexadecimal)
                if addr_str.upper().startswith('0X'):
                    self.current_address = int(addr_str, 16)
                else:
                    try:
                        # Default to hexadecimal
                        self.current_address = int(addr_str, 16)
                    except ValueError:
                        # Fallback to decimal only if hex parsing fails
                        self.current_address = int(addr_str, 10)
                expect_data_value = True  # Next non-empty line should be a data value
                continue
            
            if ':' in line:
                label_part, instruction_part = line.split(':', 1)
                label = label_part.strip()
                
                if label in self.labels:
                    raise ValueError(f"Line {line_num}: Duplicate label '{label}'")
                
                self.labels[label] = self.current_address
                line = instruction_part.strip()
                
                if not line:
                    continue
            
            parts = line.split()
            if not parts:
                continue
            
            # Handle INT0 and INT1 as special cases (expand to INT 0 and INT 1)
            if parts[0].upper() == 'INT0':
                line = 'INT 0'
                parts = ['INT', '0']
            elif parts[0].upper() == 'INT1':
                line = 'INT 1'
                parts = ['INT', '1']
            
            # Check if this is a plain number (data value) after .ORG
            if expect_data_value:
                # First check if it's a valid instruction mnemonic - if so, treat as instruction, not data
                mnemonic_check = parts[0].upper()
                if mnemonic_check in self.opcodes or mnemonic_check in ['INT0', 'INT1']:
                    # It's an instruction, not a data value
                    expect_data_value = False
                else:
                    # Try to parse as a number (defaults to hexadecimal)
                    try:
                        value_str = parts[0]
                        if value_str.upper().startswith('0X'):
                            value = int(value_str, 16)
                        elif value_str.upper().startswith('0B'):
                            value = int(value_str, 2)
                        else:
                            value = int(value_str, 16)  # Default to hexadecimal (all numbers in test cases are hexadecimal)
                        processed_lines.append((self.current_address, line, line_num, True))
                        self.current_address += 1
                        expect_data_value = False
                        continue
                    except ValueError:
                        # Not a number, treat as instruction
                        expect_data_value = False
            
            mnemonic = parts[0].upper()
            if mnemonic not in self.opcodes:
                raise ValueError(f"Line {line_num}: Unknown instruction '{mnemonic}': {original_line}")
            
            processed_lines.append((self.current_address, line, line_num, False))
            self.current_address += self.get_instruction_size(mnemonic)
        
        return processed_lines
    
    def assemble_instruction(self, line: str, line_num: int) -> List[str]:
        """Assemble a single instruction into machine code (one or two words)"""
        parts = re.split(r'[,\s]+', line.strip())
        parts = [p for p in parts if p]
        
        mnemonic = parts[0].upper()
        opcode = self.opcodes[mnemonic]
        instructions = []
        
        try:
            if mnemonic in self.type1_no_op:
                instructions.append(opcode + '0' * 27)
            
            elif mnemonic in self.type1_one_op:
                if len(parts) < 2:
                    raise ValueError(f"{mnemonic} requires a register operand")
                rd = self.parse_register(parts[1])
                instructions.append(opcode + rd + '0' * 24)
            
            elif mnemonic in self.type1_one_op_special:
                if len(parts) < 2:
                    raise ValueError(f"{mnemonic} requires a register operand")
                rs = self.parse_register(parts[1])
                instructions.append(opcode + '000' + rs + '000' + '0' * 18)
            
            elif mnemonic == 'MOV':
                # MOV Rsrc, Rdst - first operand is source, second is destination
                if len(parts) < 3:
                    raise ValueError("MOV requires 2 register operands")
                rs = self.parse_register(parts[1])  # Source register
                rd = self.parse_register(parts[2])  # Destination register
                instructions.append(opcode + rd + rs + '0' * 21)
            
            elif mnemonic == 'SWAP':
                # SWAP Rd, Rs - swap two registers
                if len(parts) < 3:
                    raise ValueError("SWAP requires 2 register operands")
                rd = self.parse_register(parts[1])
                rs = self.parse_register(parts[2])
                instructions.append(opcode + rd + rs + '0' * 21)
            
            elif mnemonic in self.type2_three_op:
                if len(parts) < 4:
                    raise ValueError(f"{mnemonic} requires 3 register operands")
                rd = self.parse_register(parts[1])
                rs1 = self.parse_register(parts[2])
                rs2 = self.parse_register(parts[3])
                instructions.append(opcode + rd + rs1 + rs2 + '0' * 18)
            
            elif mnemonic in self.type2_imm:
                if len(parts) < 4:
                    raise ValueError(f"{mnemonic} requires Rd, Rs, Imm")
                rd = self.parse_register(parts[1])
                rs = self.parse_register(parts[2])
                # allow labels as immediates for IADD as well (flexible)
                imm = self.parse_immediate(parts[3], 16, allow_labels=True)
                instructions.append(opcode + rd + '000' + rs + '0' * 18)
                instructions.append('0' * 16 + imm)
            
            elif mnemonic == 'PUSH':
                if len(parts) < 2:
                    raise ValueError("PUSH requires a register operand")
                rs = self.parse_register(parts[1])
                instructions.append(opcode + '000' + rs + '000' + '0' * 18)
            
            elif mnemonic == 'POP':
                if len(parts) < 2:
                    raise ValueError("POP requires a register operand")
                rd = self.parse_register(parts[1])
                instructions.append(opcode + rd + '0' * 24)
            
            elif mnemonic in self.type3_imm:
                if len(parts) < 3:
                    raise ValueError(f"{mnemonic} requires Rd, Imm")
                rd = self.parse_register(parts[1])
                # Allow labels as immediates (LDM <Rd>, label)
                imm = self.parse_immediate(parts[2], 16, allow_labels=True)
                instructions.append(opcode + rd + '0' * 24)
                instructions.append('0' * 16 + imm)
            
            elif mnemonic == 'LDD':
                if len(parts) < 3:
                    raise ValueError("LDD requires Rd, offset(Rs)")
                rd = self.parse_register(parts[1])
                offset_part = ''.join(parts[2:])
                offset, rs = self.parse_offset_register(offset_part)
                instructions.append(opcode + rd + '000' + rs + '0' * 18)
                instructions.append('0' * 16 + offset)
            
            elif mnemonic == 'STD':
                if len(parts) < 3:
                    raise ValueError("STD requires Rs1, offset(Rs2)")
                rs1 = self.parse_register(parts[1])
                offset_part = ''.join(parts[2:])
                offset, rs2 = self.parse_offset_register(offset_part)
                instructions.append(opcode + '000' + rs1 + rs2 + '0' * 18)
                instructions.append('0' * 16 + offset)
            
            elif mnemonic in self.type4_imm:
                if len(parts) < 2:
                    raise ValueError(f"{mnemonic} requires an immediate address value")
                # Allow labels for branch/jump/call immediates
                imm = self.parse_immediate(parts[1], 16, allow_labels=True)
                instructions.append(opcode + '0' * 27)
                instructions.append('0' * 16 + imm)
            
            elif mnemonic in self.type4_no_op:
                instructions.append(opcode + '0' * 27)
            
            elif mnemonic in self.type4_index:
                # INT instruction - TWO words
                if len(parts) < 2:
                    raise ValueError("INT requires an index (0 or 1)")
                index_val = parts[1].strip().replace(',', '')
                try:
                    index = int(index_val)
                except ValueError:
                    raise ValueError(f"INT index must be 0 or 1, got: {parts[1]}")
                if index not in [0, 1]:
                    raise ValueError(f"INT index must be 0 or 1, got: {index}")
                
                # First word: opcode + zeros
                instructions.append(opcode + '0' * 27)
                # Second word: zeros + index(2 bits)
                instructions.append('0' * 30 + format(index, '02b'))
            
            else:
                raise ValueError(f"Unhandled instruction type: {mnemonic}")
        
        except Exception as e:
            raise ValueError(f"Error assembling '{line}': {str(e)}")
        
        return instructions
    
    def assemble(self, input_file: str, output_file: str):
        """Main assembly process"""
        try:
            print(f"\n{'='*60}")
            print(f"RISC Processor Assembler")
            print(f"{'='*60}")
            print(f"Reading: {input_file}")
            
            with open(input_file, 'r') as f:
                lines = f.readlines()
            
            print(f"Total lines: {len(lines)}")
            
            print(f"\nFirst pass: Collecting labels...")
            processed_lines = self.first_pass(lines)
            
            print(f"Instructions found: {len(processed_lines)}")
            print(f"Labels found: {len(self.labels)}")
            
            if self.labels:
                print("\nLabel Table:")
                for label, addr in sorted(self.labels.items(), key=lambda x: x[1]):
                    print(f"  {label:20s} = {addr:5d} (0x{addr:04X})")
            
            print(f"\nInitializing memory ({self.memory_size} words)...")
            memory = [self.opcodes['NOP'] + '0' * 27] * self.memory_size
            
            print(f"\nSecond pass: Generating machine code...")
            error_count = 0
            
            for item in processed_lines:
                address, line, line_num, is_data_value = item
                try:
                    if is_data_value:
                        # This is a data value (plain number after .ORG)
                        value = self.parse_data_value(line.split()[0])
                        # Store as 32-bit value (sign-extend to 32 bits if needed)
                        value_32bit = value & 0xFFFFFFFF
                        instruction = format(value_32bit, '032b')
                        if address < self.memory_size:
                            memory[address] = instruction
                        else:
                            print(f"  Warning: Address {address} exceeds memory size")
                    else:
                        # This is an instruction
                        instructions = self.assemble_instruction(line, line_num)
                        for i, instruction in enumerate(instructions):
                            mem_addr = address + i
                            if mem_addr < self.memory_size:
                                memory[mem_addr] = instruction
                            else:
                                print(f"  Warning: Address {mem_addr} exceeds memory size")
                except Exception as e:
                    error_count += 1
                    print(f"  ERROR at line {line_num}: {line}")
                    print(f"    {str(e)}")
            
            if error_count > 0:
                print(f"\nERROR: Assembly failed with {error_count} error(s)")
                sys.exit(1)
            
            print(f"\nWriting output: {output_file}")
            with open(output_file, 'w') as f:
                # Write header lines matching out.mem format
                f.write("// instance=/cpu/id_memory_inst/mem\n")
                f.write("// format=mti addressradix=h dataradix=s version 1.0 wordsperline=1\n")
                
                # Write memory contents
                for i, instruction in enumerate(memory):
                    # Format: right-aligned to 8 chars (spaces + lowercase hex address), colon+space, 32-bit binary
                    addr_hex = format(i, 'x')
                    f.write(f"{addr_hex:>8}: {instruction}\n")
            
            print(f"\n{'='*60}")
            print(f"Assembly Successful!")
            print(f"{'='*60}")
            print(f"Input file:    {input_file}")
            print(f"Output file:   {output_file}")
            print(f"Memory size:   {self.memory_size} words")
            print(f"Instructions:  {len(processed_lines)}")
            print(f"Labels:        {len(self.labels)}")
            print(f"{'='*60}\n")
            
        except FileNotFoundError:
            print(f"ERROR: Input file '{input_file}' not found")
            sys.exit(1)
        except Exception as e:
            print(f"ERROR: Assembly error: {str(e)}")
            import traceback
            traceback.print_exc()
            sys.exit(1)


def main():
    """Main entry point"""
    print("\n" + "="*60)
    print("RISC Processor Assembler v1.0")
    print("="*60)
    
    if len(sys.argv) < 2:
        print("\nUsage: python assembler.py <input.asm> [output.mem]")
        print("\nExample:")
        print("  python assembler.py program.asm program.mem")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file.rsplit('.', 1)[0] + '.mem'
    
    assembler = RISCAssembler()
    assembler.assemble(input_file, output_file)


if __name__ == "__main__":
    main()
