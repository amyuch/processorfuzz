#.section .text
#.globl _start
#_start:
#    li t0, 0xFFFFFFFF
#    csrw cycle, t0     // 'cycle' is a read-only CSR — should raise illegal instruction
#loop:
#    j loop
#  # Enable interrupts (M-mode)
#  li t0, 0x8
#  csrw mstatus, t0
#
#  # Set trap vector to our handler
#  la t1, trap_handler
#  csrw mtvec, t1
#
#  # Attempt misaligned load (should cause trap)
#  li t2, 0x80000001
#  lw t3, 0(t2)
#
#  # If we get here, trap did NOT occur
#  li t4, 0xDEAD
#  li t5, 0x80001000
#  sw t4, 0(t5)
#  j .
#
## Trap handler — writes 1 to 0x80001000
#trap_handler:
#  li t6, 1
#  li t5, 0x80001000
#  sw t6, 0(t5)
#
#  # Infinite loop to stop execution
#  j .
# See LICENSE for license details.

#*****************************************************************************
# add.S
#-----------------------------------------------------------------------------
#
# Test add instruction.
#

#include "riscv_test.h"
#include "fuzz_test.h"

# entry.S

#if __riscv_xlen == 64
# define STORE    sd
# define LOAD     ld
# define REGBYTES 8
#else
# define STORE    sw
# define LOAD     lw
# define REGBYTES 4
#endif

#define TESTEND gp
#define STACK_TOP (_end + 4096)

  .section ".text.init","ax",@progbits
  .global _start
  .align 2
_start:
  j handle_reset
  
  /* NMI vector */
  .align 2
nmi_vector:
  j wtf

  .align 2
trap_vector:
  j wtf

  .global _fuzz_prefix
  init_mie;
_fuzz_prefix:
_p0:    xor x11, x11, x11                         ;
        addi x12, zero, 1                         ;
        slli x12, x12, 11                         ;
        add x11, x11, x12                         ;
        addi x13, zero, 1                         ;
        slli x13, x13, 14                         ;
        add x11, x11, x13                         ;
        addi x10, zero, 3                         ;
        slli x10, x10, 18                         ;
        add x11, x11, x10                         ;
        csrrw x12, sscratch, x11                  ;
_p1:    csrrwi x12, pmpaddr4, 18                  ;
_p2:    la x10, d_1_5                             ;
        srai x10, x10, 1                          ;
        csrrc x12, pmpaddr5, x10                  ;
_p3:;
    /* Fuzz Prefix */
    /**/
_end_prefix:
    ret

handle_reset:
INIT_XREGS

  la t0, trap_mtvec 
  csrw mtvec, t0
  la sp, STACK_TOP - SIZEOF_TRAPFRAME_T
  csrr t0, mhartid
  slli t0, t0, 12
  add sp, sp, t0
  csrw mscratch, sp
  li a0, MSTATUS_FS
  csrs mstatus, a0
  call init_freg
  la a0, userstart
  j vm_boot

init_freg:
INIT_FREGS

        ret
        .align;

  .global trap_stvec
trap_stvec:
        clear_sie;
_fuzz_suffix:
_s0:    la x16, d_3_17                            ;
        addi x16, x16, -16                        ;
        amomaxu.w x26, x16, (x16)                 ;
_s1:    la x14, d_2_23                            ;
        addi x14, x14, -24                        ;
        amoadd.d x3, x1, (x14)                    ;
_s2:    la x11, d_5_7                             ;
        lbu x22, 1(x11)                           ;
_s3:    la x10, d_3_20                            ;
        addi x10, x10, -0                         ;
        amomin.w x26, x5, (x10)                   ;
_s4:    csrrwi x26, sepc, 20                      ;
_s5:;
        /* Fuzz trap */
        /**/
_end_suffix:
        ecall

  .global trap_mtvec
trap_mtvec:
        clear_mie;
  DUMP_REGS

   write_tohost:
        li TESTEND, 1
        sw TESTEND, tohost, t5;
  _test_end:
#ifdef BP_EN
  BP_END
#endif
        j _test_end;


  .global pop_tf
pop_tf:
  LOAD  t0,33*REGBYTES(a0)
  csrw  sepc, t0
  LOAD  x1,1*REGBYTES(a0)
  LOAD  x2,2*REGBYTES(a0)
  LOAD  x3,3*REGBYTES(a0)
  LOAD  x4,4*REGBYTES(a0)
  LOAD  x5,5*REGBYTES(a0)
  LOAD  x6,6*REGBYTES(a0)
  LOAD  x7,7*REGBYTES(a0)
  LOAD  x8,8*REGBYTES(a0)
  LOAD  x9,9*REGBYTES(a0)
  LOAD  x11,11*REGBYTES(a0)
  LOAD  x12,12*REGBYTES(a0)
  LOAD  x13,13*REGBYTES(a0)
  LOAD  x14,14*REGBYTES(a0)
  LOAD  x15,15*REGBYTES(a0)
  LOAD  x16,16*REGBYTES(a0)
  LOAD  x17,17*REGBYTES(a0)
  LOAD  x18,18*REGBYTES(a0)
  LOAD  x19,19*REGBYTES(a0)
  LOAD  x20,20*REGBYTES(a0)
  LOAD  x21,21*REGBYTES(a0)
  LOAD  x22,22*REGBYTES(a0)
  LOAD  x23,23*REGBYTES(a0)
  LOAD  x24,24*REGBYTES(a0)
  LOAD  x25,25*REGBYTES(a0)
  LOAD  x26,26*REGBYTES(a0)
  LOAD  x27,27*REGBYTES(a0)
  LOAD  x28,28*REGBYTES(a0)
  LOAD  x29,29*REGBYTES(a0)
  LOAD  x30,30*REGBYTES(a0)
  LOAD  x31,31*REGBYTES(a0)
  LOAD  x10,10*REGBYTES(a0)
  sret

  .global trap_entry
  .align 2
