#!/bin/bash

die() {
    echo -e $1; exit 1
}

[[ -e $HOME/.minecraft ]] || die "You don't even *have* Minecraft."
cd $LWJGLDIR || die "Please set LWJGLDIR to the location of lwjgl on your system."
[[ -e jar/jinput.jar ]] || die "Please set LWJGLDIR to the location of lwjgl on your system."

cp jar/jinput.jar ~/.minecraft/bin/jinput.jar
cp jar/lwjgl.jar ~/.minecraft/bin/lwjgl.jar
cp jar/lwjgl_util.jar ~/.minecraft/bin/lwjgl_util.jar
cp native/linux/libjinput-linux.so ~/.minecraft/bin/natives/libjinput-linux.so
cp native/linux/libjinput-linux64.so ~/.minecraft/bin/natives/libjinput-linux64.so
cp native/linux/liblwjgl.so ~/.minecraft/bin/natives/liblwjgl.so
cp native/linux/liblwjgl64.so ~/.minecraft/bin/natives/liblwjgl64.so
cp native/linux/libopenal.so ~/.minecraft/bin/natives/libopenal.so
cp native/linux/libopenal64.so ~/.minecraft/bin/natives/libopenal64.so
