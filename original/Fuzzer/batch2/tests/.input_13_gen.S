# Assembly file template for fuzzing

#*********************************************************************
# test_template.S
#---------------------------------------------------------------------

#include "riscv_test.h"
#include "test_macros.h"
#include "fuzz_test.h"

#define TESTEND gp

RVTEST_RV64UF

// RVTEST_CODE_BEGIN
        .section .text.init;
        .align  6;
        .weak stvec_handler;
        .weak mtvec_handler;
        .global _start;
_start:
        /* reset vector */
INIT_XREGS
        j reset_vector;
        .align;
init_freg:
INIT_FREGS
        ret
        .align;
trap_stvec:
        clear_sie;
_fuzz_suffix:
_s0:    ebreak                                    ;
_s1:    jal x23, _s5                              ;
_s2:    fcvt.lu.s x30, f11, rdn                   ;
_s3:    mulw x30, x16, x6                         ;
_s4:    subw x26, x12, x14                        ;
_s5:;
        /* Fuzz trap */
        /**/
_end_suffix:
        ecall
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
reset_vector:
        csrwi mstatus, 0;
        RISCV_MULTICORE_DISABLE;
        DELEGATE_NO_TRAPS;
        INIT_SATP;
        INIT_PMP;
        la t0, trap_mtvec;
        csrw mtvec, t0;
        li TESTEND, 0;
        CHECK_XLEN;
        la t0, trap_stvec;
        csrw stvec, t0;
        li t0, (1 << CAUSE_LOAD_PAGE_FAULT) | \
                (1 << CAUSE_STORE_PAGE_FAULT) | \
                (1 << CAUSE_FETCH_PAGE_FAULT) | \
                (1 << CAUSE_MISALIGNED_FETCH) | \
                (1 << CAUSE_USER_ECALL) | \
                (1 << CAUSE_BREAKPOINT);
        csrs medeleg, t0;
  1:    li a0, (MSTATUS_FS & (MSTATUS_FS >> 0)) | \
                (MSTATUS_MPP & (MSTATUS_MPP >> 1));
        csrs mstatus, a0;
        init_mie;
        csrwi fcsr, 0;
        call init_freg
        csrw minstret,zero
        csrr a0, mhartid;
_fuzz_prefix:
_p0:    csrrsi x11, satp, 31                      ;
_p1:    csrrci x12, pmpaddr2, 21                  ;
_p2:    csrrsi x12, pmpaddr3, 0                   ;
_p3:;
        /* Fuzz prefix */
        /**/
_end_prefix:
        la t0, main;
        csrw mepc, t0;
        addi t0, zero, 0;
        mret;
  1:
      
      .align 6;

main:
_fuzz_main:
_l0:    ebreak                                    ;
_l1:    lui x5, 125091                            ;
_l2:    fcvt.s.lu f25, x12, dyn                   ;
_l3:    fnmadd.s f3, f3, f3, f25, rdn             ;
_l4:    srai x23, x9, 35                          ;
_l5:    la x12, d_5_20                            ;
        addi x12, x12, 0                          ;
        amoand.w x19, x15, (x12)                  ;
_l6:    bge x11, x23, _l107                       ;
_l7:    la x21, _l45                              ;
        csrrw zero, mepc, x21                     ;
        mret                                      ;
_l8:    fnmadd.s f13, f25, f0, f27, rup           ;
_l9:    la x10, d_3_26                            ;
        addi x10, x10, -16                        ;
        lr.d x17, (x10)                           ;
_l10:   la x23, d_5_17                            ;
        addi x23, x23, 4                          ;
        amoswap.w x15, x26, (x23)                 ;
_l11:   la x1, d_2_24                             ;
        addi x1, x1, -0                           ;
        amoand.w x10, x28, (x1)                   ;
_l12:   csrrsi x6, pmpaddr1, 0                    ;
_l13:   ecall                                     ;
_l14:   auipc x12, 5                              ;
_l15:   fnmsub.s f1, f31, f6, f0, rmm             ;
_l16:   la x19, _l58                              ;
        lh x14, -0(x19)                           ;
