#!/bin/sh

echo "- Getting latest Stockfish ..."

if [ -d Stockfish/src ]; then
    cd Stockfish/src
    make clean > /dev/null
    git pull
else
    git clone --depth 1 https://github.com/niklasf/Stockfish.git --branch fishnet
    cd Stockfish/src
fi

echo "- Determining CPU architecture ..."

ARCH="$(uname -m)"
EXE=stockfish-"$ARCH"
case "$ARCH" in
    aarch64|arm)
        ARCH=armv7
        EXE=stockfish-"$ARCH"
        ;;
    x86_64)
        ARCH=x86-64
        ;;
    i*86)
        # Assuming that everyone trying to run fishnet has SSE
        ARCH=x86-32
        ;;
    ppc|ppcle)
        ARCH=ppc-32
        ;;
    ppc64|ppc64le)
        ARCH=ppc-64
        ;;
    *)
        # If arch unknown, fall back to general config
        if [ "$(getconf LONG_BIT)" = "64" ]; then
            ARCH=general-64
        else
            ARCH=general-32
        fi
        ;;
esac

if [ "$ARCH" = "x86-64" ]; then
    if [ -f /proc/cpuinfo ]; then
        if grep "^flags" /proc/cpuinfo | grep -q popcnt ; then
            ARCH=x86-64-modern
            EXE=stockfish-x86_64-modern
        fi

        if grep "^vendor_id" /proc/cpuinfo | grep -q Intel ; then
            if grep "^flags" /proc/cpuinfo | grep bmi2 | grep -q popcnt ; then
                ARCH=x86-64-bmi2
                EXE=stockfish-x86_64-bmi2
            fi
       fi
    fi
fi

echo "- Building and profiling $EXE ... (patience advised)"
make profile-build ARCH=$ARCH EXE=../../$EXE > /dev/null

cd ../..
echo "- Done!"
