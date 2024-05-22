INCDIR = /Applications/Wolfram\ Engine.app/Contents/Resources/Wolfram\ Player.app/Contents/SystemFiles/IncludeFiles/C
INCDIR_LOC = ./headers
SRCDIR = ./src
EXTRA_LIBS = -lc++ -framework Foundation -framework Metal -framework CoreGraphics

CFLAGS = -I${INCDIR} -I${INCDIR_LOC} -fPIC -fobjc-arc
LDFLAGS = -shared -dynamiclib

libmetal : $(SRCDIR)/metal.o \
	$(SRCDIR)/metal_device.o \
	$(SRCDIR)/utilities.o \
	$(SRCDIR)/add_arrays.o
	${CC} $(LDFLAGS) $(CFLAGS) $^ -o libmetal.dylib $(EXTRA_LIBS)

$(SRCDIR)/%.m.o:
	${CC} -c $(CFLAGS) $<

$(SRCDIR)/%.c.o :
	${CC} -c $(CFLAGS) $<

library:
	cat ./lib/*.metal > ./lib/library.metal

clean:
	rm -f libmetal.dylib ./src/*.o ./lib/library.metal