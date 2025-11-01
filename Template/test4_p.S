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
_s0:    remw x2, x18, x3                          ;
_s1:    sllw x17, x29, x18                        ;
_s2:    blt x15, x29, _s3                         ;
_s3:    srlw x18, x1, x27                         ;
_s4:    la x6, d_1_12                             ;
        lh x23, -28(x6)                           ;
_s5:;
        /* Fuzz suffix */
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
  1:    li a0, (MSTATUS_FS & (MSTATUS_FS >> 0));
        csrs mstatus, a0;
        init_mie;
        csrwi fcsr, 0;
        call init_freg
        csrw minstret,zero
        csrr a0, mhartid;
_fuzz_prefix:
_p0:    csrrsi x13, sie, 30                       ;
_p1:    csrrsi x10, frm, 31                       ;
_p2:;
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
_l0:    la x2, d_1_21                             ;
        addi x2, x2, 28                           ;
        amomin.w x24, x23, (x2)                   ;
_l1:    mulw x8, x9, x18                          ;
_l2:    srlw x21, x7, x27                         ;
_l3:    feq.s x13, f1, f8                         ;
_l4:    la x3, d_5_6                              ;
        sd x20, 0(x3)                             ;
_l5:    fcvt.l.s x12, f27, dyn                    ;
_l6:    la x4, _l23                                       ;
        csrrw zero, uepc, x4                      ;
        uret                                      ;
_l7:    csrrwi x23, sie, 1                        ;
_l8:    fmsub.s f22, f25, f22, f25, rmm           ;
_l9:    fnmadd.s f10, f21, f17, f7, rtz           ;
_l10:   andi x27, x27, 1533                       ;
_l11:   la x8, d_0_22                             ;
        addi x8, x8, -16                          ;
        amoadd.d x13, x27, (x8)                   ;
_l12:   auipc x20, 451966                         ;
_l13:   remw x10, x0, x19                         ;
_l14:   blt x10, x10, _l84                        ;
_l15:   la x3, d_4_15                             ;
        sb x29, 31(x3)                            ;
_l16:   la x31, d_1_16                            ;
        lhu x4, -0(x31)                           ;
_l17:   la x4, d_5_15                             ;
        lui x5, 0xffe00                           ;
        xor x4, x4, x5                            ;
        lwu x4, 4(x4)                             ;
_l18:   la x21, d_3_22                            ;
        srai x21, x21, 1                          ;
        csrrc x2, pmpaddr5, x21                   ;
_l19:   la x14, d_0_24                            ;
        lui x14, 0xffe00                          ;
        xor x14, x14, x14                         ;
        sw x5, 8(x14)                             ;
_l20:   divw x2, x5, x8                           ;
_l21:   la x17, d_2_9                             ;
        lwu x11, 8(x17)                           ;
_l22:   mul x2, x8, x2                            ;
_l23:   la x24, d_5_9                             ;
        addi x24, x24, -8                         ;
        amoor.d x8, x19, (x24)                    ;
_l24:   fcvt.s.w f3, x21, rmm                     ;
_l25:   sraw x3, x21, x27                         ;
_l26:   la x9, d_1_1                              ;
        sb x3, -30(x9)                            ;
_l27:   fmv.w.x f8, x10                           ;
_l28:   andi x11, x8, 2047                        ;
_l29:   csrrci x22, mie, 3                        ;
_l30:   divuw x10, x22, x4                        ;
_l31:   la x25, d_4_16                            ;
        addi x25, x25, -12                        ;
        amoand.w x29, x1, (x25)                   ;
_l32:   la x29, d_2_2                             ;
        sw x2, -4(x29)                            ;
_l33:   jal x19, _l41                                     ;
_l34:   la x11, d_3_25                            ;
        addi x11, x11, -0                         ;
        amoadd.d x27, x9, (x11)                   ;
_l35:   la x4, d_1_13                             ;
        addi x4, x4, -16                          ;
        amoor.d x10, x21, (x4)                    ;
_l36:   xor x8, x8, x8                            ;
        csrrs x9, sip, x8                         ;
