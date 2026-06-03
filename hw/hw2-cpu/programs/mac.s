; mac.s -- dot product of two length-3 Q6.10 vectors using the MAC custom
; instruction. Showcases that MAC = sat(acc + round(a*b)) in ONE instruction.
;
;   dot = a.b = 1.0*1.0 + 2.0*0.5 + 0.5*4.0 = 1.0 + 1.0 + 2.0 = 4.0
;   stored (Q6.10) at data address `result`  -> 4.0 = 0x1000
;
; Register use: r1 = accumulator, r2 = a[i], r3 = b[i]

.data
a0:     .word 1.0
a1:     .word 2.0
a2:     .word 0.5
b0:     .word 1.0
b1:     .word 0.5
b2:     .word 4.0
result: .word 0

.text
        li   r1, 0          ; acc = 0

        lw   r2, a0(r0)
        lw   r3, b0(r0)
        mac  r1, r2, r3      ; acc += a0*b0

        lw   r2, a1(r0)
        lw   r3, b1(r0)
        mac  r1, r2, r3      ; acc += a1*b1

        lw   r2, a2(r0)
        lw   r3, b2(r0)
        mac  r1, r2, r3      ; acc += a2*b2

        sw   r1, result(r0)  ; store dot product
        halt
