#!/bin/bash

die() {
    echo -e $1; exit 1
}

[[ -e $HOME/.minecraft ]] || die "You don't even *have* Minecraft."
[[ -d $LWJGLDIR ]] || die "Please set LWJGLDIR to the location of lwjgl on your system."
[[ -e $LWJGLDIR/jar/jinput.jar ]] || die "Please set LWJGLDIR to the location of lwjgl on your system."

cp -v $LWJGLDIR/jar/jinput.jar ~/.minecraft/bin/jinput.jar
cp -v $LWJGLDIR/jar/lwjgl.jar ~/.minecraft/bin/lwjgl.jar
cp -v $LWJGLDIR/jar/lwjgl_util.jar ~/.minecraft/bin/lwjgl_util.jar
cp -v $LWJGLDIR/native/linux/libjinput-linux.so ~/.minecraft/bin/natives/libjinput-linux.so
cp -v $LWJGLDIR/native/linux/libjinput-linux64.so ~/.minecraft/bin/natives/libjinput-linux64.so
cp -v $LWJGLDIR/native/linux/liblwjgl.so ~/.minecraft/bin/natives/liblwjgl.so
cp -v $LWJGLDIR/native/linux/liblwjgl64.so ~/.minecraft/bin/natives/liblwjgl64.so
cp -v $LWJGLDIR/native/linux/libopenal.so ~/.minecraft/bin/natives/libopenal.so
cp -v $LWJGLDIR/native/linux/libopenal64.so ~/.minecraft/bin/natives/libopenal64.so
