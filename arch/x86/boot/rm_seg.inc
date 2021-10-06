/*
	Real mode segment constants.

	NOTE: Header file only for assembler
*/

# Addresses of RAM:
.set BOOTSEG, 0x07c0			# Address of boot sector
.set SDATASEG, 0x9000			# System data 
.set SETUPLEN, 2				# Number of setup sectors
.set SETUPSEG, 0x9020			# Setup address
.set KERNSEG, 0x0100			# Historical load address
.set KERNSIZE, 0x1000			# Kernel size, interpret as a segment
.set KERNADDR, KERNSEG * 0x10
