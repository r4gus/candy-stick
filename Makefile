include libs/tinyusb/tools/top.mk
include libs/tinyusb/examples/make.mk

INC += \
	src \
	$(TOP)/hw \

# This didn't work on mac
#PROJECT_SOURCE += $(wildcard src/*.c)
#SRC_C += $(addprefix $(CURRENT_PATH)/, $(PROJECT_SOURCE))

SRC_C += src/usb_descriptors.c

ZIG_OBJ += main.o

include libs/tinyusb/examples/rules.mk
