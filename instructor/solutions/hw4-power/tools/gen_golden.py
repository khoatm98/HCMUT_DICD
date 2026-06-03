#!/usr/bin/env python3
"""Golden model + stimulus generator for the IoT Data Filter (HW4 -- power).

This Python model is the SINGLE SOURCE OF TRUTH for expected iotdf behavior; it
must match common/rtl/iotdf/iotdf.v exactly. It emits a packed stimulus/expected
stream that the self-checking testbench reads with $readmemh, plus a count
include -- mirroring the HW1 approach.

Outputs (written to ../golden/):
  iotdf_vectors.hex   one 24-bit packed word per CYCLE, fields (MSB first):
                        [23]    i_valid
                        [22:21] i_fn
                        [20:13] i_data
                        [12]    o_valid_exp   (this cycle's output = prev byte)
                        [11:4]  o_data_exp
                        [3:0]   0
  iotdf_count.vh      `localparam integer N_VECTORS = <n>;`  (included by the TB)

Also writes the POWER WORKLOAD stimulus (a long mixed-function byte stream that
produces representative switching activity) for the gate-level power runs:
  ../workload/workload.hex   one 16-bit word per CYCLE: {i_valid, 1'b0, i_fn[1:0],
                             i_data[7:0], 4'b0} -- read by tb_workload.

Run:  python3 tools/gen_golden.py     (from hw/hw4-power/)
"""
import os
import random

# ---- function codes (must match iotdf_defs.vh) ----
FN_BIN2GRAY, FN_GRAY2BIN, FN_CRC8, FN_LFSR = 0, 1, 2, 3

CRC_POLY  = 0x07
LFSR_SEED = 0xFF
MASK8     = 0xFF


# ----------------------------------------------------------------------------
# Pure byte transforms (independent re-derivation of the spec, used by the model
# and by the hand-check). These are deliberately written straightforwardly.
# ----------------------------------------------------------------------------
def bin2gray(x):
    return (x ^ (x >> 1)) & MASK8


def gray2bin(x):
    o = x & 0x80
    for k in range(6, -1, -1):
        bit = ((o >> (k + 1)) & 1) ^ ((x >> k) & 1)
        o |= bit << k
    return o & MASK8


def crc8_byte(crc, data):
    c = (crc ^ data) & MASK8
    for _ in range(8):
        c = ((c << 1) ^ CRC_POLY) & MASK8 if (c & 0x80) else (c << 1) & MASK8
    return c


def lfsr_step(s):
    fb = ((s >> 7) ^ (s >> 5) ^ (s >> 4) ^ (s >> 3)) & 1   # taps 8,6,5,4
    return ((s << 1) | fb) & MASK8


def lfsr_adv8(s):
    for _ in range(8):
        s = lfsr_step(s)
    return s


# ----------------------------------------------------------------------------
# Cycle-accurate reference: drives the same (i_valid, i_fn, i_data) stimulus the
# DUT sees and produces (o_valid, o_data) with the SAME 1-cycle latency, with the
# SAME reset semantics (CRC=0, LFSR=seed at start; state holds when not selected).
# ----------------------------------------------------------------------------
class IotdfModel:
    def __init__(self):
        self.crc  = 0x00
        self.lfsr = LFSR_SEED
        self.o_data = 0x00            # current value of the o_data register

    def apply(self, i_valid, i_fn, i_data):
        """Clock ONE input cycle. Returns (o_valid, o_data) that the registered
        outputs will SHOW after this input is clocked in -- i.e. the value the
        testbench samples one posedge after driving (i_valid,i_fn,i_data). This
        is the fixed 1-cycle latency: input[i] -> output sampled at the same line.
        Mirrors the RTL exactly (o_data holds when i_valid=0; CRC/LFSR state
        updates only when their function is selected)."""
        if i_valid:
            if i_fn == FN_BIN2GRAY:
                result = bin2gray(i_data)
            elif i_fn == FN_GRAY2BIN:
                result = gray2bin(i_data)
            elif i_fn == FN_CRC8:
                result = crc8_byte(self.crc, i_data)
                self.crc = result                       # update only when selected
            elif i_fn == FN_LFSR:
                result = i_data ^ self.lfsr
                self.lfsr = lfsr_adv8(self.lfsr)        # advance only when selected
            else:
                result = 0x00
            self.o_data = result & MASK8
            return 1, self.o_data
        # idle: o_valid=0 and o_data holds (RTL: o_data <= i_valid ? result : o_data)
        return 0, self.o_data