trap_entry:
  csrrw sp, sscratch, sp

  STORE x1,1*REGBYTES(sp)
  STORE x3,3*REGBYTES(sp)
  STORE x4,4*REGBYTES(sp)
  STORE x5,5*REGBYTES(sp)
  STORE x6,6*REGBYTES(sp)
  STORE x7,7*REGBYTES(sp)
  STORE x8,8*REGBYTES(sp)
  STORE x9,9*REGBYTES(sp)
  STORE x10,10*REGBYTES(sp)
  STORE x11,11*REGBYTES(sp)
  STORE x12,12*REGBYTES(sp)
  STORE x13,13*REGBYTES(sp)
  STORE x14,14*REGBYTES(sp)
  STORE x15,15*REGBYTES(sp)
  STORE x16,16*REGBYTES(sp)
  STORE x17,17*REGBYTES(sp)
  STORE x18,18*REGBYTES(sp)
  STORE x19,19*REGBYTES(sp)
  STORE x20,20*REGBYTES(sp)
  STORE x21,21*REGBYTES(sp)
  STORE x22,22*REGBYTES(sp)
  STORE x23,23*REGBYTES(sp)
  STORE x24,24*REGBYTES(sp)
  STORE x25,25*REGBYTES(sp)
  STORE x26,26*REGBYTES(sp)
  STORE x27,27*REGBYTES(sp)
  STORE x28,28*REGBYTES(sp)
  STORE x29,29*REGBYTES(sp)
  STORE x30,30*REGBYTES(sp)
  STORE x31,31*REGBYTES(sp)
  csrrw t0,sscratch,sp
  STORE t0,2*REGBYTES(sp)
  csrr  t0,sstatus
  STORE t0,32*REGBYTES(sp)
  csrr  t0,sepc
  STORE t0,33*REGBYTES(sp)
  csrr  t0,sbadaddr
  STORE t0,34*REGBYTES(sp)
  csrr  t0,scause
  STORE t0,35*REGBYTES(sp)

  move  a0, sp
  j handle_trap

RVTEST_RV64U
# RVTEST_CODE_BEGIN
        .text;
        .global extra_boot;
extra_boot:
        EXTRA_INIT
        ret;
        .global userstart;
userstart:
_fuzz_main:
_l0:    fmadd.s f6, f27, f6, f2, rdn              ;
_l1:    la x14, d_2_1                             ;
        addi x14, x14, -0                         ;
        amomin.w x13, x12, (x14)                  ;
_l2:    la x11, d_4_9                             ;
        flw f27, -12(x11)                         ;
_l3:    fmsub.s f10, f2, f17, f31, rmm            ;
_l4:    la x14, d_5_6                             ;
        addi x14, x14, -24                        ;
        lr.d x12, (x14)                           ;
_l5:    fsub.s f7, f11, f2, rdn                   ;
_l6:    fmax.s f10, f20, f0                       ;
_l7:    fle.s x12, f31, f16                       ;
_l8:    la x5, d_5_25                             ;
        lh x7, 14(x5)                             ;
_l9:    ori x22, x5, -3                           ;
_l10:   fnmsub.s f30, f30, f22, f29, rtz          ;
_l11:   la x7, _l29                               ;
        lh x24, -30(x7)                           ;
_l12:   div x15, x10, x18                         ;
_l13:   sraw x15, x18, x5                         ;
_l14:   fsgnjx.s f7, f12, f12                     ;
_l15:   fle.s x4, f7, f5                          ;
_l16:   fclass.s x9, f5                           ;
_l17:   fmadd.s f20, f28, f31, f9, rne            ;
_l18:   ecall                                     ;
_l19:   la x14, d_0_8                             ;
        addi x14, x14, -28                        ;
        amoand.w x2, x14, (x14)                   ;
_l20:   addiw x26, x11, -1368                     ;
_l21:   fsgnjn.s f17, f27, f28                    ;
_l22:   fmax.s f7, f26, f20                       ;
_l23:   fmv.w.x f17, x6                           ;
_l24:   fsgnjn.s f15, f1, f31                     ;
_l25:   la x13, d_3_23                            ;
        addi x13, x13, -16                        ;
        lr.w x7, (x13)                            ;
_l26:   fmax.s f14, f16, f12                      ;
_l27:   la x8, d_1_20                             ;
        addi x8, x8, 24                           ;
        amomax.w x28, x15, (x8)                   ;
_l28:   la x7, d_2_23                             ;
        addi x7, x7, 28                           ;
        lui x31, 0xffe00                          ;
        xor x7, x7, x31                           ;
        amoor.w x9, x31, (x7)                     ;
_l29:   la x27, d_0_20                            ;
        addi x27, x27, -24                        ;
        amoand.w x2, x18, (x27)                   ;
_l30:   xor x20, x20, x20                         ;
        addi x19, zero, 3                         ;
        slli x19, x19, 0                          ;
        add x20, x20, x19                         ;
        addi x11, zero, 1                         ;
        slli x11, x11, 27                         ;
        add x20, x20, x11                         ;
        csrrs x29, pmpcfg0, x20                   ;
