; ops.s -- exercises (almost) the entire TinyRISC-16 ISA. Each result is stored
; to data memory and checked against the golden ISS. Q6.10 constants are built
; with shifts (no data section needed).
.text
        ; ---- integer ALU (results -> dmem[0..8]) ----
        li   r1, 12
        li   r2, 5
        add  r3, r1, r2
        sw   r3, 0(r0)
        sub  r3, r1, r2
        sw   r3, 1(r0)
        and  r3, r1, r2
        sw   r3, 2(r0)
        or   r3, r1, r2
        sw   r3, 3(r0)
        xor  r3, r1, r2
        sw   r3, 4(r0)
        slt  r3, r2, r1        ; 5 < 12  -> 1
        sw   r3, 5(r0)
        slt  r3, r1, r2        ; 12 < 5  -> 0
        sw   r3, 6(r0)
        sll  r3, r1, r2        ; 12 << 5
        sw   r3, 7(r0)
        sra  r3, r1, r2        ; 12 >>> 5
        sw   r3, 8(r0)

        ; ---- fixed-point Q6.10 (build constants via shifts) -> dmem[9..11] ----
        li   r4, 9
        li   r1, 3
        sll  r1, r1, r4        ; 3<<9  = 1536 = 1.5
        li   r4, 8
        li   r2, 1
        sll  r2, r2, r4        ; 1<<8  = 256  = 0.25
        fxadd r3, r1, r2       ; 1.75
        sw   r3, 9(r0)
        li   r4, 11
        li   r2, 1
        sll  r2, r2, r4        ; 1<<11 = 2048 = 2.0
        fxsub r3, r1, r2       ; -0.5
        sw   r3, 10(r0)
        fxmul r3, r1, r2       ; 1.5 * 2.0 = 3.0
        sw   r3, 11(r0)

        ; ---- lw round-trip -> dmem[12] = 31 ----
        li   r1, 31
        sw   r1, 20(r0)
        lw   r2, 20(r0)
        sw   r2, 12(r0)

        ; ---- bne loop: sum 1..4 = 10 -> dmem[15] ----
        li   r1, 0
        li   r2, 1
        li   r4, 5
sumloop:
        add  r1, r1, r2
        addi r2, r2, 1
        bne  r2, r4, sumloop
        sw   r1, 15(r0)

        ; ---- beq taken -> dmem[13] = 1 ----
        li   r5, 7
        li   r6, 7
        beq  r5, r6, eqlab
        li   r6, 9
        sw   r6, 13(r0)        ; skipped
eqlab:
        li   r6, 1
        sw   r6, 13(r0)

        ; ---- jmp over a store: dmem[14] stays 0 ----
        jmp  skip
        li   r6, 5
        sw   r6, 14(r0)        ; skipped
skip:
        ; ---- jal sets link register r7; "return" via jmp ----
        jal  subr
done:
        halt
subr:
        sw   r7, 16(r0)        ; store link address
        jmp  done