_l37:   sltiu x15, x22, 0                         ;
_l38:   fadd.s f24, f8, f3, rdn                   ;
_l39:   slli x5, x16, 6                           ;
_l40:   remuw x5, x20, x1                         ;
_l41:   la x4, d_3_25                             ;
        addi x4, x4, -28                          ;
        amoxor.w x18, x2, (x4)                    ;
_l42:   fmv.w.x f10, x9                           ;
_l43:   fadd.s f12, f28, f14, rdn                 ;
_l44:   la x16, d_5_5                             ;
        addi x16, x16, -16                        ;
        lui x25, 0xffe00                          ;
        xor x16, x16, x25                         ;
        amoswap.d x10, x25, (x16)                 ;
_l45:   andi x29, x10, 472                        ;
_l46:   fmv.x.w x29, f3                           ;
_l47:   ori x27, x15, 405                         ;
_l48:   csrrci x15, frm, 18                       ;
_l49:   remuw x10, x13, x10                       ;
_l50:   xor x17, x17, x17                         ;
        addi x26, zero, 1                         ;
        slli x26, x26, 3                          ;
        add x17, x17, x26                         ;
        csrrc x28, mhartid, x17                   ;
_l51:   fcvt.s.wu f0, x19, rtz                    ;
_l52:   mulhu x7, x2, x30                         ;
_l53:   lui x25, 696355                           ;
_l54:   bge x15, x26, _l95                                ;
_l55:   la x29, d_4_0                             ;
        addi x29, x29, 0                          ;
        amomaxu.d x4, x18, (x29)                  ;
_l56:   xor x11, x11, x11                         ;
        csrrw x5, sepc, x11                       ;
_l57:   andi x1, x20, 240                         ;
_l58:   srliw x9, x9, 29                          ;
_l59:   sllw x12, x17, x21                        ;
_l60:   slliw x12, x21, 0                         ;
_l61:   la x30, d_0_16                            ;
        addi x30, x30, -24                        ;
        amominu.d x29, x26, (x30)                 ;
_l62:   jal x13, _l82                                     ;
_l63:   fence                                     ;
_l64:   slti x28, x7, 1906                        ;
_l65:   la x11, _l84                              ;
        csrrw zero, mepc, x11                     ;
        mret                                      ;
_l66:   fmsub.s f8, f12, f20, f3, rup             ;
_l67:   la x8, d_0_17                             ;
        addi x8, x8, -0                           ;
        sc.d x22, x8, (x8)                        ;
_l68:   la x13, d_5_13                            ;
        addi x13, x13, 16                         ;
        amoand.d x12, x4, (x13)                   ;
_l69:   la x22, _l78                                      ;
        csrrw zero, mepc, x22                     ;
        mret                                      ;
_l70:   la x27, d_4_10                            ;
        sd x17, 0(x27)                            ;
_l71:   la x26, d_2_10                            ;
        srai x26, x26, 1                          ;
        csrrs x25, pmpaddr0, x26                  ;
_l72:   la x4, d_3_13                             ;
        addi x4, x4, -28                          ;
        amoand.w x11, x21, (x4)                   ;
_l73:   la x28, d_4_6                             ;
        sd x3, -0(x28)                            ;
_l74:   la x26, d_5_22                            ;
        addi x26, x26, -12                        ;
        lr.w x16, (x26)                           ;
_l75:   la x21, d_2_20                            ;
        sh x30, -0(x21)                           ;
_l76:   fcvt.l.s x16, f4, rmm                     ;
_l77:   la x10, d_4_3                             ;
        addi x10, x10, 4                          ;
        lr.w x4, (x10)                            ;
_l78:   fcvt.s.lu f14, x29, rtz                   ;
_l79:   la x21, d_4_19                            ;
        addi x21, x21, -8                         ;
        amomaxu.w x26, x3, (x21)                  ;
_l80:   fcvt.lu.s x30, f31, rdn                   ;
_l81:   la x14, _l88                                      ;
        csrrw zero, mepc, x14                     ;
        mret                                      ;
