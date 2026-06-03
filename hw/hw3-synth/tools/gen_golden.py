#!/usr/bin/env python3
"""Golden model + stimulus/expected generator for the 3x3 convolution engine (HW3).

This Python model is the SINGLE SOURCE OF TRUTH for expected conv_engine
behavior; it must match common/rtl/conv/conv_engine.v exactly
(WIDTH=16, FRAC=10 -> Q6.10, IMG=8, 3x3 kernel, zero padding).

Numeric model (mirror of the HW1 ALU FXMUL):
  * pixels and kernel are signed fixed-point Q6.10 (value = raw / 1024).
  * each output pixel = sum over the nine 3x3 taps of (kernel * neighbour pixel),
    accumulated in FULL integer precision (no intermediate rounding),
  * then rounded HALF-UP back to Q6.10:  (acc + (1<<(FRAC-1))) >> FRAC,
  * then SATURATED to signed 16 bits.
  * out-of-bounds neighbours (zero padding) contribute 0.

Outputs (written to ../golden/, one test case per "block"):
  conv_stim.hex      input stream, one 16-bit hex word per line, in protocol
                     order: 9 kernel words then 64 image words, repeated per
                     test case (TOTAL = N_CASES * 73 words).
  conv_exp.hex       expected output stream, one 16-bit hex word per line, 64
                     result words per test case (TOTAL = N_CASES * 64 words).
  conv_count.vh      generated localparams the TB includes:
                       N_CASES, KCNT, ICNT, NPIX  (sizes are not hard-coded in TB)

Run:  python3 tools/gen_golden.py     (from hw/hw3-synth/)
"""
import os
import random

WIDTH = 16
FRAC  = 10
IMG   = 8
MASK  = (1 << WIDTH) - 1
SMAX  = (1 << (WIDTH - 1)) - 1      # +32767
SMIN  = -(1 << (WIDTH - 1))        # -32768
NPIX  = IMG * IMG
KCNT  = 9
ICNT  = NPIX


def u16(x):
    return x & MASK


def s16(x):
    x &= MASK
    return x - (1 << WIDTH) if x & (1 << (WIDTH - 1)) else x


def sat(v):
    return SMAX if v > SMAX else (SMIN if v < SMIN else v)


def q(real):
    """Real number -> Q6.10 raw 16-bit (saturating). For building test inputs."""
    return u16(sat(int(round(real * (1 << FRAC)))))


def conv2d(kernel, image):
    """Golden 3x3 zero-padded convolution. kernel,image are lists of raw Q6.10.

    kernel: 9 raw words, row-major k[0..2][0..2].
    image:  NPIX raw words, row-major.
    Returns NPIX raw Q6.10 result words, row-major.
    """
    out = []
    for r in range(IMG):
        for c in range(IMG):
            acc = 0                              # full-precision integer accumulator
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    t = (dr + 1) * 3 + (dc + 1)
                    rr, cc = r + dr, c + dc
                    if 0 <= rr < IMG and 0 <= cc < IMG:
                        pv = s16(image[rr * IMG + cc])
                    else:
                        pv = 0                   # zero padding
                    acc += s16(kernel[t]) * pv   # Q12.20 partial product
            rnd = (acc + (1 << (FRAC - 1))) >> FRAC   # round half-up -> Q6.10
            out.append(u16(sat(rnd)))
        # (row loop)
    return out


# ----------------------------- test cases -----------------------------
def make_cases():
    rng = random.Random(20260603)   # deterministic
    cases = []   # each case is (name, kernel[9], image[NPIX]) of raw Q6.10 words

    # Case 0: 3x3 BOX BLUR (averaging) kernel = 1/9 each, on a ramp image.
    blur = [q(1.0 / 9.0)] * 9
    ramp = [q((r * IMG + c) / 16.0) for r in range(IMG) for c in range(IMG)]
    cases.append(("blur_ramp", blur, ramp))

    # Case 1: SOBEL-X edge kernel on a vertical step (left half 0, right half 1.0).
    sobel_x = [q(v) for v in (-1, 0, 1,
                              -2, 0, 2,
                              -1, 0, 1)]
    step = [q(1.0 if c >= IMG // 2 else 0.0) for r in range(IMG) for c in range(IMG)]
    cases.append(("sobel_step", sobel_x, step))

    # Case 2: IDENTITY kernel (center=1) -> output == input (interior); a good
    # equivalence sanity case for gate-level sim.
    ident = [q(0.0)] * 9
    ident[4] = q(1.0)
    rng_img = [u16(rng.randint(0, MASK)) for _ in range(NPIX)]
    cases.append(("identity_rand", ident, rng_img))

    # Cases 3-6: random kernels (small magnitude, to exercise rounding without
    # constant saturation) over random images.
    for k in range(4):
        kern = [q(rng.uniform(-0.5, 0.5)) for _ in range(9)]
        image = [q(rng.uniform(-4.0, 4.0)) for _ in range(NPIX)]
        cases.append(("rand%d" % k, kern, image))

    # Case 7: SATURATION stress -- large kernel * large pixels forces clamping.
    big_k = [q(8.0)] * 9
    big_img = [q(rng.uniform(2.0, 30.0)) for _ in range(NPIX)]
    cases.append(("saturate", big_k, big_img))

    return cases


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    outdir = os.path.join(here, "..", "golden")
    os.makedirs(outdir, exist_ok=True)

    cases = make_cases()

    stim_lines = []
    exp_lines = []
    for name, kernel, image in cases:
        out = conv2d(kernel, image)
        # stimulus: 9 kernel words then 64 image words (protocol order)
        for w in kernel:
            stim_lines.append("%04x" % u16(w))
        for w in image:
            stim_lines.append("%04x" % u16(w))
        # expected: 64 result words, raster order
        for w in out:
            exp_lines.append("%04x" % u16(w))

    with open(os.path.join(outdir, "conv_stim.hex"), "w") as f:
        f.write("\n".join(stim_lines) + "\n")
    with open(os.path.join(outdir, "conv_exp.hex"), "w") as f:
        f.write("\n".join(exp_lines) + "\n")
    with open(os.path.join(outdir, "conv_count.vh"), "w") as f:
        f.write("// AUTO-GENERATED by tools/gen_golden.py -- do not edit.\n")
        f.write("localparam integer N_CASES = %d;\n" % len(cases))
        f.write("localparam integer KCNT    = %d;\n" % KCNT)
        f.write("localparam integer ICNT    = %d;\n" % ICNT)
        f.write("localparam integer NPIX    = %d;\n" % NPIX)

    print("Wrote %d test case(s): %d stim words, %d expected words to %s"
          % (len(cases), len(stim_lines), len(exp_lines), outdir))
    for i, (name, _, _) in enumerate(cases):
        print("  case %d: %s" % (i, name))


if __name__ == "__main__":
    main()