_l17:   mulh x27, x10, x4                         ;
_l18:   fdiv.s f28, f7, f9, dyn                   ;
_l19:   fmul.s f6, f15, f3, rmm                   ;
_l20:   ecall                                     ;
_l21:   feq.s x22, f27, f27                       ;
_l22:   ecall                                     ;
_l23:   la x22, d_2_1                             ;
        addi x22, x22, -8                         ;
        amomin.w x6, x1, (x22)                    ;
_l24:   sllw x1, x23, x26                         ;
_l25:   ecall                                     ;
_l26:   fcvt.wu.s x4, f27, rdn                    ;
_l27:   csrrsi x25, pmpaddr5, 19                  ;
_l28:   la x3, d_1_1                              ;
        addi x3, x3, -0                           ;
        amomax.w x11, x12, (x3)                   ;
_l29:   li x2, 1                                  ;
        la x6, pt1                                ;
        addi x6, x6, 8                            ;
        sfence.vma x2, x6                         ;
_l30:   csrrci x29, pmpaddr7, 30                  ;
_l31:   mulw x27, x29, x3                         ;
_l32:   xor x7, x7, x7                            ;
        addi x4, zero, 1                          ;
        slli x4, x4, 27                           ;
        add x7, x7, x4                            ;
        addi x21, zero, 1                         ;
        slli x21, x21, 15                         ;
        add x7, x7, x21                           ;
        addi x15, zero, 1                         ;
        slli x15, x15, 26                         ;
        add x7, x7, x15                           ;
        csrrc x17, mscratch, x7                   ;
_l33:   la x21, _l19                              ;
        lwu x28, -20(x21)                         ;
_l34:   la x12, d_3_9                             ;
        lui x2, 0xffe00                           ;
        xor x12, x12, x2                          ;
        sd x29, 24(x12)                           ;
_l35:   la x16, _l100                             ;
        flw f18, 20(x16)                          ;
_l36:   la x12, d_5_6                             ;
        addi x12, x12, -28                        ;
        amoor.w x28, x19, (x12)                   ;
_l37:   blt x12, x23, _l90                        ;
_l38:   la x24, d_3_5                             ;
        addi x24, x24, -8                         ;
        amoor.w x7, x11, (x24)                    ;
_l39:   xori x27, x28, 469                        ;
_l40:   fclass.s x0, f9                           ;
_l41:   ecall                                     ;
_l42:   la x19, d_5_16                            ;
        addi x19, x19, -20                        ;
        amominu.w x5, x10, (x19)                  ;
_l43:   srai x28, x26, 10                         ;
_l44:   xori x6, x16, 1373                        ;
_l45:   divuw x12, x9, x21                        ;
_l46:   srlw x17, x10, x16                        ;
_l47:   mulh x2, x19, x17                         ;
_l48:   sllw x12, x2, x19                         ;
_l49:   la x9, d_5_7                              ;
        addi x9, x9, 16                           ;
        amoswap.d x11, x3, (x9)                   ;
_l50:   la x16, d_4_12                            ;
        srai x16, x16, 1                          ;
        csrrc x1, pmpaddr1, x16                   ;
_l51:   xor x8, x8, x8                            ;
        addi x29, zero, 1                         ;
        slli x29, x29, 29                         ;
        add x8, x8, x29                           ;
        addi x25, zero, 3                         ;
        slli x25, x25, 19                         ;
        add x8, x8, x25                           ;
        addi x16, zero, 3                         ;
        slli x16, x16, 16                         ;
        add x8, x8, x16                           ;
        csrrc x19, pmpcfg0, x8                    ;