_l82:   blt x30, x1, _l87                                 ;
_l83:   fcvt.s.l f25, x29, rtz                    ;
_l84:   la x14, _l94                                      ;
        csrrw zero, mepc, x14                     ;
        mret                                      ;
_l85:   addw x25, x25, x23                        ;
_l86:   slli x12, x0, 33                          ;
_l87:   la x14, _l8                               ;
        ld x28, -0(x14)                           ;
_l88:   fence                                     ;
_l89:   la x1, d_0_0                              ;
        lbu x22, -0(x1)                           ;
_l90:   la x2, d_4_2                              ;
        addi x2, x2, -0                           ;
        amomaxu.d x23, x23, (x2)                  ;
_l91:   la x22, _l92                                      ;
        ld x7, 16(x22)                            ;
_l92:   div x9, x23, x28                          ;
_l93:   la x2, d_1_5                              ;
        addi x2, x2, 0                            ;
        amomax.d x14, x24, (x2)                   ;
_l94:   remw x29, x22, x7                         ;
_l95:   la x9, _l2                                        ;
        ld x10, 24(x9)                            ;
_l96:;
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
                .dword 0x5dfc991d496aef9e, 0x874290442c946ab2
                .dword 0xd16a384976676b21, 0xe7863170c41fc1d7
d_0_0:          .dword 0x477bc9c138ef4de8, 0x7a614a8a877b7816
d_0_1:          .dword 0xf97b76ba180ecb92, 0x00ad1d0a3ecdc1ae
d_0_2:          .dword 0xbbd6692edd240973, 0xc4413757c11e6c63
d_0_3:          .dword 0xb1cf620d3898dfea, 0x0446b9f7b7d44b3a
d_0_4:          .dword 0xbbed41ae87411814, 0x959702d3e6f969f4
d_0_5:          .dword 0x7ac3556f7442e5d6, 0xde79fa8e0252ffad
d_0_6:          .dword 0x249cfbccc0a5bf85, 0x0c48a78c53a6fda6
d_0_7:          .dword 0x24c8432e449d2dd4, 0x5ceef24e1a2a8f08
d_0_8:          .dword 0x5c8288155a4966cc, 0xcbbb8d114b4e6baf
d_0_9:          .dword 0x6c616e6ff99b9d89, 0x950ba2087c224e3d
d_0_10:         .dword 0x64fe661296e2cb24, 0x1a319c45c755648c
d_0_11:         .dword 0xe66e707a65582014, 0xaef81dcc28aad67b
d_0_12:         .dword 0xa7f84da84510b434, 0xdf47b9efca68b913
d_0_13:         .dword 0xc2d2583e9e95de80, 0x37eb4da86fc75cc6
d_0_14:         .dword 0x0be17dbfdfe16be7, 0x2a10b5821f2b285f
d_0_15:         .dword 0x103caa6e717fcdca, 0x43c1a39c35898d57
d_0_16:         .dword 0x3d8b36db28137eca, 0xc5b46480ba0160c7
d_0_17:         .dword 0x4fbcac4f77ecf6bf, 0x215b789d0a0708ac
d_0_18:         .dword 0x0496737e9551f0e1, 0xc8aeb55707fd868d
d_0_19:         .dword 0xad9c31929979e0c0, 0xeabd06c4b88f7f1b
d_0_20:         .dword 0x09906c1333545362, 0x7cc8af48e04675ea
d_0_21:         .dword 0x175dfa8388068805, 0x1177234463c5f690
d_0_22:         .dword 0x99a8c7f638c1d330, 0x9f8e1165d0bac16b
d_0_23:         .dword 0x96309f23a16e076e, 0xdcbe5226d326c5cf
d_0_24:         .dword 0x6fc1040169686a19, 0x216597f4a115efd6
d_0_25:         .dword 0x0ef9119774b6c9e2, 0x8a4369c6cec72e86
d_0_26:         .dword 0x78e84c21a70b4dd5, 0x1bd7cc5a865dfb4f
d_0_27:         .dword 0x9eb95694fe7b52b8, 0x68bde1a3963a22e9
                .dword 0xab78432765e5bbd1, 0x02a387aebc762b97
                .dword 0xf03748ddef9b8e7d, 0x46bab5d143a5b90c
        /* Random data */
