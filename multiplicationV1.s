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

# ��L�`��
increment_value: .word 0x00000080
mask_normalize: .word 0x00008000
mask_infinity: .word 0x7F800000
mask_shift8: .word 0x00008000
mask_result: .word 0xFFFF0000

# �n��X���r��
str_value: .string "value is:"  # ��ܵ��G���e��
str_newline: .string "\n"        # ����
str_nan: .string "NaN"            # �D�ƭ�

.text    
.globl _start

_start:
    # �B�z����ܲĤ@�ո��
    la s5, input1_1
    la s6, input2_1
    jal convert_fp32_to_bf16  # �B�z�Ĥ@�ո��
    jal display_result  # ���L�Ĥ@�յ��G

    # �B�z����ܲĤG�ո��
    la s5, input1_2
    la s6, input2_2
    jal convert_fp32_to_bf16  # �B�z�ĤG�ո��
    jal display_result  # ���L�ĤG�յ��G

    # �B�z����ܲĤT�ո��
    la s5, input1_3
    la s6, input2_3
    jal convert_fp32_to_bf16  # �B�z�ĤT�ո��
    jal display_result  # ���L�ĤT�յ��G

    # ���`�h�X�{��
    li a7, 93         # �t�νեθ��A93 ��ܰh�X
    li a0, 0          # �h�X���A�X 0
    ecall

convert_fp32_to_bf16:
    # s5: input1 ���a�}, s6: input2 ���a�}
    lw s0, 0(s5)   # ���J input1
    lw s1, 0(s6)   # ���J input2
    la s2, mask_exponent
    lw s2, 0(s2)
    la s3, mask_mantissa
    lw s3, 0(s3)

    # ���� input1 �����ƩM����
    and t0, s0, s2   # ���X input1 �����Ƴ���
    and t1, s0, s3   # ���X input1 �����Ƴ���
    bnez t0, exp1_non_zero  # �p�G���Ƥ����s�A����U�@�q
    beqz t1, return_result     # �p�G���ƬO�s�A������^

exp1_non_zero:
    la s4, mask_infinity
    lw s4, 0(s4)
    beq t0, s4, return_result  # �p�G���ƬO�L�a�j�A������^
    la t0, mask_shift8  # �k�� 8 �쪺���X
    lw t0, 0(t0)
    add s0, s0, t0
    la t0, mask_result  # ���X�A�˱�C 16 ��
    lw t0, 0(t0)
    and s0, s0, t0

    # ���� input2 �����ƩM����
    and t0, s1, s2   # ���X input2 �����Ƴ���
    and t1, s1, s3   # ���X input2 �����Ƴ���
    bnez t0, exp2_non_zero  # �p�G���Ƥ����s�A����U�@�q
    beqz t1, return_result     # �p�G���ƬO�s�A������^

exp2_non_zero:
    la s4, mask_infinity
    lw s4, 0(s4)
    beq t0, s4, return_result  # �p�G���ƬO�L�a�j�A������^
    la t0, mask_shift8  # �k�� 8 �쪺���X
    lw t0, 0(t0)
    add s1, s1, t0
    la t0, mask_result  #�˱�C 16 ��
    lw t0, 0(t0)
    and s1, s1, t0

    # �i�J�D�p��L�{
    j calculate

return_result:
    ret  # ��^

calculate:
    # �p�⵲�G���Ÿ���
    la s2, mask_sign
    lw s2, 0(s2)
    xor t2, s0, s1
    and s10, t2, s2  # s10 �O�s���G���Ÿ���

    # �p�⵲�G������
    la s2, mask_exponent
    lw s2, 0(s2)
    and t3, s0, s2
    and t4, s1, s2
    srli t3, t3, 23
    srli t4, t4, 23
    addi t3, t3, -127  # �N�����q�վ�
    addi t4, t4, -127
    add t3, t3, t4
    addi s11, t3, 127  # s11 �O�s���G������

    # �����÷ǳƧ���
    la s3, mask_mantissa
    lw s3, 0(s3)
    la s4, increment_value
    lw s4, 0(s4)
    and t3, s0, s3   # ���� input1 ������
    and t4, s1, s3   # ���� input2 ������
    srli t3, t3, 16
    srli t4, t4, 16
    or t3, t3, s4
    or t4, t4, s4
    mv s9, t3        # s9 �O�s�B�z�᪺ input1 ����

    # ��l�ƭ��k�����ܶq
    mv t5, x0        # ���G���֥[��
    mv s7, x0        # �j��p�ƾ�
    mv s8, x0
    addi s8, s8, 8   # �N s8 �]�� 8

    # ���k�j��}�l
    andi t6, t4, 1   # ���X input2 ���ƪ��̧C��
    srli t4, t4, 1   # �k�� input2 ����
    beqz t6, mul_loop
    add t5, s9, t5

mul_loop:
    slli t3, t3, 1   # ���� input1 ����
    bge s7, s8, normalize_result
    addi s7, s7, 1
    andi t6, t4, 1   # ���X input2 ���ƪ��̧C��
    srli t4, t4, 1   # �k�� input2 ����
    beqz t6, mul_loop
    add t5, t3, t5
    j mul_loop

normalize_result:
    la s0, mask_normalize
    lw s0, 0(s0)
    and s0, s0, t5  # �ˬd���ƬO�_�ݭn�k�@
    beqz s0, adjust_bits_15
    addi s11, s11, 1
    slli s11, s11, 24  # �I�_����
    srli s11, s11, 1
    srli t5, t5, 7  # �˱�h�l����
    slli t5, t5, 24 
    srli t5, t5, 9  
    j combine_result

adjust_bits_15:
    slli s11, s11, 24
    srli s11, s11, 1
    srli t5, t5, 7  # �˱�h�l����
    slli t5, t5, 25 
    srli t5, t5, 9

combine_result:   
    or s10, s11, s10  # �զX�Ÿ���P���Ʀ�
    or s10, s10, t5   # s10 �O�s�̲׵��G
    ret               # ��^

display_result:
    # ��ܨC�ո�ƪ����G
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
    ret               # ��^
