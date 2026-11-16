
.eqv RX_CTRL 0xFFFF0000
.eqv RX_DATA 0xFFFF0004

.text
.globl main

main:
    li   t0, RX_CTRL       # Receiver control address
    li   t1, RX_DATA       # Receiver data address

wait_key:
    lw   t2, 0(t0)         # Read receiver control
    andi t2, t2, 1         # Check ready bit

    beqz t2, wait_key      # No key? Keep waiting

    lw   t3, 0(t1)         # Read the received character

    li   t4, 119           # ASCII for lowercase 'w'
    beq  t3, t4, key_w

    j    wait_key          # Ignore other keys

key_w:
    li   a0, 1              # Mark that W was detected
    li   a7, 10             # Exit program
    ecall
