#!/bin/bash
# Compila o Mesen-S (libretro) para o EmulatorJS 4.2.3, com o RetroArch adaptado da época (commit 31ccb89, 08/06/2025).
set -ex
apt-get update -qq && apt-get install -y -qq p7zip-full >/dev/null
cd /root
git init -q RetroArch && cd RetroArch
git remote add origin https://github.com/EmulatorJS/RetroArch.git
git fetch -q --depth 1 origin 31ccb892522a7b0e914dc71731f0834c6495a218
git checkout -q FETCH_HEAD
cd /root
git clone -q --depth 1 https://github.com/libretro/Mesen-S.git
cd Mesen-S && git log -1 --format='Mesen-S %H %cd' && cd Libretro
# SHARED sem --no-undefined (o wasm-ld do Emscripten não aceita); o resto do Makefile fica igual.
emmake make -j$(nproc) platform=emscripten TARGET_NAME=mesen_s SHARED=-shared ALTTARGET=copia-descartada.bc
# O RetroArch já traz o SDK do 7-Zip, e o Mesen-S traz outra cópia (símbolos duplicados no link final).
# A do Mesen-S só serve para abrir ROM dentro de .7z, o que nunca acontece aqui (o EmulatorJS entrega a ROM aberta):
# refaz o .bc sem ../SevenZip/*.o.
rm -f mesen_s_libretro_emscripten.bc
em++ -fPIC -shared -o mesen_s_libretro_emscripten.bc $(find .. -name '*.o' -not -path '../SevenZip/*') -lm
ls -la *.bc
mkdir -p /root/EmulatorJS/data/cores
cd /root/RetroArch/emulatorjs
cp /root/Mesen-S/Libretro/mesen_s_libretro_emscripten.bc .
emmake ./build-emulatorjs.sh --clean
cp /root/Mesen-S/Libretro/mesen_s_libretro_emscripten.bc .
emmake ./build-emulatorjs.sh --clean --legacy
cp /root/EmulatorJS/data/cores/*.data /out/
cp /root/Mesen-S/LICENSE /out/license.txt
ls -la /out