_l31:   sltiu x20, x6, 365                        ;
_l32:   fmadd.s f29, f31, f10, f16, rup           ;
_l33:   la x14, d_2_0                             ;
        addi x14, x14, 8                          ;
        amominu.d x6, x29, (x14)                  ;
_l34:   la x5, d_1_8                              ;
        lwu x23, -12(x5)                          ;
_l35:   la x15, d_2_11                            ;
        sb x27, -23(x15)                          ;
_l36:   fle.s x26, f30, f28                       ;
_l37:   la x19, d_4_14                            ;
        ld x13, 16(x19)                           ;
_l38:   fsub.s f1, f3, f29, rup                   ;
_l39:   la x21, d_2_26                            ;
        ld x17, -8(x21)                           ;
_l40:   la x4, d_1_8                              ;
        lui x2, 0xffe00                           ;
        xor x4, x4, x2                            ;
        lbu x9, 6(x4)                             ;
_l41:   srlw x18, x7, x12                         ;
_l42:   ecall                                     ;
_l43:   fmv.x.w x2, f10                           ;
_l44:   la x16, d_5_23                            ;
        sw x10, -0(x16)                           ;
_l45:   andi x21, x0, -20                         ;
_l46:   fcvt.s.wu f15, x19, rup                   ;
_l47:   la x14, d_1_1                             ;
        sb x22, 6(x14)                            ;
_l48:   div x14, x21, x23                         ;
_l49:   la x6, _l53                               ;
        csrrw zero, uepc, x6                      ;
        uret                                      ;
_l50:   sraw x17, x15, x8                         ;
_l51:   fence.i                                   ;
_l52:   la x20, _l21                              ;
        lui x19, 0xffe00                          ;
        xor x20, x20, x19                         ;
        ld x8, -24(x20)                           ;
_l53:   mulhsu x27, x4, x29                       ;
_l54:   remu x12, x1, x4                          ;
_l55:   fnmadd.s f2, f30, f12, f21, rdn           ;
_l56:   la x2, d_0_11                             ;
        addi x2, x2, 16                           ;
        lui x4, 0xffe00                           ;
        xor x2, x2, x4                            ;
        amomin.d x16, x4, (x2)                    ;
_l57:   fmin.s f27, f22, f5                       ;
_l58:   addi x16, x15, -1428                      ;
_l59:   lui x16, 639262                           ;
_l60:   la x20, d_3_17                            ;
        addi x20, x20, -8                         ;
        amoadd.d x26, x18, (x20)                  ;
_l61:   fmul.s f27, f21, f15, rup                 ;
_l62:   la x25, d_5_22                            ;
        addi x25, x25, 16                         ;
        amoxor.d x23, x5, (x25)                   ;
_l63:   fmadd.s f19, f3, f7, f13, rdn             ;
_l64:   subw x13, x23, x22                        ;
_l65:   remuw x8, x20, x13                        ;
_l66:   srliw x24, x21, 29                        ;
_l67:   la x26, d_3_3                             ;
        addi x26, x26, 0                          ;
        lr.d x26, (x26)                           ;
_l68:   fcvt.s.lu f30, x6, rup                    ;
_l69:   la x9, _l77                               ;
        csrrw zero, sepc, x9                      ;
        sret                                      ;
_l70:   beq x19, x19, _l77                        ;
_l71:   la x1, d_0_14                             ;
        addi x1, x1, 12                           ;
        amoand.w x30, x18, (x1)                   ;
_l72:   la x23, d_3_1                             ;
        addi x23, x23, 28                         ;
        amomaxu.w x7, x18, (x23)                  ;
_l73:   la x10, d_3_11                            ;
        sh x30, 6(x10)                            ;
_l74:   ori x5, x16, 28                           ;
_l75:   ori x17, x18, -325                        ;
_l76:   la x13, d_1_16                            ;
        addi x13, x13, 16                         ;
        sc.d x13, x13, (x13)                      ;
_l77:   la x18, d_0_5                             ;
        addi x18, x18, -8                         ;
        amoxor.w x25, x18, (x18)                  ;
_l78:   fnmsub.s f28, f9, f31, f20, rmm           ;
_l79:   fmv.x.w x23, f11                          ;
_l80:   xor x17, x17, x17                         ;
        csrrw x15, sscratch, x17                  ;
_l81:   la x11, d_4_10                            ;
        addi x11, x11, -0                         ;
        amoxor.d x18, x28, (x11)                  ;
_l82:   csrrci x10, medeleg, 18                   ;
_l83:   la x14, d_4_25                            ;
        lw x10, 16(x14)                           ;
_l84:   la x29, d_5_3                             ;
        addi x29, x29, 0                          ;
        lui x25, 0xffe00                          ;
        xor x29, x29, x25                         ;
        sc.d x22, x29, (x29)                      ;
_l85:   bgeu x10, x4, _l99                        ;
_l86:   la x12, d_0_17                            ;
        addi x12, x12, 20                         ;
        amomax.w x21, x22, (x12)                  ;
_l87:   fmv.w.x f3, x19                           ;
_l88:   srliw x28, x8, 31                         ;
_l89:   srli x27, x18, 63                         ;
_l90:   auipc x16, 700457                         ;
_l91:   la x29, d_3_12                            ;
        addi x29, x29, -0                         ;
        amoand.d x10, x2, (x29)                   ;
