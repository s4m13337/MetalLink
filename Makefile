WSLINKDIR = /Applications/Wolfram\ Engine.app/Contents/Resources/Wolfram\ Player.app/Contents/SystemFiles/Links/WSTP/DeveloperKit
SYS = MacOSX-ARM64
CADDSDIR = ${WSLINKDIR}/${SYS}/CompilerAdditions

INCDIR = ${CADDSDIR}
INCDIR_LOC = ./headers
LIBDIR = ${CADDSDIR}
SRCDIR = ./src

WSPREP = ${CADDSDIR}/wsprep
WSTP_LIB = -lWSTPi4
EXTRA_LIBS = -lc++ -framework Foundation -framework Metal -framework CoreGraphics

CFLAGS = -I${INCDIR} -I${INCDIR_LOC}
LIBS = -L${LIBDIR} ${WSTP_LIB} ${EXTRA_LIBS}

SRCS := $(wildcard $(SRCDIR)/*.m) $(wildcard $(SRCDIR)/*.c)
OBJS := $(SRCS:.m=.o) $(SRCS:.c=.o)

metal : $(SRCDIR)/metaltm.o $(SRCDIR)/metal.o $(SRCDIR)/metal_device.o $(SRCDIR)/utilities.o
	${CC} $(CFLAGS) $^ $(LIBS) -o $@

$(SRCDIR)/%.m.o:
	${CC} -c -I${INCDIR} -I${INCDIR_LOC} $<

$(SRCDIR)/%.c.o :
	${CC} -c -I${INCDIR} -I${INCDIR_LOC} $<

$(SRCDIR)/metaltm.c : $(SRCDIR)/metal.tm
	${WSPREP} $? -o $@

clean:
	rm -f metal ./src/*.o ./src/metaltm.c