# ----------------------------------------------------------------------------
# Stimulus construction. Each stream holds i_fn stable (per the spec) and feeds a
# block of bytes; we interleave idle (i_valid=0) cycles to exercise the holding
# behavior. The model is the source of truth for the expected output each cycle.
# ----------------------------------------------------------------------------
def build_streams(rng):
    streams = []   # list of (fn, [bytes])

    # Directed: known CRC vector "123456789" -> running CRC ends at 0xF4.
    streams.append((FN_CRC8, list(b"123456789")))
    # Directed: Gray round-trip prep -- bin2gray of a corner set.
    corner = [0x00, 0x01, 0x0B, 0x55, 0xAA, 0xFF, 0x80, 0x7F, 0xF0, 0x0F]
    streams.append((FN_BIN2GRAY, corner))
    # Directed: gray2bin of the Gray codes -> should recover `corner`.
    streams.append((FN_GRAY2BIN, [bin2gray(x) for x in corner]))
    # Directed: LFSR scramble of zeros -> emits the keystream bytes.
    streams.append((FN_LFSR, [0x00] * 12))
    # Directed: LFSR scramble then... (descrambler is a separate stream re-seeded
    # at reset; here we just exercise more bytes).
    streams.append((FN_LFSR, corner))
    # Directed: CRC of all-zeros and all-ones.
    streams.append((FN_CRC8, [0x00] * 6))
    streams.append((FN_CRC8, [0xFF] * 6))

    # Randomized coverage: many short streams per function.
    for _ in range(40):
        fn = rng.randint(0, 3)
        n  = rng.randint(1, 10)
        streams.append((fn, [rng.randint(0, 255) for _ in range(n)]))

    return streams


def emit_cycles(streams, rng):
    """Flatten streams into a per-cycle stimulus list of (i_valid, i_fn, i_data),
    inserting occasional idle bubbles between/within streams."""
    cyc = []
    for fn, data in streams:
        for b in data:
            cyc.append((1, fn, b))
            if rng.random() < 0.15:                     # sprinkle idle bubbles
                cyc.append((0, fn, 0x00))
        cyc.append((0, fn, 0x00))                        # gap between streams
    # one trailing idle so the last byte's output is captured
    cyc.append((0, 0, 0x00))
    return cyc


def build_power_workload():
    """A long, deterministic mixed-function stream for activity-driven power.
    Cycles through all four functions over many bytes so every unit toggles
    (baseline) -- clock gating should quiet the three idle ones each phase."""
    rng = random.Random(0xC0FFEE)
    cyc = []
    # 4 phases x 64 bytes, one function each, back-to-back (dense activity).
    for fn in (FN_BIN2GRAY, FN_GRAY2BIN, FN_CRC8, FN_LFSR):
        for _ in range(64):
            cyc.append((1, fn, rng.randint(0, 255)))
    # then an interleaved burst that switches function frequently
    for _ in range(128):
        cyc.append((1, rng.randint(0, 3), rng.randint(0, 255)))
    cyc.append((0, 0, 0x00))
    return cyc


def main():
    here   = os.path.dirname(os.path.abspath(__file__))
    golden = os.path.join(here, "..", "golden")
    wkld   = os.path.join(here, "..", "workload")
    os.makedirs(golden, exist_ok=True)
    os.makedirs(wkld, exist_ok=True)

    rng = random.Random(20260603)                       # deterministic
    streams = build_streams(rng)
    cycles  = emit_cycles(streams, rng)

    model = IotdfModel()
    lines = []
    for (iv, fn, d) in cycles:
        ov, od = model.apply(iv, fn, d)             # output sampled 1 cycle later
        word = ((iv & 1) << 23) | ((fn & 3) << 21) | ((d & MASK8) << 13) \
               | ((ov & 1) << 12) | ((od & MASK8) << 4)
        lines.append("%06x" % word)

    with open(os.path.join(golden, "iotdf_vectors.hex"), "w") as f:
        f.write("\n".join(lines) + "\n")
    with open(os.path.join(golden, "iotdf_count.vh"), "w") as f:
        f.write("// AUTO-GENERATED by tools/gen_golden.py -- do not edit.\n")
        f.write("localparam integer N_VECTORS = %d;\n" % len(lines))

    # ---- power workload (stimulus only; no expected values needed) ----
    wl = build_power_workload()
    with open(os.path.join(wkld, "workload.hex"), "w") as f:
        for (iv, fn, d) in wl:
            word = ((iv & 1) << 15) | ((fn & 3) << 12) | ((d & MASK8) << 4)
            f.write("%04x\n" % word)
    with open(os.path.join(wkld, "workload_count.vh"), "w") as f:
        f.write("// AUTO-GENERATED by tools/gen_golden.py -- do not edit.\n")
        f.write("localparam integer N_WORKLOAD = %d;\n" % len(wl))

    print("Wrote %d golden cycles to %s" % (len(lines), golden))
    print("Wrote %d workload cycles to %s" % (len(wl), wkld))


if __name__ == "__main__":
    main()