_l92:   srli x19, x15, 49                         ;
_l93:   srlw x5, x18, x3                          ;
_l94:   ori x9, x11, -1697                        ;
_l95:   la x5, d_2_16                             ;
        addi x5, x5, 8                            ;
        amomin.d x21, x16, (x5)                   ;
_l96:   li x1, 1                                  ;
        la x21, pt3                               ;
        addi x21, x21, 48                         ;
        sfence.vma x1, x21                        ;
_l97:   la x27, d_0_7                             ;
        addi x27, x27, -16                        ;
        amoor.d x13, x14, (x27)                   ;
_l98:   div x20, x1, x10                          ;
_l99:   sraiw x13, x26, 17                        ;
_l100:  xor x22, x22, x22                         ;
        csrrs x28, mepc, x22                      ;
_l101:  sltiu x11, x9, -339                       ;
_l102:  beq x6, x22, _l104                        ;
_l103:  srliw x9, x12, 31                         ;
_l104:;
        /* Fuzz main */
        /**/
// RVTEST_CODE_END
        ecall
        unimp
_end_main:
        unimp
        unimp
        unimp
        unimp
        unimp
        unimp
        unimp
        unimp

RVTEST_CODE_END

  .data

RVTEST_DATA_BEGIN

        .align 8
xreg_output_data:
reg_x0_output:  .dword 0x0000000000000000
reg_x1_output:  .dword 0x0000000000000000
reg_x2_output:  .dword 0x0000000000000000
reg_x3_output:  .dword 0x0000000000000000
reg_x4_output:  .dword 0x0000000000000000
reg_x5_output:  .dword 0x0000000000000000
reg_x6_output:  .dword 0x0000000000000000
reg_x7_output:  .dword 0x0000000000000000
reg_x8_output:  .dword 0x0000000000000000
reg_x9_output:  .dword 0x0000000000000000
reg_x10_output: .dword 0x0000000000000000
reg_x11_output: .dword 0x0000000000000000
reg_x12_output: .dword 0x0000000000000000
reg_x13_output: .dword 0x0000000000000000
reg_x14_output: .dword 0x0000000000000000
reg_x15_output: .dword 0x0000000000000000
reg_x16_output: .dword 0x0000000000000000
reg_x17_output: .dword 0x0000000000000000
reg_x18_output: .dword 0x0000000000000000
reg_x19_output: .dword 0x0000000000000000
reg_x20_output: .dword 0x0000000000000000
reg_x21_output: .dword 0x0000000000000000
reg_x22_output: .dword 0x0000000000000000
reg_x23_output: .dword 0x0000000000000000
reg_x24_output: .dword 0x0000000000000000
reg_x25_output: .dword 0x0000000000000000
reg_x26_output: .dword 0x0000000000000000
reg_x27_output: .dword 0x0000000000000000
reg_x28_output: .dword 0x0000000000000000
reg_x29_output: .dword 0x0000000000000000
reg_x30_output: .dword 0x0000000000000000
reg_x31_output: .dword 0x0000000000000000

        .align 8
freg_output_data:
reg_f0_output:  .dword 0x0000000000000000
reg_f1_output:  .dword 0x0000000000000000
reg_f2_output:  .dword 0x0000000000000000
reg_f3_output:  .dword 0x0000000000000000
reg_f4_output:  .dword 0x0000000000000000
reg_f5_output:  .dword 0x0000000000000000
reg_f6_output:  .dword 0x0000000000000000
reg_f7_output:  .dword 0x0000000000000000
reg_f8_output:  .dword 0x0000000000000000
reg_f9_output:  .dword 0x0000000000000000
reg_f10_output: .dword 0x0000000000000000
reg_f11_output: .dword 0x0000000000000000
reg_f12_output: .dword 0x0000000000000000
reg_f13_output: .dword 0x0000000000000000
reg_f14_output: .dword 0x0000000000000000
reg_f15_output: .dword 0x0000000000000000
reg_f16_output: .dword 0x0000000000000000
reg_f17_output: .dword 0x0000000000000000
reg_f18_output: .dword 0x0000000000000000
reg_f19_output: .dword 0x0000000000000000
reg_f20_output: .dword 0x0000000000000000
reg_f21_output: .dword 0x0000000000000000
reg_f22_output: .dword 0x0000000000000000
reg_f23_output: .dword 0x0000000000000000
reg_f24_output: .dword 0x0000000000000000
reg_f25_output: .dword 0x0000000000000000
reg_f26_output: .dword 0x0000000000000000
reg_f27_output: .dword 0x0000000000000000
reg_f28_output: .dword 0x0000000000000000
reg_f29_output: .dword 0x0000000000000000
reg_f30_output: .dword 0x0000000000000000
reg_f31_output: .dword 0x0000000000000000

        .align 8
