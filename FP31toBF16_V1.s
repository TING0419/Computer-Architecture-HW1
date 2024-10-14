.data
numbers:     .word 0x40490fdb, 0x7FC00000, 0xC2480000  # �]�t�@�� NaN ���խ�
sign_mask:   .word 0x80000000
inf_mask:    .word 0x7F800000  # �Ω��˴� NaN ���B�n

valueis:     .string "value is: "
nan_str:     .string "NaN\n"
nextline:    .string "\n"

.text
.global _start

_start:
    # ��l�ƱH�s��
    la      s5, numbers       # s5 ���V�Ʀr�}�C���_�l�a�}
    li      s6, 3             # s6 = �}�C���ס]3�ӼƦr�^
    li      s7, 0             # s7 = �j��p�ƾ�

    # �w�����J�B�n�M�r��a�}�A��ְj�餺�����J����
    lw      t4, sign_mask     # t4 = sign_mask
    not     t4, t4            # t4 = ~sign_mask
    lw      t6, inf_mask      # t6 = inf_mask

    la      a1, valueis      # a1 = "value is: "
    la      a2, nan_str      # a2 = "NaN\n"
    la      a3, nextline     # a3 = "\n"

loop_start:
    bge     s7, s6, loop_end  # �p�G s7 >= s6�A���X�j��

    lw      s0, 0(s5)          # ���J��e�� FP32 �Ʀr�� s0

    # ��������ȡ]�h���Ÿ���^
    and     t5, s0, t4        # t5 = s0 & ~sign_mask

    # �ˬd�O�_�� NaN
    bgt     t5, t6, is_nan    # �p�G����� > inf_mask�A�h�O NaN

    # ���`�B�z�]�٤J�M�ഫ�^
    # �����C 16 ��A�s�J t1
    slli    t1, s0, 16        # t1 = s0 << 16
    srli    t1, t1, 16        # t1 = (s0 << 16) >> 16�A�����C 16 ��

    # ������ 16 ��A�s�J t0
    srli    t0, s0, 16        # t0 = s0 >> 16�A������ 16 ��

    # �B�z�٤J
    li      t2, 0x8000         # t2 = 0x8000
    blt     t1, t2, no_round  # �p�G�C 16 �� < 0x8000�A���ݭn�٤J
    bgt     t1, t2, round_up  # �p�G�C 16 �� > 0x8000�A�ݭn�٤J
    # �C 16 �� == 0x8000�A�ݭn�ˬd�� 16 �쪺�̧C��
    andi    t3, t0, 1          # t3 = t0 & 0x1�A������ 16 �쪺�̧C��
    beqz    t3, no_round       # �p�G�̧C�쬰 0�A���ݭn�٤J
    # �_�h�A�ݭn�٤J

round_up:
    addi    t0, t0, 1          # �� 16 ��[ 1
    j       convert_to_hex

no_round:
    # t0 �{�b�]�t BF16 ����
    j       convert_to_hex

is_nan:
    # ��X "value is: NaN\n"

    # ��X "value is: "
    mv      a0, a1             # a0 = "value is: "
    li      a7, 4              # �t�ΩI�s���X�G4�]��X�r��^
    ecall

    # ��X "NaN\n"
    mv      a0, a2             # a0 = "NaN\n"
    li      a7, 4              # �t�ΩI�s���X�G4�]��X�r��^
    ecall

    # �ǳƤU�@���j��
    addi    s5, s5, 4          # s5 = s5 + 4�A���V�U�@�ӼƦr
    addi    s7, s7, 1          # s7 = s7 + 1
    j       loop_start         # ���^�j��}�l

convert_to_hex:
    # ��X "value is: "
    mv      a0, a1             # a0 = "value is: "
    li      a7, 4              # �t�ΩI�s���X�G4�]��X�r��^
    ecall

    # ��X BF16 �ȡ]���] a7=34 �O�۩w�q����X�Q���i��t�ΩI�s�^
    mv      a0, t0             # �N BF16 �Ȧs�J a0
    li      a7, 34             # �t�ΩI�s���X�G34�]��X�Q���i���ơ^
    ecall

    # ��X�����
    mv      a0, a3             # a0 = "\n"
    li      a7, 4              # �t�ΩI�s���X�G4�]��X�r��^
    ecall

    # �ǳƤU�@���j��
    addi    s5, s5, 4          # s5 = s5 + 4�A���V�U�@�ӼƦr
    addi    s7, s7, 1          # s7 = s7 + 1
    j       loop_start         # ���^�j��}�l

loop_end:
    # �{������
    li      a7, 93             # �t�ΩI�s���X�G93�]�h�X�^
    li      a0, 0              # ��^�ȡG0
    ecall