_l52:   addi x26, x12, 298                        ;
_l53:   fadd.s f27, f9, f25, rtz                  ;
_l54:   fmin.s f19, f9, f18                       ;
_l55:   srlw x22, x24, x6                         ;
_l56:   la x7, d_4_24                             ;
        addi x7, x7, 0                            ;
        amoadd.w x26, x28, (x7)                   ;
_l57:   fle.s x5, f7, f22                         ;
_l58:   fclass.s x27, f14                         ;
_l59:   csrrci x6, sepc, 0                        ;
_l60:   la x13, d_0_12                            ;
        addi x13, x13, 16                         ;
        sc.w x22, x12, (x13)                      ;
_l61:   remuw x9, x23, x9                         ;
_l62:   la x25, d_4_19                            ;
        addi x25, x25, -20                        ;
        amoor.w x27, x25, (x25)                   ;
_l63:   divuw x6, x22, x14                        ;
_l64:   fsub.s f19, f18, f18, rmm                 ;
_l65:   srai x28, x7, 47                          ;
_l66:   fmadd.s f13, f31, f0, f27, rne            ;
_l67:   la x3, d_3_24                             ;
        addi x3, x3, 8                            ;
        amoadd.d x1, x13, (x3)                    ;
_l68:   la x14, d_4_16                            ;
        addi x14, x14, 24                         ;
        amoand.w x11, x25, (x14)                  ;
_l69:   la x12, d_2_19                            ;
        sh x28, 18(x12)                           ;
_l70:   la x8, d_1_2                              ;
        addi x8, x8, 24                           ;
        sc.d x12, x8, (x8)                        ;
_l71:   addw x5, x15, x17                         ;
_l72:   la x16, _l112                             ;
        csrrw zero, mepc, x16                     ;
        mret                                      ;
_l73:   sraiw x17, x9, 0                          ;
_l74:   fnmadd.s f3, f0, f2, f15, rne             ;
_l75:   fsub.s f1, f15, f3, rmm                   ;
_l76:   fmsub.s f8, f11, f14, f25, rmm            ;
_l77:   srlw x13, x6, x6                          ;
_l78:   slliw x0, x0, 3                           ;
_l79:   la x12, d_0_19                            ;
        lh x7, -0(x12)                            ;
_l80:   fcvt.s.w f19, x9, rup                     ;
_l81:   srli x12, x8, 8                           ;
_l82:   sraw x12, x6, x11                         ;
_l83:   xor x11, x11, x11                         ;
        csrrw x22, mscratch, x11                  ;
_l84:   bgeu x25, x19, _l106                      ;
_l85:   fadd.s f20, f7, f20, dyn                  ;
_l86:   srlw x19, x4, x7                          ;
_l87:   fsgnjn.s f22, f24, f21                    ;
_l88:   la x28, d_3_14                            ;
        addi x28, x28, 8                          ;
        amoadd.d x21, x10, (x28)                  ;
_l89:   blt x2, x1, _l107                         ;
_l90:   la x3, d_1_23                             ;
        addi x3, x3, -8                           ;
        sc.d x28, x3, (x3)                        ;
_l91:   fmin.s f29, f8, f16                       ;
_l92:   fence                                     ;
_l93:   fmsub.s f21, f11, f6, f7, rup             ;
_l94:   fsgnjx.s f27, f14, f9                     ;
_l95:   divw x27, x9, x24                         ;
_l96:   bltu x1, x11, _l100                       ;
_l97:   auipc x13, 30159                          ;
_l98:   blt x4, x30, _l103                        ;
_l99:   addi x2, x14, 1133                        ;
_l100:  fclass.s x29, f25                         ;
_l101:  bne x18, x3, _l111                        ;
_l102:  la x7, d_1_25                             ;
        addi x7, x7, -0                           ;
        amoswap.w x6, x30, (x7)                   ;
_l103:  divw x1, x11, x10                         ;
_l104:  fsgnj.s f16, f22, f27                     ;
_l105:  fcvt.s.wu f25, x10, rmm                   ;
_l106:  srai x30, x24, 0                          ;
_l107:  fmul.s f6, f8, f22, rne                   ;
_l108:  la x4, d_3_14                             ;
        addi x4, x4, -8                           ;
        lr.d x24, (x4)                            ;