csr_output_data:
ustatus_output:        .dword 0x0000000000000000                   
uie_output:            .dword 0x0000000000000000               
utvec_output:          .dword 0x0000000000000000                 
uscratch_output:       .dword 0x0000000000000000                    
uepc_output:           .dword 0x0000000000000000                
ucause_output:         .dword 0x0000000000000000                  
utval_output:          .dword 0x0000000000000000                 
uip_output:            .dword 0x0000000000000000               
fflags_output:         .dword 0x0000000000000000                 
frm_output:            .dword 0x0000000000000000               
fcsr_output:           .dword 0x0000000000000000                
sstatus_output:        .dword 0x0000000000000000                   
sedeleg_output:        .dword 0x0000000000000000                   
sideleg_output:        .dword 0x0000000000000000                   
sie_output:            .dword 0x0000000000000000               
stvec_output:          .dword 0x0000000000000000                 
scounteren_output:     .dword 0x0000000000000000 
sscratch_output:       .dword 0x0000000000000000                    
sepc_output:           .dword 0x0000000000000000                
scause_output:         .dword 0x0000000000000000                  
stval_output:          .dword 0x0000000000000000                 
sip_output:            .dword 0x0000000000000000               
satp_output:           .dword 0x0000000000000000                
mhartid_output:        .dword 0x0000000000000000                   
mstatus_output:        .dword 0x0000000000000000                   
medeleg_output:        .dword 0x0000000000000000                   
mideleg_output:        .dword 0x0000000000000000                   
mie_output:            .dword 0x0000000000000000               
mtvec_output:          .dword 0x0000000000000000                 
mcounteren_output:     .dword 0x0000000000000000     
mscratch_output:       .dword 0x0000000000000000                    
mepc_output:           .dword 0x0000000000000000                
mcause_output:         .dword 0x0000000000000000                  
mtval_output:          .dword 0x0000000000000000                 
mip_output:            .dword 0x0000000000000000               
pmpcfg0_output:        .dword 0x0000000000000000                   
pmpcfg1_output:        .dword 0x0000000000000000                   
pmpcfg2_output:        .dword 0x0000000000000000                   
pmpcfg3_output:        .dword 0x0000000000000000                   
pmpaddr0_output:       .dword 0x0000000000000000                    
pmpaddr1_output:       .dword 0x0000000000000000                    
pmpaddr2_output:       .dword 0x0000000000000000                    
pmpaddr3_output:       .dword 0x0000000000000000                    
pmpaddr4_output:       .dword 0x0000000000000000                    
pmpaddr5_output:       .dword 0x0000000000000000                    
pmpaddr6_output:       .dword 0x0000000000000000                    
pmpaddr7_output:       .dword 0x0000000000000000                    
pmpaddr8_output:       .dword 0x0000000000000000                    
pmpaddr9_output:       .dword 0x0000000000000000                    
pmpaddr10_output:      .dword 0x0000000000000000 
pmpaddr11_output:      .dword 0x0000000000000000 
pmpaddr12_output:      .dword 0x0000000000000000 
pmpaddr13_output:      .dword 0x0000000000000000 
pmpaddr14_output:      .dword 0x0000000000000000 
pmpaddr15_output:      .dword 0x0000000000000000 
mcycle_output:         .dword 0x0000000000000000     
minstret_output:       .dword 0x0000000000000000                    
mcycleh_output:        .dword 0x0000000000000000                   
minstreth_output:      .dword 0x0000000000000000         

RVTEST_DATA_END  

    .section .data.random0;
    .align  8;

_random_data0:
                .dword 0x5d85a95370545716, 0xbaaa6a6ecfdc0d1a
                .dword 0x76040892b02e8ebf, 0xa1d4cfd7b7f41f1c
d_0_0:          .dword 0xc836f33cc408b594, 0x7a6f4ce96a0cb039
d_0_1:          .dword 0xb9375006004e7030, 0x840f42bf06da324e
d_0_2:          .dword 0x278a96ba006599ad, 0xfe20bcce62f9cf79
d_0_3:          .dword 0x87c23008eeddcfc6, 0x786944dd3f3b4d3c
d_0_4:          .dword 0x3ef57edb65358649, 0xe169b9a77964706d
d_0_5:          .dword 0x10b6e1aeda8865de, 0xb7272d95bfdc94a1
d_0_6:          .dword 0xb9a3601920b4784b, 0x2f8ee59f91408cc3
d_0_7:          .dword 0x426a5211d462fcfa, 0xa5134c7ad356cec6
d_0_8:          .dword 0x2d99be371aac7613, 0x12bfa82123196d92
d_0_9:          .dword 0x7af3c3e3c0db4874, 0x23d8cd4b6a8fad55
d_0_10:         .dword 0xaf833776435a86af, 0x83ed75d443f3b457
d_0_11:         .dword 0x435549217093bc8e, 0xa1823dc502a5765f
d_0_12:         .dword 0x761e301da7fefb44, 0x91a5f62f4116d8f2
d_0_13:         .dword 0x20f38b6ed3f22199, 0x0f4ca544632a28f7
d_0_14:         .dword 0x838f4c6ae73b8ee2, 0xc9cf0534500c98b9
d_0_15:         .dword 0x0c860f036304f342, 0xb1fe048fec17651c
d_0_16:         .dword 0x757857af5e5fd6f5, 0xd53f85970bc5956f
d_0_17:         .dword 0x2f70e31ce8ec7bc0, 0xcc800fd5fecd298f
d_0_18:         .dword 0x5dc9b5a7849b5e4e, 0x89ffc1a6064fa785
d_0_19:         .dword 0x7636dc6af758bb0f, 0x3ef8a9caa3359f6a
d_0_20:         .dword 0x47ed7ea2a4fc4987, 0x0bde4bcb96ebc466
d_0_21:         .dword 0xc018659ed2e42816, 0xa197a7fd4c89a73d
d_0_22:         .dword 0xb99df3882be6b8ba, 0x3d583e5dbdc70122
d_0_23:         .dword 0xea010d57069a4277, 0xe0f61db34c991142
d_0_24:         .dword 0x35e8d199b4bfe2d2, 0xd51f4113eea8fc28
d_0_25:         .dword 0xfdee67f5a24235c3, 0xb7320ccc7a20cb39
d_0_26:         .dword 0xd0b225fc750ebd6e, 0x7cabe953424a1777
d_0_27:         .dword 0x51144671b4831a00, 0xfae90de18fc4927f
                .dword 0x70afb07b9d28fd04, 0xfb6198d94cf8db9e
                .dword 0x626b4c50bf278640, 0x85cae9f146c177a7
        /* Random data */
