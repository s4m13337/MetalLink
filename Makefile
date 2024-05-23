INCDIR = /Applications/Wolfram\ Engine.app/Contents/Resources/Wolfram\ Player.app/Contents/SystemFiles/IncludeFiles/C
INCDIR_LOC = ./headers
SRCDIR = ./src
BUILD_DIR = ./build
EXTRA_LIBS = -lc++ -framework Foundation -framework Metal -framework CoreGraphics

CFLAGS = -I${INCDIR} -I${INCDIR_LOC} -fPIC -fobjc-arc
LDFLAGS = -shared -dynamiclib

$(shell mkdir -p $(BUILD_DIR))

libmetal : $(BUILD_DIR)/metal.o \
	$(BUILD_DIR)/metal_device.o \
	$(BUILD_DIR)/utilities.o \
	$(BUILD_DIR)/add_arrays.o \
	$(BUILD_DIR)/metal_map.o
	${CC} $(LDFLAGS) $(CFLAGS) $^ -o libmetal.dylib $(EXTRA_LIBS)

$(BUILD_DIR)/%.o: $(SRCDIR)/%.m
	${CC} -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/%.o: $(SRCDIR)/%.c
	${CC} -c $(CFLAGS) $< -o $@

library:
	cat ./lib/*.metal > ./lib/library.metal

clean:
	rm -rf libmetal.dylib ./lib/library.metal ./build