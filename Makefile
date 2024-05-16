WSLINKDIR = /Applications/Wolfram\ Engine.app/Contents/Resources/Wolfram\ Player.app/Contents/SystemFiles/Links/WSTP/DeveloperKit
SYS = MacOSX-ARM64
CADDSDIR = ${WSLINKDIR}/${SYS}/CompilerAdditions

INCDIR = ${CADDSDIR}
LIBDIR = ${CADDSDIR}

WSPREP = ${CADDSDIR}/wsprep
WSTP_LIB = -lWSTPi4
EXTRA_LIBS = -lc++ -framework Foundation -framework Metal -framework CoreGraphics

addtwo : addtwotm.o addtwo.o
	${CC} -I${INCDIR} addtwotm.o addtwo.o -L${LIBDIR} ${WSTP_LIB} ${EXTRA_LIBS} -o $@

metal : metaltm.o metal.o
	${CC} -I${INCDIR} metaltm.o metal.o -L${LIBDIR} ${WSTP_LIB} ${EXTRA_LIBS} -o $@

.m.o :
	${CC} -c -I${INCDIR} $<

.c.o :
	${CC} -c -I${INCDIR} $<

addtwotm.c : addtwo.tm
	${WSPREP} $? -o $@

metaltm.c : metal.tm
	${WSPREP} $? -o $@

clean:
	rm addtwotm.c addtwotm.o addtwo.o addtwo metaltm.c metaltm.o metal.o metal 