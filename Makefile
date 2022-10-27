include libs/tinyusb/tools/top.mk
include libs/tinyusb/examples/make.mk

INC += \
	src \
	$(TOP)/hw \

# Example source
PROJECT_SOURCE += $(wildcard src/*.c)
SRC_C += $(addprefix $(CURRENT_PATH)/, $(PROJECT_SOURCE))

ZIG_OBJ += main.o

include libs/tinyusb/examples/rules.mk