_l109:  addi x24, x18, 788                        ;
_l110:  la x15, d_3_16                            ;
        addi x15, x15, 16                         ;
        amomaxu.w x4, x10, (x15)                  ;
_l111:  bge x9, x14, _l112                        ;
_l112:;
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

PT_BASES

    .section .data.random0;
    .align  8;

_random_data0:
                .dword 0x1bfb1e94a67e5cd8, 0x6c52ae334b640135
                .dword 0x6689b226de2d610e, 0xfda659e402e5aae7
d_0_0:          .dword 0x598f5721789d3eed, 0x11db247248051488
d_0_1:          .dword 0x54765a9d292561ed, 0xfaccb4ccad51171c
d_0_2:          .dword 0xa99553c4e4553b46, 0xbe4db6a3bbc3db42
d_0_3:          .dword 0x3a981fc9aa587829, 0xcd120c6d59c11320
d_0_4:          .dword 0x4c68301b66adaf5b, 0xad3a473934421999
d_0_5:          .dword 0xad7eee32e9c72011, 0x3041ccb8b509edc5
d_0_6:          .dword 0x02791f383b89338e, 0x31ba98abe81c843e
d_0_7:          .dword 0x1ed9d9ec92afd99e, 0x6aa4f12acd1041f7
d_0_8:          .dword 0x6589cd8a7b58e302, 0xdfefc5f6a05ea5b1
d_0_9:          .dword 0xf881d46946367685, 0xaed3a87fe1c2e27e
d_0_10:         .dword 0x1086d2b07e1615a1, 0xb77c96e550e52385
d_0_11:         .dword 0x5f492359717f171f, 0x0dacc7d2796cf85b
d_0_12:         .dword 0x92884f6427b758b3, 0xd66a372100ad5ba5
d_0_13:         .dword 0x49a087ae259fdaa6, 0x66a8273199e635cb
d_0_14:         .dword 0x6d2afeb563900fed, 0x616548b669967895
d_0_15:         .dword 0x87a6aa74ddcc4c7b, 0x182bd8faedac0616
d_0_16:         .dword 0x264b105bdd4b88eb, 0xf7015ffcb1acfe92
d_0_17:         .dword 0x51059072dc98487b, 0x4f6c59df97989410
d_0_18:         .dword 0x3ab1a786c6f286c9, 0x5ebb1eba8677c207
d_0_19:         .dword 0xbdcfeabe4e792c0a, 0xdd60433d1d40c8b0
d_0_20:         .dword 0xfb86dd58f18fb2e0, 0x8a20d07e86418cc4
d_0_21:         .dword 0x2e0c6f802a4ff3c0, 0x0576317ad133b3f4
d_0_22:         .dword 0xbb6591911aa9c3d6, 0x22a183b00c2130ce
d_0_23:         .dword 0x77543018efb279df, 0x9887521264d5c888
d_0_24:         .dword 0xa5496d759757f42f, 0x43ff46092e0292b3
d_0_25:         .dword 0x903b3e6ad9c81275, 0xe987a1d77b11ba7c
d_0_26:         .dword 0xb6a1bc2ab18865d7, 0xb2052a0990e1448e
d_0_27:         .dword 0xa62ae5d99cf871f8, 0xa5e40f891746121d
                .dword 0xd15236257144cd18, 0x24ffe66075670e15
                .dword 0x0046c1de9a734b19, 0x41037dc19b7bb104
        /* Random data */
_end_data0:
                 

    .section .data.random1;
    .align  8;

_random_data1:
                .dword 0x35b0eae44703b291, 0x8c7729e21ddcdef9
                .dword 0xf2d45352d108e7b3, 0xf9e387c621396f80
