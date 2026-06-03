#!/usr/bin/env python3
"""score.py -- QUALITY scorer for the MIMO detector capstone.

The capstone is NOT graded on exact-match to the ML golden. It is graded on
detection QUALITY -- here the symbol-domain PSNR (and symbol error rate) of your
detector's output vs the ground-truth transmitted symbols -- TOGETHER WITH area,
timing, and power (from your synthesis/STA/APR reports). So an approximate or
early-terminated sphere decoder that trades a little PSNR for a big area/time/
power win is a valid, encouraged design choice.

PSNR(dB) = 10*log10(peak^2 / MSE), where MSE is the mean squared error between
the detected and true constellation points (M-PSK, unit energy -> peak = 1).

Usage:
  python3 score.py --detected detected.txt --truth golden/truth.txt --m 8
Each file: N symbol indices (0..M-1) per line, one line per test case.
"""
import argparse
import cmath
import math


def psk(m, M):
    return cmath.exp(1j * 2.0 * math.pi * m / M)


def read_idx(path):
    rows = []
    for line in open(path):
        line = line.split('//')[0].split('#')[0].strip()
        if line:
            rows.append([int(t) for t in line.split()])
    return rows


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--detected', required=True, help="your detector's output symbol indices")
    ap.add_argument('--truth', required=True, help="ground-truth (golden/truth.txt)")
    ap.add_argument('--m', type=int, default=8, help="M-PSK")
    ap.add_argument('--peak', type=float, default=1.0, help="peak symbol magnitude (PSK = 1)")
    a = ap.parse_args()

    D, T = read_idx(a.detected), read_idx(a.truth)
    if len(D) != len(T):
        raise SystemExit("detected (%d cases) != truth (%d cases)" % (len(D), len(T)))

    nsym, werr, sse = 0, 0, 0.0
    for d, t in zip(D, T):
        if len(d) != len(t):
            raise SystemExit("row length mismatch")
        for di, ti in zip(d, t):
            nsym += 1
            if di != ti:
                werr += 1
            sse += abs(psk(di, a.m) - psk(ti, a.m)) ** 2

    mse = sse / nsym if nsym else 0.0
    psnr = 99.0 if mse <= 1e-12 else 10.0 * math.log10((a.peak ** 2) / mse)
    ser = werr / nsym if nsym else 0.0
    print("symbols=%d  SER=%.4f  MSE=%.6f  PSNR=%.2f dB" % (nsym, ser, mse, psnr))


if __name__ == '__main__':
    main()