_end_data0:
                 

    .section .data.random1;
    .align  8;

_random_data1:
                .dword 0x967ac4e4217e73c3, 0xa549fb18773cfce9
                .dword 0xa61b09f84b10247a, 0x36f2767ce5653d80
d_1_0:          .dword 0x8870aa0d8e5a60d0, 0xa8e76d0eabf21dab
d_1_1:          .dword 0x45bca41b30553ebb, 0x98610eefa51ccc82
d_1_2:          .dword 0xb9d93472c98b08bf, 0x99ad59512e5f6ae0
d_1_3:          .dword 0x27d432be4846f2ad, 0x896ea1f2e851e30d
d_1_4:          .dword 0xdfdb4061f8ce231a, 0x39622bc83e65804a
d_1_5:          .dword 0x1e8615590c6084f8, 0x0a82de667668ed09
d_1_6:          .dword 0xd0dfa6873ea47e81, 0xc9dbeeac69d327f3
d_1_7:          .dword 0xef2d172195d1cff8, 0x3b4601df778906f1
d_1_8:          .dword 0xbdc1ca47476957be, 0x1e2ee34870554044
d_1_9:          .dword 0x1f25bd8414962e40, 0x4bf965cd36fe118e
d_1_10:         .dword 0xb8ab4aab6201607d, 0xb02a93b930c67a78
d_1_11:         .dword 0x894c43da8f2aba31, 0xb72e327803ea6b6c
d_1_12:         .dword 0x0689e667901a2e17, 0x548515c8bd7a5744
d_1_13:         .dword 0xcee4c6ab731cbeb6, 0xf8566242963a1f53
d_1_14:         .dword 0x66ef7611ffe2032d, 0x4684bb0d0af49c15
d_1_15:         .dword 0xc97d7cabbdb5fbe9, 0xd86656fa23067439
d_1_16:         .dword 0xcaced4f9abacc68a, 0xd99b4c2b34d22bab
d_1_17:         .dword 0x4d932ff81ff1c93a, 0xd5823bc45c351629
d_1_18:         .dword 0x766acf86dab1816c, 0x9e2743df21efdf85
d_1_19:         .dword 0x91d10c0cfacc3f50, 0xdcee57782761120a
d_1_20:         .dword 0x674ccdac77c537c8, 0x2874a3b55ac022e2
d_1_21:         .dword 0xe017627ea02a76a9, 0x16be8f40166adf3f
d_1_22:         .dword 0xfbe3e6b8559009cb, 0x757175f4229d73ab
d_1_23:         .dword 0x7f12a23bd6b9d77e, 0x2d92fac27a4c484c
d_1_24:         .dword 0x1f92fd9d64a25cce, 0x901f338c83e8e8c9
d_1_25:         .dword 0xeb2a73546051290f, 0xe54dcdaa40971466
d_1_26:         .dword 0x78f9a8605381fa0e, 0xe5b70118aff46e87
d_1_27:         .dword 0x7ea58e350bbb16a3, 0x6ff3344bab3ed4cc
                .dword 0x783e70578296c36c, 0xb7253b07a4fa3eb7
                .dword 0xd8b48b0fc0c1c335, 0xa1e86efdd0c50822
        /* Random data */
_end_data1:


    .section .data.random2;
    .align  8;

_random_data2:
                .dword 0xe1389bf8a0547330, 0x2398d28f0f423011
                .dword 0xd91fdb53e19af083, 0xa32befb87a347f98