d_1_0:          .dword 0x73ca0f9e40e8c227, 0xcba40ad22385619c
d_1_1:          .dword 0x760418e587902481, 0x22c43ac29c2cfa34
d_1_2:          .dword 0x0c27de0746dccd94, 0x74da5818e560cb87
d_1_3:          .dword 0x9b6c22b4c79dd5a6, 0xf65d4691eb91818a
d_1_4:          .dword 0xb86408b3b35ab978, 0x8fb1b9feddf36422
d_1_5:          .dword 0xc0b0ee05c0c32f8a, 0xdf42c7f4b9cb9d4f
d_1_6:          .dword 0x8108a425c193b489, 0x3431389d29e952c9
d_1_7:          .dword 0xb8cebb5e2d9a4670, 0xccf5fb63d085ecd0
d_1_8:          .dword 0x5194715dfc8867e2, 0x82fc88274a9ede85
d_1_9:          .dword 0xad924601e1160062, 0xe611e283d54e33bd
d_1_10:         .dword 0xf85fc9b5adf12f98, 0xb8260c2a3dd01c5c
d_1_11:         .dword 0x399931bfd3f59fed, 0x6c576ddb7a08de86
d_1_12:         .dword 0x1eaffc7fd76ad1e1, 0xe03004dca2517bbf
d_1_13:         .dword 0xc0e9f17fb4745c2a, 0xcbf395c61b26e3c6
d_1_14:         .dword 0xe56ed80728737f07, 0xe28a88968b201924
d_1_15:         .dword 0xfb8aead86b9a36f8, 0xa23cce1ff3a17363
d_1_16:         .dword 0x814d342f71425c33, 0x14f325f7533fe7ef
d_1_17:         .dword 0x90c618aa5a4d36fa, 0xde163634ee41ef24
d_1_18:         .dword 0xe7481d6c1a1aaeb2, 0x54ccdff5c60b44bc
d_1_19:         .dword 0xb489e17cd73b8563, 0xc6f8238527533960
d_1_20:         .dword 0x6dc675d64e0e072f, 0xa06237cbf27a3474
d_1_21:         .dword 0x794c12fd841142e4, 0x3c32d159001c507a
d_1_22:         .dword 0xa8bb35e93b4c6c7e, 0x3f223019c695165d
d_1_23:         .dword 0xc38cb6d4e945eed9, 0xdbe1ab591379058e
d_1_24:         .dword 0xc8f617e553ce0106, 0x4387a5b45b87040d
d_1_25:         .dword 0x72b3b6e620bcd802, 0xe6d0564906037bf8
d_1_26:         .dword 0x96ed5591234bd82e, 0x394b21713766b4d9
d_1_27:         .dword 0xb1ff8c23fe5d1b51, 0x52c64010693177b5
                .dword 0x47b8f547fb0cce5c, 0x87fb2107b3a04944
                .dword 0x63bbdaec2ca87c2f, 0x1cf48779f87fd4d6
        /* Random data */
_end_data1:


    .section .data.random2;
    .align  8;

_random_data2:
                .dword 0x24e6c1744f778ad6, 0xb1af0aaa068842fd
                .dword 0x5fab66b9790e09c2, 0xc056f010029c5eb9
