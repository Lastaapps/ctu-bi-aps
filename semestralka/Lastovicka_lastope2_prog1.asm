	
	lw	s0, 4(x0)
	li	s1, 8

loop:
	beq	s0, x0, end
	lw	a2, 0(s1)
	call	prime
	sw	a0, 0(s1)
	
	addi	s1, s1, 4
	addi	s0, s0, -1
	j	loop


# isPrime
# param a2 - number to check
# return a0 - 1 for prime, 0 for other
prime:
	li	t1, 1
	beq	a2, x0, prime_fail
	beq	a2, t1, prime_fail
	mv	t0, a2
prime_loop:
	addi	t0, t0, -1
	beq	t0, t1, prime_succ
	
	rem	t2, a2, t0
	beq	t2, x0, prime_fail
	j	prime_loop
	
prime_succ:
	li	a0, 1
	ret
prime_fail:
	li	a0, 0
	ret
end: