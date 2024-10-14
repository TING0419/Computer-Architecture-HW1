.data
numbers: .word 0x40490fdb, 0x7FC00000, 0xC2480000  # 包含一個 NaN 測試值
sign_mask: .word 0x80000000
exp_mask:  .word 0x7F800000
man_mask:  .word 0x007FFFFF
inf_mask:  .word 0x7F800000  # 用於檢測 NaN 的遮罩

valueis:   .string "value is: "
nextline:  .string "\n"
nan_str:   .string "NaN\n"

.text
.global _start

_start:
    la s5, numbers       # s5 指向數字陣列的起始地址
    li s6, 3             # s6 = 陣列長度（3個數字）
    li s7, 0             # s7 = 迴圈計數器

loop_start:
    bge s7, s6, loop_end  # 如果 s7 >= s6，跳出迴圈

    lw s0, 0(s5)          # 載入當前的 FP32 數字到 s0

    # 提取絕對值（去除符號位）
    la t4, sign_mask
    lw t4, 0(t4)
    not t4, t4            # t4 = ~sign_mask
    and t5, s0, t4        # t5 = s0 & ~sign_mask

    # 載入無窮大模式
    la t6, inf_mask
    lw t6, 0(t6)

    # 檢查是否為 NaN
    bgt t5, t6, is_nan    # 如果絕對值大於無窮大，則說明是 NaN

    # 正常處理（舍入和轉換）
    # 提取低 16 位，存入 t1
    slli t1, s0, 16       # t1 = s0 << 16
    srli t1, t1, 16       # t1 = (s0 << 16) >> 16，提取低 16 位

    # 提取高 16 位，存入 t0
    srli t0, s0, 16       # t0 = s0 >> 16，提取高 16 位

    # 處理舍入
    li t2, 0x8000         # t2 = 0x8000
    blt t1, t2, no_round  # 如果低 16 位 < 0x8000，不需要舍入
    bgt t1, t2, round_up  # 如果低 16 位 > 0x8000，需要舍入
    # 低 16 位 == 0x8000，需要檢查高 16 位的最低位
    andi t3, t0, 1        # t3 = t0 & 0x1，提取高 16 位的最低位
    beqz t3, no_round     # 如果最低位為 0，不需要舍入
    # 否則，需要舍入
round_up:
    addi t0, t0, 1        # 高 16 位加 1
no_round:
    # t0 現在包含 BF16 的值
    j print_result

is_nan:
    # 輸出 "NaN"
    la a0, valueis
    li a7, 4              # 系統呼叫：輸出字串
    ecall

    la a0, nan_str
    li a7, 4              # 系統呼叫：輸出字串
    ecall

    # 準備下一次迴圈
    addi s5, s5, 4        # s5 = s5 + 4，指向下一個數字
    addi s7, s7, 1        # s7 = s7 + 1
    j loop_start          # 跳回迴圈開始

print_result:
    # 輸出結果
    la t1, valueis
    mv a0, t1
    li a7, 4              # 系統呼叫：輸出字串
    ecall

    mv a0, t0             # 將 BF16 值存入 a0
    li a7, 34             # 系統呼叫：輸出十六進位整數
    ecall

    la a0, nextline
    li a7, 4
    ecall

    # 準備下一次迴圈
    addi s5, s5, 4        # s5 = s5 + 4，指向下一個數字
    addi s7, s7, 1        # s7 = s7 + 1
    j loop_start          # 跳回迴圈開始

loop_end:
    # 程式結束
    li a7, 93             # 系統呼叫：退出
    li a0, 0
    ecall