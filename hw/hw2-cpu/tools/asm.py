#!/usr/bin/env python3
"""asm.py -- assembler for the TinyRISC-16 ISA (HW2).

Two-pass assembler. Emits two hex files (one 16-bit word per line):
  <out_imem>   instruction memory image
  <out_dmem>   data memory image (initial contents from the .data section)

Usage:
  python3 asm.py <prog.s> <out_imem.hex> <out_dmem.hex>

Syntax (see hw/hw2-cpu/SPEC.md):
  ; or # start a comment.  Labels: `name:`.  Registers: r0..r7.
  .text / .data switch sections (default .text).
  In .data:  label: .word v0, v1, ...   (ints, 0x.., or Q6.10 floats like 1.5)

Instructions:
  add/sub/and/or/xor/slt/sll/sra  rd, rs, rt      (integer ALU)
  fxadd/fxsub/fxmul               rd, rs, rt      (Q6.10 ALU)
  mac                             rd, rs, rt      (rd = sat(rd + round(rs*rt)))
  addi                            rd, rs, imm
  lw / sw                         rd, imm(rs) | rd, label
  beq / bne                       rd, rs, label
  jmp / jal                       label
  halt
Pseudo: li rd, imm6 | mov rd, rs | nop
"""
import re
import sys

# opcodes (match isa_defs.vh)
OP = dict(ALU=0x0, FALU=0x1, MAC=0x2, ADDI=0x3, LW=0x4, SW=0x5,
          BEQ=0x6, BNE=0x7, JMP=0x8, JAL=0x9, HALT=0xF)
F_ALU  = dict(add=0, sub=1, **{'and': 2}, **{'or': 3}, xor=4, slt=5, sll=6, sra=7)
F_FALU = dict(fxadd=0, fxsub=1, fxmul=2)


class AsmError(Exception):
    pass


def parse_reg(tok):
    m = re.fullmatch(r'[rR]([0-7])', tok.strip())
    if not m:
        raise AsmError("bad register '%s'" % tok)
    return int(m.group(1))


def parse_imm(tok, labels=None):
    tok = tok.strip()
    if labels is not None and tok in labels:
        return labels[tok]
    if '.' in tok:                       # Q6.10 fixed-point literal
        return q610(float(tok))
    return int(tok, 0)                   # decimal / 0x.. / negative


def q610(x):
    v = int(round(x * 1024.0))
    if v > 32767 or v < -32768:
        raise AsmError("Q6.10 literal out of range: %s" % x)
    return v & 0xFFFF


def enc_r(op, rd, rs, rt, funct):
    return ((op & 0xF) << 12) | ((rd & 7) << 9) | ((rs & 7) << 6) | ((rt & 7) << 3) | (funct & 7)


def enc_i(op, rd, rs, imm):
    if imm < -32 or imm > 31:
        raise AsmError("immediate %d out of 6-bit signed range [-32,31]" % imm)
    return ((op & 0xF) << 12) | ((rd & 7) << 9) | ((rs & 7) << 6) | (imm & 0x3F)


def enc_j(op, addr):
    if addr < 0 or addr > 0xFFF:
        raise AsmError("jump address %d out of 12-bit range" % addr)
    return ((op & 0xF) << 12) | (addr & 0xFFF)


def tokenize(line):
    line = line.split(';', 1)[0].split('#', 1)[0].strip()
    return line


def split_ops(rest):
    return [t.strip() for t in rest.split(',')] if rest.strip() else []


MEMREF = re.compile(r'(-?\w+)\s*\(\s*([rR][0-7])\s*\)')   # imm(rs)