_end_data0:
                 

    .section .data.random1;
    .align  8;

_random_data1:
                .dword 0x4d689f17224a095e, 0x583a54f93ddefd88
                .dword 0x587f0da73cad7f99, 0x7bbf80a64d7e43a4
d_1_0:          .dword 0x74e40306cb8b97e9, 0xfe7b9939586afd5e
d_1_1:          .dword 0x36c1d69fe70086e4, 0xf32c45b8a8dec974
d_1_2:          .dword 0xff05eec2af1afcab, 0x3474a9548293cecd
d_1_3:          .dword 0x12f72c9638618e4b, 0xf28c3eac84d300dd
d_1_4:          .dword 0xcf82b167180449a1, 0x19865e96ffc4fc02
d_1_5:          .dword 0x50710ff61d11a57e, 0xa8afcb3a68bc06dc
d_1_6:          .dword 0x1f29b7972602a3cb, 0x393918820a5aa952
d_1_7:          .dword 0xb3939f8504c30a11, 0xb106eb53af774215
d_1_8:          .dword 0x448f5ec83365f9b0, 0xc114d2765d609fdc
d_1_9:          .dword 0xefcff19e6cbd2370, 0xf7de17f922ea63aa
d_1_10:         .dword 0xf1504fe588a8f94a, 0x83132d8a2ed0899d
d_1_11:         .dword 0x71bdd8d3d475f546, 0x7a52625e7a4e2970
d_1_12:         .dword 0x184109eaf03c4f11, 0x8c20187fccef42d7
d_1_13:         .dword 0x6f02a15df27481c7, 0xf8be0eddca98098d
d_1_14:         .dword 0x892255ee3f1e37c2, 0xdc4fa601b8650709
d_1_15:         .dword 0xab5a402bd240ac11, 0x50d068196c2c0b4d
d_1_16:         .dword 0xb529bb760225bbff, 0x76caf93dd539e5d0
d_1_17:         .dword 0x6f31bd1980606675, 0xbe4d2edf10f3bdd8
d_1_18:         .dword 0x7329636401848d00, 0xe6154601a2186f18
d_1_19:         .dword 0xcc3b6ac41bc68ae3, 0xf98fb1d1cc0a4502
d_1_20:         .dword 0xe6cbb63eddd7815b, 0x059bb78a43f9140b
d_1_21:         .dword 0x5c711e437022734c, 0x0029b3dc6db1dec5
d_1_22:         .dword 0xc585c13d7e8ceed5, 0x95f908693ba4d980
d_1_23:         .dword 0x103779759e86c4a3, 0x35702ec0b65e2ac1
d_1_24:         .dword 0x4f068be11ac343fb, 0xaaa14fcaf3dba581
d_1_25:         .dword 0x3cc023b4e769de5a, 0x76efb2251458b95e
d_1_26:         .dword 0x9557d731ca7ee990, 0xb4d25ee51217ba37
d_1_27:         .dword 0x4f3da036f73a9ef3, 0x450e715390dc8893
                .dword 0x3f49eabf2d2ab19a, 0x472af6e11377810e
                .dword 0xde263e8625f0561d, 0x697b0e63a8c219f2
        /* Random data */
_end_data1:


    .section .data.random2;
    .align  8;

_random_data2:
                .dword 0x1ab2fc9510070fc4, 0x6093fa0654426212
                .dword 0xc4cda835637b5602, 0x071078beba25f7fa
d_2_0:          .dword 0xf60f21c8527e85de, 0x78b27acf9eb85a19
d_2_1:          .dword 0xf94698e976de1b71, 0xf0b788f65cb65c21
d_2_2:          .dword 0x884a8c5b1a8189a5, 0xb0d53872cc4de261
d_2_3:          .dword 0xacd89d269e394298, 0x806b27cc6007b968
d_2_4:          .dword 0x041c528e330f49cd, 0x1441b5ad999af643
d_2_5:          .dword 0x59174b57952f5846, 0x92cfaac47e245907
d_2_6:          .dword 0x03cf740c61d9d066, 0xa04dce57b2f1510e
d_2_7:          .dword 0x576a3f7a07a3fa3b, 0xbdcfac6279360c3f
d_2_8:          .dword 0x184a495a342b9494, 0x5177dafe1c528966
d_2_9:          .dword 0x47a29b3f8b3de317, 0xb6960fdfd28acadf
d_2_10:         .dword 0x59b3d9393677545c, 0x4f796d4f698fc4bf
d_2_11:         .dword 0x4c6dfbee699621d7, 0x5a7b4b61e47f4b4d
d_2_12:         .dword 0x1e7fd0a893a235c4, 0x1e028ea0ba485572
d_2_13:         .dword 0x852ef650bfede21b, 0x95f73699145576e4
d_2_14:         .dword 0x3f4990c48a9be7ee, 0xdb732279a880ac2c
d_2_15:         .dword 0x80b6dfbcdd79aeea, 0x1d9a93f177dcd718
d_2_16:         .dword 0x16dc07cc0b4819e8, 0xda027a311590b501
d_2_17:         .dword 0xdf01eb8fbe0ffa19, 0x09a4628dd380f09a
d_2_18:         .dword 0xe0f35fef3971f557, 0x172d3eec2a4d3394
d_2_19:         .dword 0xe2a266b8f8de03be, 0xd23da9c47f28ae13
d_2_20:         .dword 0xc3eb02245e34a9e7, 0xde77fb4861e268be
d_2_21:         .dword 0x4a7c340386308618, 0x5c8167ecafa45e27
d_2_22:         .dword 0x3f253bdad6512706, 0x97218d3f2c73dd00
d_2_23:         .dword 0xb501f67b61b23114, 0x7a36bde074d15d5e
d_2_24:         .dword 0x8573e842661a29b4, 0xcddb3199b26a1616
d_2_25:         .dword 0x8cae6ea5d19a3b57, 0xde1f7dcfd534315d
d_2_26:         .dword 0x38bb9ad9a029b406, 0xae1375c5780bb6d9
d_2_27:         .dword 0x9cb2753f904b56c7, 0x28c61e58a4a75e0e
                .dword 0xa6c62af5d275ae64, 0x64ff4cd8339cdd7b
                .dword 0xad127dd54dfd78d4, 0xad6e8575be93b060
         /* Random data */
