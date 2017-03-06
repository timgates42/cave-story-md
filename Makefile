GENDEV?=/opt/toolchains/gen
GENGCC_BIN=$(GENDEV)/m68k-elf/bin/m68k-elf-
GENBIN=$(GENDEV)/bin

CC = $(GENGCC_BIN)gcc
AS = $(GENGCC_BIN)as
LD = $(GENGCC_BIN)ld
NM = $(GENGCC_BIN)nm
OBJC = $(GENGCC_BIN)objcopy
RESCOMP= sgdk/bin/rescomp

INCS = -Isgdk/inc -Isgdk/res -Isrc -Ires -Iinc
CCFLAGS = $(OPTION) -m68000 -Wall -Wextra -Wno-char-subscripts -Wno-missing-field-initializers \
			-std=c99 -c -fno-builtin
ASFLAGS = -m68000 --register-prefix-optional
TOOLFLAGS = -std=c99 -O2 -Wall -Wextra
LIBS = -Lsgdk -L$(GENDEV)/m68k-elf/m68k-elf/lib -lmd -lnosys 
LINKFLAGS = -T $(GENDEV)/ldscripts/sgdk.ld -nostdlib
ARCHIVES = $(GENDEV)/m68k-elf/lib/gcc/m68k-elf/*/libgcc.a 

BOOTSS=$(wildcard src/boot/*.s)
BOOT_RESOURCES=$(BOOTSS:.s=.o)

RESS=$(wildcard res/*.res)
CS=$(wildcard src/*.c)
CS+=$(wildcard src/ai/*.c)
CS+=$(wildcard src/db/*.c)
SS=$(wildcard src/*.s)
RESOURCES=$(RESS:.res=.o)
RESOURCES+=$(CS:.c=.o)
RESOURCES+=$(SS:.s=.o)

OBJS = $(RESOURCES)

.PHONY: all release debug ntsc pal ntsc-debug pal-debug tools clean clean-tools
.SECONDARY: doukutsu.elf

all: ntsc
tarsaves: prof2sram
tarsaves:
	python2 savegen.py
	tar czvf saves.tar.gz save
saves: prof2sram
saves:
	python2 savegen.py
	zip -r saves.zip save
ntsc: release

ntsc-debug: debug

pal: CCFLAGS += -DPAL
pal: release

pal-debug: CCFLAGS += -DPAL
pal-debug: debug

release: sgdk/libmd.a
release: CCFLAGS += -O3
release: LIBMD = sgdk/libmd.a
release: main-build
debug: sgdk/libmd_debug.a
debug: CCFLAGS += -g -O1 -DDEBUG -DKDEBUG
debug: LIBMD = sgdk/libmd_debug.a
debug: main-build
main-build: head-gen doukutsu.bin symbol.txt

symbol.txt: doukutsu.bin
	$(NM) -n doukutsu.elf > symbol.txt

src/boot/sega.o: src/boot/rom_head.bin
	$(AS) $(ASFLAGS) src/boot/sega.s -o $@

%.bin: %.elf
	$(OBJC) -O binary $< temp.bin
	dd if=temp.bin of=$@ bs=8K conv=sync

%.elf: $(OBJS) $(BOOT_RESOURCES)
	$(CC) -o $@ $(LINKFLAGS) $(BOOT_RESOURCES) $(LIBMD) $(ARCHIVES) $(OBJS) $(LIBS)

%.o: %.c
	@echo "CC $<"
	@$(CC) $(CCFLAGS) $(INCS) -c $< -o $@

%.o: %.s 
	@echo "AS $<"
	@$(AS) $(ASFLAGS) $< -o $@

%.s: %.res
	$(RESCOMP) $< $@

src/boot/rom_head.bin: src/boot/rom_head.o
	$(LD) $(LINKFLAGS) --oformat binary -o $@ $<

head-gen:
	rm -f inc/ai_gen.h
	python aigen.py
	
tools: prof2sram

tscomp:
	gcc tools/tscomp/tscomp.c -o tscomp $(TOOLFLAGS)

tileopt:
	gcc tools/tileopt/tileopt.c -lSDL2 -lSDL2_image -o tileopt $(TOOLFLAGS)

lutgen:
	gcc tools/lutgen/lutgen.c -lm -o lutgen $(TOOLFLAGS)

prof2sram:
	gcc tools/prof2sram/prof2sram.c -o prof2sram $(TOOLFLAGS)

savetrim:
	gcc tools/savetrim/savetrim.c -o savetrim $(TOOLFLAGS)

sgdk/libmd.a:
	cd sgdk && make clean && make

sgdk/libmd_debug.a:
	cd sgdk && make clean && make debug

clean: clean-sgdk
	rm -f $(RESOURCES)
	rm -f doukutsu.bin doukutsu.elf temp.bin symbol.txt
	rm -f src/boot/sega.o src/boot/rom_head.o src/boot/rom_head.bin
	rm -f res/resources.h res/resources.s
	rm -f inc/ai_gen.h
	#rm -rf save
	rm -f saves.zip saves.tar.gz

clean-sgdk:
	cd sgdk && make clean

clean-tools:
	rm -f prof2sram tileopt tscomp lutgen savetrim