def assemble(src_lines):
    # ---- pass 1: collect labels, instruction list, data words ----
    text = []        # list of (lineno, mnemonic, operands)
    data_words = []  # list of 16-bit ints
    labels = {}
    section = 'text'
    for lineno, raw in enumerate(src_lines, 1):
        line = tokenize(raw)
        if not line:
            continue
        # leading label(s)
        while ':' in line:
            lbl, _, line = line.partition(':')
            lbl = lbl.strip()
            if not re.fullmatch(r'[A-Za-z_]\w*', lbl):
                raise AsmError("line %d: bad label '%s'" % (lineno, lbl))
            labels[lbl] = (len(text) if section == 'text' else len(data_words))
            line = line.strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mnem = parts[0].lower()
        rest = parts[1] if len(parts) > 1 else ''
        if mnem == '.text':
            section = 'text'; continue
        if mnem == '.data':
            section = 'data'; continue
        if mnem == '.word':
            for v in split_ops(rest):
                data_words.append(parse_imm(v) & 0xFFFF)
            continue
        if section != 'text':
            raise AsmError("line %d: instruction in .data section" % lineno)
        text.append((lineno, mnem, rest))

    # ---- pass 2: encode ----
    imem = []
    for idx, (lineno, mnem, rest) in enumerate(text):
        ops = split_ops(rest)
        try:
            if mnem in F_ALU:
                rd, rs, rt = map(parse_reg, ops)
                imem.append(enc_r(OP['ALU'], rd, rs, rt, F_ALU[mnem]))
            elif mnem in F_FALU:
                rd, rs, rt = map(parse_reg, ops)
                imem.append(enc_r(OP['FALU'], rd, rs, rt, F_FALU[mnem]))
            elif mnem == 'mac':
                rd, rs, rt = map(parse_reg, ops)
                imem.append(enc_r(OP['MAC'], rd, rs, rt, 0))
            elif mnem == 'addi':
                rd, rs = parse_reg(ops[0]), parse_reg(ops[1])
                imem.append(enc_i(OP['ADDI'], rd, rs, parse_imm(ops[2], labels)))
            elif mnem in ('lw', 'sw'):
                rd = parse_reg(ops[0])
                m = MEMREF.fullmatch(ops[1].strip())
                if m:
                    imm, rs = parse_imm(m.group(1), labels), parse_reg(m.group(2))
                else:                                  # bare label/number -> base r0
                    imm, rs = parse_imm(ops[1], labels), 0
                imem.append(enc_i(OP['LW' if mnem == 'lw' else 'SW'], rd, rs, imm))
            elif mnem in ('beq', 'bne'):
                rd, rs = parse_reg(ops[0]), parse_reg(ops[1])
                target = labels[ops[2]]
                off = target - (idx + 1)               # PC-relative to PC+1
                imem.append(enc_i(OP['BEQ' if mnem == 'beq' else 'BNE'], rd, rs, off))
            elif mnem in ('jmp', 'jal'):
                imem.append(enc_j(OP['JMP' if mnem == 'jmp' else 'JAL'], labels[ops[0]]))
            elif mnem == 'halt':
                imem.append(enc_j(OP['HALT'], 0))
            # ---- pseudo-instructions ----
            elif mnem == 'li':
                rd = parse_reg(ops[0])
                imem.append(enc_i(OP['ADDI'], rd, 0, parse_imm(ops[1], labels)))
            elif mnem == 'mov':
                rd, rs = parse_reg(ops[0]), parse_reg(ops[1])
                imem.append(enc_i(OP['ADDI'], rd, rs, 0))
            elif mnem == 'nop':
                imem.append(enc_r(OP['ALU'], 0, 0, 0, F_ALU['add']))
            else:
                raise AsmError("unknown mnemonic '%s'" % mnem)
        except AsmError as e:
            raise AsmError("line %d (%s): %s" % (lineno, mnem, e))
        except (ValueError, IndexError, KeyError) as e:
            raise AsmError("line %d (%s): bad operands %r (%s)" % (lineno, mnem, ops, e))
    return imem, data_words


def write_hex(path, words):
    with open(path, 'w') as f:
        for w in words:
            f.write("%04x\n" % (w & 0xFFFF))


def main(argv):
    if len(argv) != 4:
        print(__doc__)
        return 2
    src, out_imem, out_dmem = argv[1], argv[2], argv[3]
    with open(src) as f:
        lines = f.readlines()
    try:
        imem, dmem = assemble(lines)
    except AsmError as e:
        sys.stderr.write("ASM ERROR: %s\n" % e)
        return 1
    write_hex(out_imem, imem)
    write_hex(out_dmem, dmem)
    print("assembled %s: %d instructions, %d data words" % (src, len(imem), len(dmem)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
