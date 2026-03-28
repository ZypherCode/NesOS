NAME='boot'
INCLUDE="$(pwd)/include"

ASM="$NAME.asm"
OBJ="$NAME.o"
RES="$NAME.nes"

ca65 -I $INCLUDE $ASM
ld65 $OBJ -C "nes.cfg" -o $RES
rm $OBJ

nestopia $RES