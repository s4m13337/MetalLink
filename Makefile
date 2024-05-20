INCDIR = /Applications/Wolfram\ Engine.app/Contents/Resources/Wolfram\ Player.app/Contents/SystemFiles/IncludeFiles/C
INCDIR_LOC = ./headers
SRCDIR = ./src
EXTRA_LIBS = -lc++ -framework Foundation -framework Metal -framework CoreGraphics

CFLAGS = -I${INCDIR} -I${INCDIR_LOC} -fPIC
LDFLAGS = -shared -dynamiclib

libmetal.dylib : $(SRCDIR)/metal.o \
	$(SRCDIR)/metal_device.o \
	$(SRCDIR)/utilities.o 
	${CC} $(LDFLAGS) $(CFLAGS) $^ -o libmetal.dylib $(EXTRA_LIBS)

$(SRCDIR)/%.m.o:
	${CC} -c $(CFLAGS) $<

$(SRCDIR)/%.c.o :
	${CC} -c $(CFLAGS) $<

clean:
	rm -f metal ./src/*.o ./src/metaltm.c