d_2_0:          .dword 0xb75c30ce282f10f5, 0x7c2fecda377cc470
d_2_1:          .dword 0x607a275e33863eec, 0x01f74c83c17378a4
d_2_2:          .dword 0x692bb3845296b6fe, 0xdd1806a95ad736e3
d_2_3:          .dword 0xbed4c5dca5557c06, 0x16076a20c7af36e0
d_2_4:          .dword 0x5f589cf68560c1ac, 0x3423f9d1afb3f426
d_2_5:          .dword 0x3a00fe87bc1cda77, 0x0d3e897d2724cbc8
d_2_6:          .dword 0x20a65ed37a7dd72b, 0xcddd737e978c6e19
d_2_7:          .dword 0x0a170f9dc571617d, 0x67fa279930512f45
d_2_8:          .dword 0x9dfaa4bbff0011c0, 0x1b115f99e6a7209a
d_2_9:          .dword 0x0a23ab85b91c5c32, 0xf25c30166ad74f33
d_2_10:         .dword 0x94f1fed93a85c9ed, 0x2756d2078ae2a73b
d_2_11:         .dword 0xe7ce648111751dad, 0x97dc93ef581634c6
d_2_12:         .dword 0x8fda2ae7a3496143, 0xff7b8c85de056a0f
d_2_13:         .dword 0x8296e2c4c1004b99, 0xc8d0209281dd20b0
d_2_14:         .dword 0xda46556dafc0857c, 0x1b417a6aa3c8c4d0
d_2_15:         .dword 0xa9ccc447acaa871b, 0xbdede7d7e4d1450b
d_2_16:         .dword 0xc5ac917e9dd66188, 0x7c613d6aca62ca08
d_2_17:         .dword 0x2d24a4d849c266b2, 0x77f0719e02533df8
d_2_18:         .dword 0x0f14dc96808d96f6, 0x59d193c188296f19
d_2_19:         .dword 0xed12cd0621d747a5, 0xbd110c1d6f003ef0
d_2_20:         .dword 0xbb111365b19d28d0, 0x21911446a10d1b74
d_2_21:         .dword 0x9a4e919f93bd53c4, 0x05a20db3b26d7aa4
d_2_22:         .dword 0x11871c61e5311463, 0xf4b3ace464046f00
d_2_23:         .dword 0xe9cfd3c15895c6e8, 0x79a8829c69ac4ae9
d_2_24:         .dword 0xdfb38c139ef3a3a8, 0x313758bacea84028
d_2_25:         .dword 0xeefcab15c2705590, 0xae423a7a190b38d7
d_2_26:         .dword 0x9a3b2ca33ce0a725, 0x0465568ca85307bf
d_2_27:         .dword 0x3a9057e7ed232980, 0x885d193bf1c0196b
                .dword 0x8689490a995f30f9, 0xf3d9c1bef0325e8b
                .dword 0xf3092d73e39adcec, 0xf25da39357930fb6
         /* Random data */
_end_data2:
                

    .section .data.random3;
    .align  8;

_random_data3:
                .dword 0x45f0e59a78e54683, 0x95628a3487ea378a
                .dword 0x4ff9f8a9d348ac4a, 0x681571e9d08553f2
d_3_0:          .dword 0x1cf96ab45204b579, 0xd19a20b42e559b32
d_3_1:          .dword 0xe2461e3cbad0ee20, 0x659a568f969f8242
d_3_2:          .dword 0x8f9929b288ebbf7a, 0x6a0c36e49ae4eff3
d_3_3:          .dword 0xe5990a3518b8f223, 0xc60f6c40b8cfe83f
d_3_4:          .dword 0x4ac5f314307b5929, 0xd04c08af88aa14f0
d_3_5:          .dword 0xc62349bdaeecb9a3, 0x92ec167ebf17dcd1
d_3_6:          .dword 0xee51900147b50aaa, 0xec8694341ab95498
d_3_7:          .dword 0x8c2c826489eee12a, 0x4bab17df3256850a
d_3_8:          .dword 0xa6f4bab7dae13c44, 0x55a75b5077f976a8
d_3_9:          .dword 0xc27e3d510186e1f3, 0xc5d18a3e2a3957a7
d_3_10:         .dword 0xd0306397cf1b16d8, 0xe2f9893b764aeb0a
d_3_11:         .dword 0x9b44c54031442f1f, 0x978a62e1f14e5c2a
d_3_12:         .dword 0x4d848fcef34fd3ff, 0x9a3b796672102a29
d_3_13:         .dword 0x878f5c328e9bce67, 0xf0b4d32c222dcc2f
d_3_14:         .dword 0xf8474afcf2a07b5a, 0x4c2754c954543642
d_3_15:         .dword 0x1a0d0bf4271f09ff, 0x51422a918bdec7eb
d_3_16:         .dword 0xc17dc69028cd646f, 0xef753f7817288e10
d_3_17:         .dword 0x292d7ca090f438f4, 0x685235c906125463
d_3_18:         .dword 0x381a2c72342d2248, 0x4ca609696dbf0fe5
d_3_19:         .dword 0xc98b0fc2c3963904, 0x9b990a6c8663a48d
d_3_20:         .dword 0x7a79c05fcad6e0ba, 0xe2d350b70819bb7c
d_3_21:         .dword 0x1ebf23a98ba4d9e0, 0x8193d6d0be6c5001
d_3_22:         .dword 0xcac81a9f45d85432, 0xb1097605a5eaebeb
d_3_23:         .dword 0x8ff51730d48fbb16, 0xc75c6ae866681a39
d_3_24:         .dword 0xe41dbf8d18895671, 0x3595bb53b58efe1c
d_3_25:         .dword 0x87f502fd0254d151, 0x4f3110fcced516ca
d_3_26:         .dword 0x1e3ce72b85949a1c, 0xaaf69d7c87c8a62e
d_3_27:         .dword 0x2d85360297211992, 0xcf15f5f3d03e82a5
                .dword 0x7ab82a388c06371f, 0x07c72093e6ad3a88
                .dword 0x29ec2d56f9f7e547, 0xfe885264dc8607a8
        /* Random data */