d_2_0:          .dword 0xa06ccea6649375de, 0xdd6721a41e81e7ab
d_2_1:          .dword 0xe5dde2aae4c950d6, 0x886885af3f696604
d_2_2:          .dword 0x1f88a38cf0dd387d, 0x0232044f1fe01d1a
d_2_3:          .dword 0xec21c1576a1060dd, 0x3c8671ab69d85467
d_2_4:          .dword 0xa6904ed55e1ae8a7, 0x8eee12540a326bbe
d_2_5:          .dword 0xb668469b610d2336, 0xa881eaaad214b0da
d_2_6:          .dword 0x63c7e07466b9a22a, 0x886aa89cd3783d25
d_2_7:          .dword 0x6bf938b9105f0f5b, 0x348bca78cd44c414
d_2_8:          .dword 0x9b7c05dc68903056, 0x70b5b1c57d846ae0
d_2_9:          .dword 0x7f3f458aeb76bd62, 0x462aa1b11e7808c3
d_2_10:         .dword 0xf92bbc228f48e7ba, 0xec3017265a13dffe
d_2_11:         .dword 0xad0722db0ad65a22, 0xebab0b9809765812
d_2_12:         .dword 0x6e596bf32f7f9335, 0x936d8724776e0c35
d_2_13:         .dword 0xe5962783c393ff4f, 0xe29bc347fd71d491
d_2_14:         .dword 0xb50339438f7689ce, 0x58a8be62ed29ce6e
d_2_15:         .dword 0xa0cf06f81a42afb1, 0x0c0ab796a852e518
d_2_16:         .dword 0x367272325ddbf193, 0x51315c4101c53306
d_2_17:         .dword 0x9c5043989d32b2bc, 0x77104ce9f0e04259
d_2_18:         .dword 0xc8d1b6b8fac5781e, 0x420ab2f23e958a0d
d_2_19:         .dword 0xad65381c51f164c0, 0xc8dc5e6593c3f40e
d_2_20:         .dword 0xbe44b3fe44fc8689, 0x1f6fd077bae96f52
d_2_21:         .dword 0x03aa6cf7788df596, 0xd5ee58cfd141c203
d_2_22:         .dword 0x990185f192faadc2, 0x8beb4ba28f924aac
d_2_23:         .dword 0x677f53d9196316ee, 0x582333f8baae7706
d_2_24:         .dword 0x2fd2d21e1726ace3, 0xa54be4c345b19c7e
d_2_25:         .dword 0x516cc4d4b7f2e495, 0xb17d91d8eb7afdee
d_2_26:         .dword 0xcd8916d8954dbaed, 0x54da1815ffb40fd0
d_2_27:         .dword 0x3e44b848f6ad8551, 0xba4c44eca594062a
                .dword 0x46840a48a5a64de7, 0x8789cea68237f946
                .dword 0x290b9f23b9809202, 0x13613465ea599ca4
         /* Random data */
_end_data2:
                

    .section .data.random3;
    .align  8;

_random_data3:
                .dword 0x33212c057027dafa, 0x2ee69d4e66d718b3
                .dword 0x8ba3e115e7782f34, 0x1ce43b4f9eb3ec91
