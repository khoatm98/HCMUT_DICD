#!/usr/bin/env python3
"""gen_golden.py -- golden model + test-vector generator for the MIMO sphere-
decoder capstone (open-source, pure-Python replacement for the NTU MATLAB flow).

It generates, for an N x N MIMO system with an M-PSK constellation:
  * a random complex channel H, transmitted symbol vector s, and noise,
  * the QR decomposition H = Q R (modified Gram-Schmidt),
  * the hardware inputs R (upper-triangular) and y_tilde = Q^H y,
  * the GOLDEN detected symbols via exhaustive Maximum-Likelihood search
    min_s || y_tilde - R s ||^2  (this is what a sphere decoder computes faster).

Hardware works in signed fixed-point Q6.10 (same as the rest of the course), so
R and y_tilde are emitted as Q6.10 hex. Pure Python (random, cmath) -- no numpy,
no MATLAB -- so it runs anywhere python3 does.

Usage:
  python3 gen_golden.py [--n 4] [--m 8] [--cases 20] [--snr 20] [--seed 1] \
                        [--out_vectors vectors.hex] [--out_expected expected.txt]
"""
import argparse
import cmath
import math
import random

FRAC = 10
MASK = 0xFFFF


def q610(x):
    """Round a real number to Q6.10 and return the 16-bit two's-complement int."""
    v = int(round(x * (1 << FRAC)))
    v = max(-32768, min(32767, v))      # saturate
    return v & MASK


# ---- tiny complex-matrix helpers (lists of lists of python complex) ----
def cgauss(rng):
    return complex(rng.gauss(0.0, math.sqrt(0.5)), rng.gauss(0.0, math.sqrt(0.5)))


def conj_transpose(A):
    n = len(A)
    return [[A[j][i].conjugate() for j in range(n)] for i in range(n)]


def matvec(A, x):
    return [sum(A[i][k] * x[k] for k in range(len(x))) for i in range(len(A))]


def qr_mgs(H):
    """Modified Gram-Schmidt QR: returns (Q, R) with H = Q R, Q unitary columns."""
    n = len(H)
    # work on columns
    V = [[H[i][j] for i in range(n)] for j in range(n)]   # V[j] = column j
    Q = [[0j] * n for _ in range(n)]                       # Q[j] = column j
    R = [[0j] * n for _ in range(n)]
    for j in range(n):
        v = V[j][:]
        for i in range(j):
            qi = [Q[i][k] for k in range(n)]
            R[i][j] = sum(qi[k].conjugate() * v[k] for k in range(n))
            v = [v[k] - R[i][j] * qi[k] for k in range(n)]
        nrm = math.sqrt(sum(abs(v[k]) ** 2 for k in range(n)))
        R[j][j] = complex(nrm, 0.0)
        for k in range(n):
            Q[j][k] = v[k] / nrm if nrm > 1e-12 else 0j
    # reshape Q (column-major) into row-major matrix
    Qm = [[Q[j][i] for j in range(n)] for i in range(n)]
    return Qm, R


def psk(m, M):
    """M-PSK constellation point m (unit energy), Gray-free natural index."""
    return cmath.exp(1j * 2.0 * math.pi * m / M)


def ml_detect(R, yt, N, M):
    """Exhaustive ML: argmin_s ||yt - R s||^2 over s in {0..M-1}^N."""
    best, best_d = None, None
    idx = [0] * N
    total = M ** N
    for code in range(total):
        c = code
        for k in range(N):
            idx[k] = c % M
            c //= M
        s = [psk(idx[k], M) for k in range(N)]
        Rs = matvec(R, s)
        d = sum(abs(yt[i] - Rs[i]) ** 2 for i in range(N))
        if best_d is None or d < best_d:
            best_d, best = d, idx[:]
    return best


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=4, help="antennas (N x N MIMO)")
    ap.add_argument("--m", type=int, default=8, help="M-PSK (8=8-PSK, 4=QPSK)")
    ap.add_argument("--cases", type=int, default=20)
    ap.add_argument("--snr", type=float, default=20.0, help="SNR in dB")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out_vectors", default="vectors.hex")
    ap.add_argument("--out_expected", default="expected.txt", help="ML-optimal symbols (reference)")
    ap.add_argument("--out_truth", default="truth.txt", help="ground-truth transmitted symbols (for PSNR)")
    a = ap.parse_args()

    rng = random.Random(a.seed)
    N, M = a.n, a.m
    sigma = math.sqrt(0.5) * 10 ** (-a.snr / 20.0)
    recovered = 0

    fv = open(a.out_vectors, "w")
    fe = open(a.out_expected, "w")
    ft = open(a.out_truth, "w")
    fv.write("// case: R upper-tri (row-major, only i<=j), then y_tilde; each complex = re,im Q6.10 hex\n")
    fe.write("// ML-optimal detected symbol indices (0..M-1), N per line (reference)\n")
    ft.write("// ground-truth transmitted symbol indices (0..M-1), N per line\n")

    for cse in range(a.cases):
        H = [[cgauss(rng) for _ in range(N)] for _ in range(N)]
        tx = [rng.randrange(M) for _ in range(N)]
        s = [psk(tx[k], M) for k in range(N)]
        y = matvec(H, s)
        y = [y[i] + complex(rng.gauss(0, sigma), rng.gauss(0, sigma)) for i in range(N)]
        Q, R = qr_mgs(H)
        yt = matvec(conj_transpose(Q), y)
        det = ml_detect(R, yt, N, M)
        if det == tx:
            recovered += 1

        # emit R upper triangle then y_tilde as Q6.10 hex pairs
        fv.write("# case %d\n" % cse)
        for i in range(N):
            for j in range(i, N):
                fv.write("%04x %04x\n" % (q610(R[i][j].real), q610(R[i][j].imag)))
        for i in range(N):
            fv.write("%04x %04x\n" % (q610(yt[i].real), q610(yt[i].imag)))
        fe.write(" ".join(str(d) for d in det) + "\n")
        ft.write(" ".join(str(t) for t in tx) + "\n")

    fv.close()
    fe.close()
    ft.close()
    print("Wrote %d cases (N=%d, %d-PSK) -> %s, %s" % (a.cases, N, M, a.out_vectors, a.out_expected))
    print("High-SNR sanity: ML recovered the transmitted vector in %d/%d cases"
          % (recovered, a.cases))


if __name__ == "__main__":
    main()