_end_data2:
                

    .section .data.random3;
    .align  8;

_random_data3:
                .dword 0x6547330ec4ce769a, 0x48f50204ef514c57
                .dword 0xcbdcb2743fa98dde, 0x639c93035dbb9e2f
d_3_0:          .dword 0x7787426f9a0ed9ee, 0x09debdf79527579f
d_3_1:          .dword 0xbecf28e90b751150, 0x5c2cce131c798d82
d_3_2:          .dword 0x4e5d644cd5ce1f36, 0x781ea21c36f1a509
d_3_3:          .dword 0x6d4635299350862f, 0x0b292e6d1191ff10
d_3_4:          .dword 0xca6ea1ed416eb1a2, 0xef16d71a2c1e09b4
d_3_5:          .dword 0xed972ab8147a65ca, 0x88d95051a085428c
d_3_6:          .dword 0xbcc276d7554d5d64, 0xaf52930898d8871d
d_3_7:          .dword 0xad160dda4845bd8d, 0xb6cbc5bae8b8fada
d_3_8:          .dword 0x827ff001471b6af8, 0xb1b0e8065c85a2ec
d_3_9:          .dword 0x0bbcfe1d9d3024e2, 0xcd14d3f41e68af2e
d_3_10:         .dword 0x4fd7719076e7aa41, 0xd07c987c8da59355
d_3_11:         .dword 0xb86508dbc8faf72f, 0xd9408c4e40ef34d6
d_3_12:         .dword 0xfec6c789a2b6b907, 0x384551303403f584
d_3_13:         .dword 0x655c151e0ff73b51, 0x2e1af9041704810a
d_3_14:         .dword 0x3bdb21101fbb7928, 0x6092f85b3c8962cd
d_3_15:         .dword 0x6293f26c3c746d51, 0x0a1fd5ca6e818ba7
d_3_16:         .dword 0x336be022d4e8f717, 0xcadea74f30d6e46b
d_3_17:         .dword 0xa19a6ad97dd5cac9, 0xf918b15fdfca965b
d_3_18:         .dword 0x6b8e1bfdc23d45f1, 0x7d448839227047a7
d_3_19:         .dword 0x404673d32133c450, 0x3cebe4ca2165714b
d_3_20:         .dword 0xde96443e54e0c646, 0xb1d9b8fb07b769f9
d_3_21:         .dword 0x5d00aff553799a6b, 0xacb3aaac03b0203e
d_3_22:         .dword 0xa1df1aa293833ec7, 0xdc2d9de12149797f
d_3_23:         .dword 0xa8d22533d9670db3, 0x525228ca377f99f4
d_3_24:         .dword 0xb25c516f5e28c215, 0x440c21c0658a79e0
d_3_25:         .dword 0xd27b059ea5e5373a, 0x9abaf52328a4a61f
d_3_26:         .dword 0x23bd9a768e3c3b18, 0x9cf69379461a72ad
d_3_27:         .dword 0x58c5a61766acce38, 0x441a8082addb1648
                .dword 0xb02bf2c3b6990684, 0x1a06cba9fad2f1cd
                .dword 0x765a31cccd4cfb48, 0x8d786d38fb180f5a
        /* Random data */
_end_data3:


    .section .data.random4;
    .align  8;

_random_data4:
                .dword 0x7b11081031c0d963, 0x9920de47d8ca582a
                .dword 0xa1ec452a2d158a53, 0x8083fddb13cab5fb