d_3_0:          .dword 0x0e518a54063137ee, 0xd38ac568cb44c21d
d_3_1:          .dword 0xe1ce9632256e1979, 0x7428d1055fa2d6b6
d_3_2:          .dword 0x12491291a05cbb67, 0x3b195c81f6cf875f
d_3_3:          .dword 0xa37abac4b26f667c, 0x1963dc918ab1eb15
d_3_4:          .dword 0x8c01d6192cb8f09f, 0x1294d6235dec35bf
d_3_5:          .dword 0x5d8a921ef06cd6b4, 0xf0c1fb2062154b4b
d_3_6:          .dword 0x96c9be68d2239ea6, 0x33ad2a8882208b82
d_3_7:          .dword 0x7c1fb192cdda3447, 0x00571d043a5bd0b0
d_3_8:          .dword 0x98b6fb82c5639e55, 0x1e17887ee998b440
d_3_9:          .dword 0x1eb4c5d6cc489062, 0xa4ff985dcee07fd6
d_3_10:         .dword 0x52784d9cd4987ab9, 0xd8d1db5d44981d7b
d_3_11:         .dword 0x91f265fc1e9b5bca, 0xa382acac17b2273b
d_3_12:         .dword 0xfbd7b95581c7246b, 0xd9ac64c2625c712e
d_3_13:         .dword 0xe546d8489653ea7a, 0xce48106b0e8e5fcf
d_3_14:         .dword 0x3988eeed79674728, 0xac3f98bb7cf9f5dd
d_3_15:         .dword 0x830e7dd2586278ef, 0x16b5b8310d9dbf6e
d_3_16:         .dword 0xd3e555f6d4906393, 0x9299007433bbf6d8
d_3_17:         .dword 0xa5c8fe0246397e84, 0x59c5c6a1332f1823
d_3_18:         .dword 0x536e8bad436d916c, 0xeafdc8081b78c957
d_3_19:         .dword 0x108aab525752df14, 0x6bbb0b98b8677b7e
d_3_20:         .dword 0xfe1d9c5f1854ed1c, 0xb9919dea2a28f1bf
d_3_21:         .dword 0x279016f5d6af611d, 0xb94b5bb83ce67ff9
d_3_22:         .dword 0xdc7082cdab3379a3, 0xd6b412e90bb04cd3
d_3_23:         .dword 0x741ae2516f6bd99e, 0xf1b4287859697a15
d_3_24:         .dword 0x0e3565793776fe1b, 0x1d9eed17df535dd1
d_3_25:         .dword 0xc24945380260d7e1, 0x106bfe0f7a6c923c
d_3_26:         .dword 0xb2e82e2c011b3efc, 0x536a04fccd1aeab2
d_3_27:         .dword 0x3962085b50ec38b2, 0x862b4f1d3336b69a
                .dword 0x48f3a5e741655747, 0x1ad23eb496f06bd5
                .dword 0x936859a9ccb42de1, 0x8256d20021a0548b
        /* Random data */
_end_data3:


    .section .data.random4;
    .align  8;

_random_data4:
                .dword 0xce4a2c0ceba41207, 0x82925758f45f7fce
                .dword 0x887366fd21e2a606, 0xfa3665d54a3c90bc
d_4_0:          .dword 0x11947a262490e26d, 0x507b0142a49a43fe
d_4_1:          .dword 0x7fd9c2207715bc95, 0x6c361a243763c5ca
d_4_2:          .dword 0xc8dbeaf13a3271f4, 0xdd085ee03243f811
d_4_3:          .dword 0x5c0c72b4e24808e4, 0xa4d73a1c1559cdb3
d_4_4:          .dword 0xcf7f58ea7ca10d09, 0x47f8f03fc56920b5
d_4_5:          .dword 0x3540c0cf825d376e, 0x2d9de05a4c3b9e31
d_4_6:          .dword 0x629dec0f4bcf5f13, 0xe0b8bfd19728b1fa
d_4_7:          .dword 0xed775f32adf7118d, 0xdb1b4c0bad149bdb
d_4_8:          .dword 0x53219ff7cc111887, 0x91ec3bd1daea0e68
d_4_9:          .dword 0x438e2d8fdf3ed193, 0xce113f2bf4268dd9
d_4_10:         .dword 0x0451d85809247fc8, 0xbcda20f2511d2cf3
d_4_11:         .dword 0x745feb747b9f786a, 0x61f9ffc9f701bb6d
d_4_12:         .dword 0xd458c37700fbd4f9, 0x4880708a4931fb17
d_4_13:         .dword 0x5bd4f2d2fbda7a93, 0xe3d46480b46d64a1
d_4_14:         .dword 0x511bb37bd8ccf407, 0xa34dd7910c2461bd
d_4_15:         .dword 0x3d0ff2079d4f51b4, 0x28e19137b7ef96dd
d_4_16:         .dword 0xb675afac250ff4d0, 0xb34c4ca5d2d5a795
d_4_17:         .dword 0xb15b80f165d56d44, 0x7c211f18e7ac86a5
d_4_18:         .dword 0x0ccfce4ba5fcb70a, 0xea2d3fcb89a4c499
d_4_19:         .dword 0xb7bf64a6b45e05a4, 0xa0e7399a20c83601
d_4_20:         .dword 0xee99137ec6bbcb40, 0x1c024950f65aab38
d_4_21:         .dword 0xaf9ce2db52ecf609, 0xa9d0c348d71108ad
d_4_22:         .dword 0x403c1b2fe3630863, 0xa96b795f03c891b4
d_4_23:         .dword 0xeb8e29d8be263415, 0xeacf9878e8b52ec4
d_4_24:         .dword 0x1b2e93082236594e, 0x8a27479221d89037
d_4_25:         .dword 0x0696249989b434c3, 0x68769bd6c5a493fb
d_4_26:         .dword 0xdc50654da7ffc6db, 0xbd71b524d1233534
d_4_27:         .dword 0x4e744de76264eaec, 0x9dbecbcc9b1aae51
                .dword 0xbc9544401124b843, 0xfb2f3225efed2743
                .dword 0xdd87f405e79be884, 0x6c249d190be29c56
        /* Random data */
