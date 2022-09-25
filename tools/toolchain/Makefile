TARGET		= i686-elf
TOOLS_PREFIX	= $(PWD)
# The $TOOLS_PREFIX/bin dir MUST be in the PATH. GCC will use it. 
PATH		:= "$(TOOLS_PREFIX)/bin:$(PATH)"
export PATH

BINUTILS_OUT	= src/binutils/out
GCC_OUT		= src/gcc/out

all: binutils gcc
	bin/$(TARGET)-as --version
	bin/$(TARGET)-gcc -###

binutils:
	mkdir $(BINUTILS_OUT)
	(cd $(BINUTILS_OUT); ../configure --target=$(TARGET) --prefix="$(TOOLS_PREFIX)" \
		--with-sysroot \
		--disable-nls \
		--disable-gdb \
		--disable-werror)
	$(MAKE) -C $(BINUTILS_OUT)
	$(MAKE) -C $(BINUTILS_OUT) install

gcc:
	mkdir $(GCC_OUT)
	(cd $(GCC_OUT); ../configure --target=$(TARGET) --prefix="$(TOOLS_PREFIX)" \
		--disable-nls \
		--enable-languages=c \
		--without-headers)
	$(MAKE) -C $(GCC_OUT) all-gcc
	$(MAKE) -C $(GCC_OUT) all-target-libgcc
	$(MAKE) -C $(GCC_OUT) install-gcc
	$(MAKE) -C $(GCC_OUT) install-target-libgcc

clean:
	-rm -r $(BINUTILS_OUT) $(GCC_OUT)
	-rm -r bin $(TARGET) include lib libexec share