d_4_0:          .dword 0xbe3a10d64e1b8a48, 0xcc72da646d61487c
d_4_1:          .dword 0xd6db73295f7cf58a, 0x12458c1de65412da
d_4_2:          .dword 0x915de64c1c552f8c, 0x0dd438a422705a5e
d_4_3:          .dword 0x44c02a97ec7bb6d3, 0x8f80a34fe4e4839a
d_4_4:          .dword 0xe8bab5a73948ad2e, 0x2de7aed57d921250
d_4_5:          .dword 0x61676a8a18d68acb, 0xd0850dd6247b2ceb
d_4_6:          .dword 0x419b7e26fabc024c, 0x84b4a5fe2b6462e0
d_4_7:          .dword 0x8d93522698e0f9a6, 0x129b459cc4f1e8ac
d_4_8:          .dword 0x8d7191cbed2cc5f5, 0xa32b333ca8d715d0
d_4_9:          .dword 0x4d87714a406a2352, 0x9c06310d9976da70
d_4_10:         .dword 0x5bdc92696166238e, 0xa47f24f2bb5924c6
d_4_11:         .dword 0x4b15ea63f58f7c8a, 0x1ecf16bd13fa6812
d_4_12:         .dword 0x06058ac73e2a550a, 0xc48a98631df94085
d_4_13:         .dword 0x4f3553193af2c1c3, 0xd8f99b8bb9c3678b
d_4_14:         .dword 0x634d00f871eb86cf, 0x39b2bb0b5fec9ab3
d_4_15:         .dword 0x575648d3f76a7d8a, 0x502cf6a3f665e234
d_4_16:         .dword 0xedd9a0ad41d81875, 0x78836e4fc5ae2af6
d_4_17:         .dword 0xba1554c786b8c261, 0xdf8f9496900c8946
d_4_18:         .dword 0x592d3e9df6c2c651, 0x2d754461d8b703de
d_4_19:         .dword 0x76e5dce6ad72bdba, 0x13a703041f6e4f6c
d_4_20:         .dword 0x1e70d353e0c7e9b7, 0xbca61540276ae3c4
d_4_21:         .dword 0x5ce26f56693d6bef, 0xe94515d40a7c44ee
d_4_22:         .dword 0xab75039a1163645d, 0x75fd9e10edcf9745
d_4_23:         .dword 0xda62909a4a247ebe, 0xdc12c2ec4c974077
d_4_24:         .dword 0x9449f4a055edbb62, 0x08acc9bb70274536
d_4_25:         .dword 0x6bf3f799dd39b82a, 0x26d8bdfcf57c4980
d_4_26:         .dword 0xdce437bcaaa140ff, 0xfc79463834d3aafc
d_4_27:         .dword 0x9829a03d0f9f5a54, 0x00c5f76bb8f70bce
                .dword 0xb523de82ce7697ee, 0xbeaeb552d433ce44
                .dword 0xfa3c300a74de9d7f, 0x895b038a2bff27d8
        /* Random data */
_end_data4:


    .section .data.random5;
    .align  8;

_random_data5:
                .dword 0x4e20a11ea4d07a7c, 0xf7f6520a992fd243
                .dword 0x934e27be20f32521, 0xe8ad8c0f880fe2c5
d_5_0:          .dword 0x2335a53ac0b95eeb, 0x1566c0fda42cfaee
d_5_1:          .dword 0x9c0dfad3d8388e9f, 0x0ebc7357f0428ec7
d_5_2:          .dword 0xd25a7209f1a4bbaf, 0xccb258db5060149b
d_5_3:          .dword 0xbda64d730e0b7318, 0xadece872e5972545
d_5_4:          .dword 0xbd20e9ec61b43259, 0x2173aca34322c33c
d_5_5:          .dword 0xf24ddc744aad1086, 0xf2c6e8969efc31e5
d_5_6:          .dword 0x9b87012a2596aaf6, 0x0466d5468184fce4
d_5_7:          .dword 0x65d74c855a862097, 0xea34f0cf1f4ff119
d_5_8:          .dword 0xb0fa4d210ac7250c, 0x4c78eaed777f79c6
d_5_9:          .dword 0x72ddc9fc5fdec6b3, 0x0bc1ddc762c41fc0
d_5_10:         .dword 0x756ea3917fea0d09, 0xa787674d80587bb4
d_5_11:         .dword 0x853fcf053c47659b, 0xb3d7dce6120654ea
d_5_12:         .dword 0xaf4c44366b991890, 0xeee92e5c84b97bd2
d_5_13:         .dword 0xb292bbe581a28a6d, 0x014dca37d0e86ae0
d_5_14:         .dword 0x07dc765d4eb39c42, 0x807f2e3501ad200f
d_5_15:         .dword 0xb2790bc9f0a97408, 0x4f7ffd0a1b154376
d_5_16:         .dword 0xa11a34422b4a9a4c, 0xe8d2f4da1434c17b
d_5_17:         .dword 0xf0aba0097d2be3bf, 0xde1ff6e415849251
d_5_18:         .dword 0x3ef15b9672adbb20, 0x0f424cf289f25de6
d_5_19:         .dword 0xb13b058890bbd5b2, 0x86ada4cd84e2d308
d_5_20:         .dword 0xf93770c3e7c3d55d, 0x32c919697a59a482
d_5_21:         .dword 0x08a07c1126aa4830, 0x28b71c35b980b7a7
d_5_22:         .dword 0x5e544b52ab03d1be, 0xc53c2860c67138d1
d_5_23:         .dword 0xecd3e19da9ddcb80, 0xc4bd05c819f07f14
d_5_24:         .dword 0xfcec6c5867af0ccb, 0x1b9f5583b05b2e83
d_5_25:         .dword 0xbc1bb84311beb5bd, 0xb23e7e755a89823f
d_5_26:         .dword 0xac741c283c05199d, 0x74df210c54ce2c40
d_5_27:         .dword 0x7a26cd62be71b221, 0x83f92b2dfdd6be2d
                .dword 0x90bd806351846d54, 0x9e98d78b6e07d720
                .dword 0x0c1e22a8b85f185b, 0xb2ba707e4cf78f1e
         /* Random data */
_end_data5:
              
 

