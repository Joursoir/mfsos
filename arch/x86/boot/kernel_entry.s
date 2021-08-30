# bootsect.s loads the kernel and transfers control to SYSSEG address.
# We cannot be sure that the main() function will be exactly at this
# address.

# Therefore, we will use a small trick for entering the kernel correctly:
# Locate this small assembly routine at the beginning of the SYSSEG
# address => we can be sure that control will transfer to main()

.code32
.extern kernel_main
	call kernel_main
	jmp .
