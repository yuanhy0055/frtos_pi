TOOLCHAIN ?= arm-none-eabi-

SOURCES = Demo/main.c \
          Demo/startup.c \
          Demo/Drivers/rpi_gpio.c \
          Demo/Drivers/rpi_irq.c \
          Source/tasks.c \
          Source/list.c \
          Source/portable/GCC/RaspberryPi/port.c \
          Source/portable/GCC/RaspberryPi/portISR.c \
          Source/portable/GCC/RaspberryPi/portASM.c \
          Source/portable/MemMang/heap_4.c

OBJECTS = $(patsubst %.c,build/%.o,$(SOURCES))

INCDIRS = Source/include Source/portable/GCC/RaspberryPi \
          Demo/Drivers Demo/

CFLAGS = -Wall $(addprefix -I ,$(INCDIRS))
CFLAGS += -D RPI2
CFLAGS += -march=armv7-a -mtune=cortex-a7 -mfloat-abi=hard -mfpu=neon-vfpv4

ASFLAGS += -march=armv7-a -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard

LDFLAGS = 

.PHONY: all clean

all: $(MOD_NAME)

$(MOD_NAME): $(OBJECTS)
	ld -shared $(LDFLAGS) $< -o $@

build/%.o: %.c
	mkdir -p $(dir $@)
	$(TOOLCHAIN)gcc -c $(CFLAGS) $< -o $@

build/%.o: %.s
	mkdir -p $(dir $@)
	$(TOOLCHAIN)as $(ASFLAGS) $< -o $@

all: kernel.list kernel.img kernel.syms kernel.hex
	$(TOOLCHAIN)size kernel.elf

kernel.img: kernel.elf
	$(TOOLCHAIN)objcopy kernel.elf -O binary $@

kernel.list: kernel.elf
	$(TOOLCHAIN)objdump -D -S  kernel.elf > $@

kernel.syms: kernel.elf
	$(TOOLCHAIN)objdump -t kernel.elf > $@

kernel.hex : kernel.elf
	$(TOOLCHAIN)objcopy kernel.elf -O ihex $@

kernel.elf: $(OBJECTS)
	$(TOOLCHAIN)ld $^ -static -Map kernel.map -o $@ -T Demo/raspberrypi.ld

clean:
	rm -f $(OBJECTS)
	rm -f kernel.list kernel.img kernel.syms
	rm -f kernel.elf kernel.hex kernel.map
	rm -rf build

