.data

# test data
input1_1: .word 0x42491111  
input2_1: .word 0xc2931111  

input1_2: .word 0x3f800000   
input2_2: .word 0x40000000   

input1_3: .word 0x40490fdb  
input2_3: .word 0x3f8ccccd  

# mask
mask_sign: .word 0x80000000
mask_exponent: .word 0x7F800000
mask_mantissa: .word 0x007FFFFF

# 其他常數
increment_value: .word 0x00000080
mask_normalize: .word 0x00008000
mask_infinity: .word 0x7F800000
mask_shift8: .word 0x00008000
mask_result: .word 0xFFFF0000

# 要輸出的字串
str_value: .string "value is:"  # 顯示結果的前綴
str_newline: .string "\n"        # 換行
str_nan: .string "NaN"            # 非數值

.text    
.globl _start

_start:
    # 處理並顯示第一組資料
    la s5, input1_1
    la s6, input2_1
    jal convert_fp32_to_bf16  # 處理第一組資料
    jal display_result  # 打印第一組結果

    # 處理並顯示第二組資料
    la s5, input1_2
    la s6, input2_2
    jal convert_fp32_to_bf16  # 處理第二組資料
    jal display_result  # 打印第二組結果

    # 處理並顯示第三組資料
    la s5, input1_3
    la s6, input2_3
    jal convert_fp32_to_bf16  # 處理第三組資料
    jal display_result  # 打印第三組結果

    # 正常退出程序
    li a7, 93         # 系統調用號，93 表示退出
    li a0, 0          # 退出狀態碼 0
    ecall

convert_fp32_to_bf16:
    # s5: input1 的地址, s6: input2 的地址
    lw s0, 0(s5)   # 載入 input1
    lw s1, 0(s6)   # 載入 input2
    la s2, mask_exponent
    lw s2, 0(s2)
    la s3, mask_mantissa
    lw s3, 0(s3)

    # 提取 input1 的指數和尾數
    and t0, s0, s2   # 取出 input1 的指數部分
    and t1, s0, s3   # 取出 input1 的尾數部分
    bnez t0, exp1_non_zero  # 如果指數不為零，跳到下一段
    beqz t1, return_result     # 如果尾數是零，直接返回

exp1_non_zero:
    la s4, mask_infinity
    lw s4, 0(s4)
    beq t0, s4, return_result  # 如果指數是無窮大，直接返回
    la t0, mask_shift8  # 右移 8 位的掩碼
    lw t0, 0(t0)
    add s0, s0, t0
    la t0, mask_result  # 掩碼，捨棄低 16 位
    lw t0, 0(t0)
    and s0, s0, t0

    # 提取 input2 的指數和尾數
    and t0, s1, s2   # 取出 input2 的指數部分
    and t1, s1, s3   # 取出 input2 的尾數部分
    bnez t0, exp2_non_zero  # 如果指數不為零，跳到下一段
    beqz t1, return_result     # 如果尾數是零，直接返回

exp2_non_zero:
    la s4, mask_infinity
    lw s4, 0(s4)
    beq t0, s4, return_result  # 如果指數是無窮大，直接返回
    la t0, mask_shift8  # 右移 8 位的掩碼
    lw t0, 0(t0)
    add s1, s1, t0
    la t0, mask_result  #捨棄低 16 位
    lw t0, 0(t0)
    and s1, s1, t0

    # 進入主計算過程
    j calculate

return_result:
    ret  # 返回

calculate:
    # 計算結果的符號位
    la s2, mask_sign
    lw s2, 0(s2)
    xor t2, s0, s1
    and s10, t2, s2  # s10 保存結果的符號位

    # 計算結果的指數
    la s2, mask_exponent
    lw s2, 0(s2)
    and t3, s0, s2
    and t4, s1, s2
    srli t3, t3, 23
    srli t4, t4, 23
    addi t3, t3, -127  # 將偏移量調整
    addi t4, t4, -127
    add t3, t3, t4
    addi s11, t3, 127  # s11 保存結果的指數

    # 提取並準備尾數
    la s3, mask_mantissa
    lw s3, 0(s3)
    la s4, increment_value
    lw s4, 0(s4)
    and t3, s0, s3   # 提取 input1 的尾數
    and t4, s1, s3   # 提取 input2 的尾數
    srli t3, t3, 16
    srli t4, t4, 16
    or t3, t3, s4
    or t4, t4, s4
    mv s9, t3        # s9 保存處理後的 input1 尾數

    # 初始化乘法相關變量
    mv t5, x0        # 結果的累加器
    mv s7, x0        # 迴圈計數器
    mv s8, x0
    addi s8, s8, 8   # 將 s8 設為 8

    # 乘法迴圈開始
    andi t6, t4, 1   # 取出 input2 尾數的最低位
    srli t4, t4, 1   # 右移 input2 尾數
    beqz t6, mul_loop
    add t5, s9, t5

mul_loop:
    slli t3, t3, 1   # 左移 input1 尾數
    bge s7, s8, normalize_result
    addi s7, s7, 1
    andi t6, t4, 1   # 取出 input2 尾數的最低位
    srli t4, t4, 1   # 右移 input2 尾數
    beqz t6, mul_loop
    add t5, t3, t5
    j mul_loop

normalize_result:
    la s0, mask_normalize
    lw s0, 0(s0)
    and s0, s0, t5  # 檢查尾數是否需要歸一
    beqz s0, adjust_bits_15
    addi s11, s11, 1
    slli s11, s11, 24  # 截斷指數
    srli s11, s11, 1
    srli t5, t5, 7  # 捨棄多餘的位
    slli t5, t5, 24 
    srli t5, t5, 9  
    j combine_result

adjust_bits_15:
    slli s11, s11, 24
    srli s11, s11, 1
    srli t5, t5, 7  # 捨棄多餘的位
    slli t5, t5, 25 
    srli t5, t5, 9

combine_result:   
    or s10, s11, s10  # 組合符號位與指數位
    or s10, s10, t5   # s10 保存最終結果
    ret               # 返回

display_result:
    # 顯示每組資料的結果
    la t0, str_value
    mv a0, t0
    li a7, 4
    ecall
    mv a0, s10
    li a7, 34
    ecall
    la t1, str_newline
    mv a0, t1
    li a7, 4
    ecall
    ret               # 返回
