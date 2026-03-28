NAME='asm/boot'
INCLUDE="$(pwd)/include"

ASM="$NAME.asm"
OBJ="$NAME.o"
RES="nesos.nes"

ca65 -I $INCLUDE "asm/main.asm" 
ca65 -I $INCLUDE "asm/screen.asm"
ca65 -I $INCLUDE "asm/tty.asm"
ca65 -I $INCLUDE $ASM
ld65 $OBJ "asm/main.o" "asm/screen.o" "asm/tty.o"  -C "nes.cfg" -o $RES
rm $OBJ
rm "asm/main.o"
rm "asm/screen.o"
rm "asm/tty.o"

nestopia $RES