_end_data4:


    .section .data.random5;
    .align  8;

_random_data5:
                .dword 0x1fb0f61d716f8894, 0x4ceb853bdbc93b93
                .dword 0x2742f1ba16843de2, 0x70af2f42cd3a4e2f
d_5_0:          .dword 0xac2e0ea8891491b4, 0x681be652225471cb
d_5_1:          .dword 0x20a65ec0e8d1b8b0, 0xf023649bcfa2f9fd
d_5_2:          .dword 0x697e344a537e4e5f, 0x08e28426e782f000
d_5_3:          .dword 0x584ffe02b973a715, 0xf30c7445d98ff6fc
d_5_4:          .dword 0xe61dfd3c1781914f, 0xd19f306c3fad684b
d_5_5:          .dword 0x56dad6d001a46285, 0x7171849e782d1701
d_5_6:          .dword 0x3c1e9a7f8e9f97c6, 0x21fc8087265d0a1c
d_5_7:          .dword 0x09a1711d568697c4, 0x9bed0d143e478d50
d_5_8:          .dword 0x15a82aff11ae4673, 0xd9b1f3535fdee9e1
d_5_9:          .dword 0x965f9fc6085eae63, 0x680a1d75b4209fca
d_5_10:         .dword 0xeabba194d267cd61, 0xd425c36479c037c2
d_5_11:         .dword 0x3415384a90639356, 0xa429848bff9317db
d_5_12:         .dword 0xffa6044c964ea762, 0x3b77d6ea9dc10f14
d_5_13:         .dword 0xde70c40ed5419a1f, 0x961f67b4938e0159
d_5_14:         .dword 0xf55688896c252e92, 0x47af783e26af30fd
d_5_15:         .dword 0x2cd3f61d648c80ff, 0x2f17d42ce4758f23
d_5_16:         .dword 0x15a858204bf74d33, 0xaef879041796812e
d_5_17:         .dword 0x04f343619ebce589, 0xb602792a303faf9d
d_5_18:         .dword 0x186901428547d1e4, 0xb508277fcab5ad21
d_5_19:         .dword 0x10a3deb7f2233688, 0x637408b8b693de11
d_5_20:         .dword 0xc4d85dc2a2c8dc6e, 0x829b57b4bb5952b1
d_5_21:         .dword 0xad5253fab6c5b95f, 0xfde619a33a481c9a
d_5_22:         .dword 0x179fa3d02942aeed, 0x140fe253c604e7fd
d_5_23:         .dword 0x1d30e4e72656390c, 0x4c630dd1b66b2a43
d_5_24:         .dword 0xb2d3fa926a9068e0, 0xe0c69bba0d91fa61
d_5_25:         .dword 0x2d26f58bfabc376a, 0x8ab7723eab4b1310
d_5_26:         .dword 0x07bd02af8ae2c50c, 0x1f80a068dc98373a
d_5_27:         .dword 0x21a3bcff5688bada, 0xaeb6d40d488f66b9
                .dword 0x8294a075f4813ccd, 0x7a099616b9d3d6f6
                .dword 0x9332032202cdf23a, 0x9604ae66ad3ae2d1
         /* Random data */
_end_data5:
              
                 