_end_data3:


    .section .data.random4;
    .align  8;

_random_data4:
                .dword 0x2c6af9c6c3407f5e, 0xe3bd4a7633d1476e
                .dword 0x6731c50cb717bb9e, 0x032b0725e8365d1e
d_4_0:          .dword 0x9f2bf5417f723b71, 0x264926cd643acce4
d_4_1:          .dword 0x750563a70d75b515, 0x0e93d71baa28b817
d_4_2:          .dword 0xe516d65835669aba, 0xf339640dca5a964a
d_4_3:          .dword 0xc1ce290609743289, 0x3659634229eb7c23
d_4_4:          .dword 0x896b7a785e08a2e2, 0xa4b36d1db932bedf
d_4_5:          .dword 0x3f2a6b00f8aaee14, 0x04fdd04a26b75c89
d_4_6:          .dword 0x62db21cc2c68e4d3, 0x2268258481d7237b
d_4_7:          .dword 0xce10dd26f996c143, 0x0aa87786b6a2af04
d_4_8:          .dword 0x32ec20c52ca91106, 0xba0f78f4171c40c2
d_4_9:          .dword 0x32b9341bc952654b, 0x5f4ce26c0bd58aba
d_4_10:         .dword 0x4f21198f09786522, 0xbda6ef6ebb2dfe3d
d_4_11:         .dword 0x233b646f1c4aa454, 0x6177a4f1a3858020
d_4_12:         .dword 0xc1992935beba7168, 0xb618daf9cbee49b7
d_4_13:         .dword 0xfd90b4fe2c602bcf, 0x81ef94e3090965a6
d_4_14:         .dword 0xec501fe61ed975b2, 0x6d4fcbccf29187cc
d_4_15:         .dword 0x569fb1c3e44c46a6, 0x59d384f53dcfd5fa
d_4_16:         .dword 0xcd6ffcd049d82814, 0x01cfab0269b8c5a2
d_4_17:         .dword 0xcc3da262cb8ddeac, 0xdeb58445f4de09c0
d_4_18:         .dword 0xb8d3d050e754d9d5, 0x216c1fe0ee8a03c6
d_4_19:         .dword 0x927ab08fba774d0b, 0x6bc2569365153e19
d_4_20:         .dword 0xb8200b0a212a7de4, 0x97da69d0631d5bb9
d_4_21:         .dword 0x1bbc069a95b38498, 0xcf521e9656738cc6
d_4_22:         .dword 0x0b064ae001854fad, 0x964352dd36d6560a
d_4_23:         .dword 0xa4422897327c3f81, 0x890adda3c0af5acf
d_4_24:         .dword 0x30552e4a14d3bdee, 0xb0ead1f519e51cc5
d_4_25:         .dword 0xe32fb14684eca290, 0x90001f0a2d7e3f9e
d_4_26:         .dword 0xee7b5309d532f047, 0x65036364b3fd3bbe
d_4_27:         .dword 0x89d350bc2b617359, 0xf2a23f4535361793
                .dword 0xa2ba80ee18a80c43, 0xfee91b8729d08821
                .dword 0xb74920af0334f11b, 0x996516a15ac96653
        /* Random data */
