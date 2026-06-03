#!/usr/bin/env python3
"""iss.py -- golden instruction-set simulator for TinyRISC-16 (HW2).

The single source of truth for expected CPU behavior. Runs an instruction-memory
image (and an initial data-memory image), then writes the FINAL data memory as
the golden file the testbench compares against. Mirrors common/rtl/cpu/cpu_core.v.

Usage:
  python3 iss.py <imem.hex> <dmem.hex> <out_golden.hex>
"""
import sys

WIDTH = 16
FRAC  = 10
MASK  = 0xFFFF
AW    = 8
NMEM  = 1 << AW
SMAX  = 32767
SMIN  = -32768

OP_ALU, OP_FALU, OP_MAC, OP_ADDI, OP_LW, OP_SW, OP_BEQ, OP_BNE, OP_JMP, OP_JAL = range(10)
OP_HALT = 0xF
F_ALU  = {0: 'add', 1: 'sub', 2: 'and', 3: 'or', 4: 'xor', 5: 'slt', 6: 'sll', 7: 'sra'}
F_FALU = {0: 'fxadd', 1: 'fxsub', 2: 'fxmul'}


def u16(x):
    return x & MASK


def s16(x):
    x &= MASK
    return x - 0x10000 if x & 0x8000 else x


def sat(v):
    return SMAX if v > SMAX else (SMIN if v < SMIN else v)


def alu(name, a, b):
    A, B = s16(a), s16(b)
    ua, ub = u16(a), u16(b)
    sh = ub & 0x1F
    if name == 'add':  return u16(A + B)
    if name == 'sub':  return u16(A - B)
    if name == 'and':  return ua & ub
    if name == 'or':   return ua | ub
    if name == 'xor':  return ua ^ ub
    if name == 'slt':  return 1 if A < B else 0
    if name == 'sll':  return u16(ua << sh)
    if name == 'sra':  return u16(A >> sh)
    if name == 'fxadd': return u16(sat(A + B))
    if name == 'fxsub': return u16(sat(A - B))
    if name == 'fxmul':
        prod = A * B
        rnd = (prod + (1 << (FRAC - 1))) >> FRAC
        return u16(sat(rnd))
    raise ValueError(name)


def sext6(imm):
    return imm - 64 if (imm & 0x20) else imm


def run(imem, dmem, max_cycles=100000):
    reg = [0] * 8
    pc = 0
    cyc = 0
    halted = False

    def R(i):
        return 0 if i == 0 else reg[i] & MASK

    def setR(i, v):
        if i != 0:
            reg[i] = v & MASK

    while cyc < max_cycles:
        instr = imem[pc & (NMEM - 1)]
        op = (instr >> 12) & 0xF
        rd = (instr >> 9) & 7
        rs = (instr >> 6) & 7
        rt = (instr >> 3) & 7
        funct = instr & 7
        imm = sext6(instr & 0x3F)
        addr = instr & 0xFFF
        npc = pc + 1

        if op == OP_HALT:
            halted = True
            break
        elif op == OP_ALU:
            setR(rd, alu(F_ALU[funct], R(rs), R(rt)))
        elif op == OP_FALU:
            setR(rd, alu(F_FALU[funct], R(rs), R(rt)))
        elif op == OP_MAC:
            p = alu('fxmul', R(rs), R(rt))
            setR(rd, u16(sat(s16(R(rd)) + s16(p))))
        elif op == OP_ADDI:
            setR(rd, u16(s16(R(rs)) + imm))
        elif op == OP_LW:
            a = (s16(R(rs)) + imm) & (NMEM - 1)
            setR(rd, dmem[a] & MASK)
        elif op == OP_SW:
            a = (s16(R(rs)) + imm) & (NMEM - 1)
            dmem[a] = R(rd) & MASK
        elif op == OP_BEQ:
            if R(rd) == R(rs):
                npc = pc + 1 + imm
        elif op == OP_BNE:
            if R(rd) != R(rs):
                npc = pc + 1 + imm
        elif op == OP_JMP:
            npc = addr
        elif op == OP_JAL:
            setR(7, (pc + 1) & MASK)
            npc = addr
        else:
            raise ValueError("illegal opcode 0x%x at pc=%d" % (op, pc))

        pc = npc & (NMEM - 1)
        cyc += 1

    return reg, dmem, halted, cyc


def read_hex(path, n):
    mem = [0] * n
    idx = 0
    try:
        with open(path) as f:
            for line in f:
                line = line.split('//')[0].strip()
                if not line:
                    continue
                if idx < n:
                    mem[idx] = int(line, 16) & MASK
                idx += 1
    except FileNotFoundError:
        pass
    return mem


def main(argv):
    if len(argv) != 4:
        print(__doc__)
        return 2
    imem = read_hex(argv[1], NMEM)
    dmem = read_hex(argv[2], NMEM)
    reg, dmem, halted, cyc = run(imem, dmem)
    with open(argv[3], 'w') as f:
        for w in dmem:
            f.write("%04x\n" % (w & MASK))
    sys.stderr.write("ISS: %d cycles, halted=%s, regs=%s\n"
                     % (cyc, halted, [reg[i] & MASK for i in range(8)]))
    if not halted:
        sys.stderr.write("ISS WARNING: program did not HALT within %d cycles\n" % cyc)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