_end_data4:


    .section .data.random5;
    .align  8;

_random_data5:
                .dword 0x7397ad3c8d276eb6, 0xa0514b2c417d313f
                .dword 0x095bf420088f3ade, 0x99d6e41441d09f77
d_5_0:          .dword 0x7bb82ce62e3af842, 0x76940ca5942c294b
d_5_1:          .dword 0x12553029c6bbc998, 0x4476116ef3e7edf6
d_5_2:          .dword 0x9d84667065e14d29, 0xc3e90e540a09d267
d_5_3:          .dword 0x013e3115d13681b6, 0xea61cd596e6c3974
d_5_4:          .dword 0x0252c9d3ba6b65b5, 0x22a61a26ac652993
d_5_5:          .dword 0x888c3cf87eb041a6, 0xb884ff7ffa2163a3
d_5_6:          .dword 0x8fc5e99788c77c21, 0xa43fd1b6ae0dfb03
d_5_7:          .dword 0x27d32149d2c5bd9a, 0x7b27c215421d0e7d
d_5_8:          .dword 0xe6788e45811ce83e, 0x7fc2c531d294978f
d_5_9:          .dword 0x4b5a5b82910fd751, 0x422a2bdc1bb906fc
d_5_10:         .dword 0x0233fadb476a8712, 0x241fa78a32b9ba62
d_5_11:         .dword 0xc1ed000fab5f88e1, 0x5474ab3bf314dffb
d_5_12:         .dword 0xd7373f368d2c6fce, 0x7706fbfa58ba4ea7
d_5_13:         .dword 0x497ca789b9c26ee2, 0xda94e59b6898e2d0
d_5_14:         .dword 0x66166a9156d3865a, 0xdcf684d673dddf15
d_5_15:         .dword 0x183f8d847f00d12e, 0xaeb247ff9dc9c92d
d_5_16:         .dword 0xbcfebfb933623624, 0x5fd5ae11ac198c82
d_5_17:         .dword 0xe8dd2273649002c5, 0x4e2d9fcd810a023d
d_5_18:         .dword 0xee8288cd87cadf31, 0xf50987f8de092d7e
d_5_19:         .dword 0x029a0be6e53fddc1, 0x4f9474e49720fcb5
d_5_20:         .dword 0x826b9c4e2e7b8d61, 0xb01a6e45ccf1884b
d_5_21:         .dword 0xb15501057837b181, 0xf7497aeeadd9bc81
d_5_22:         .dword 0x39cc736d693e99cf, 0xc4c5bcf701c7c596
d_5_23:         .dword 0x516d6640bea18d8d, 0xdeb3954e38467bb9
d_5_24:         .dword 0x5d252491c9a53d4d, 0xb54be5ffa6918d64
d_5_25:         .dword 0xf9e63fecfaa56f27, 0x7198c39f5ee3f238
d_5_26:         .dword 0xfa3a013552d16801, 0xeb514593122ba85a
d_5_27:         .dword 0xc8f78b1969e73854, 0x1ebb8fd63d390a0d
                .dword 0xd5cffefa64228c8b, 0x3dbda0483cd3fcf1
                .dword 0x540c6d7d420298c9, 0x3f4fb9206db2f997
         /* Random data */
_end_data5:
              
                 
