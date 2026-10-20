#!/bin/bash
# Compila o Mesen-S (libretro) para o EmulatorJS 4.2.3 e empacota como o build oficial do EmulatorJS.
# Roda dentro da imagem oficial do Emscripten (ver README.md); o resultado sai em /out.
set -ex
MESEN_S=9e4fdeb9b336470bc96beb8765b2e79c86a2da1e    # libretro/Mesen-S
RETROARCH=31ccb892522a7b0e914dc71731f0834c6495a218  # EmulatorJS/RetroArch, o da época do EmulatorJS 4.2.3

apt-get update -qq && apt-get install -y -qq p7zip-full >/dev/null
buscar() { # buscar <repositório> <commit> <pasta>
  git init -q "$3" && git -C "$3" remote add origin "$1" && git -C "$3" fetch -q --depth 1 origin "$2" && git -C "$3" checkout -q FETCH_HEAD
}
cd /root
buscar https://github.com/EmulatorJS/RetroArch.git "$RETROARCH" RetroArch
buscar https://github.com/libretro/Mesen-S.git "$MESEN_S" Mesen-S

cd /root/Mesen-S/Libretro
# SHARED sem --no-undefined (o wasm-ld do Emscripten não aceita); ALTTARGET: o Makefile copia o núcleo com outro
# nome, que com TARGET_NAME=mesen_s cairia no mesmo arquivo. O resto do Makefile fica igual.
emmake make -j$(nproc) platform=emscripten TARGET_NAME=mesen_s SHARED=-shared ALTTARGET=copia-descartada.bc
# O RetroArch já traz o SDK do 7-Zip, e o Mesen-S traz outra cópia (símbolos duplicados no link final).
# A do Mesen-S só serve para abrir ROM dentro de .7z, o que nunca acontece no EmulatorJS (ele entrega a ROM
# aberta): refaz o .bc sem ../SevenZip/*.o.
rm -f mesen_s_libretro_emscripten.bc
# (sort: a ordem dos .o muda o binário; ordenada, o mesmo build sai igual.)
em++ -fPIC -shared -o mesen_s_libretro_emscripten.bc $(find .. -name '*.o' -not -path '../SevenZip/*' | sort) -lm

mkdir -p /root/EmulatorJS/data/cores
cd /root/RetroArch/emulatorjs
cp /root/Mesen-S/Libretro/mesen_s_libretro_emscripten.bc .
emmake ./build-emulatorjs.sh --clean           # WebGL2: mesen_s-wasm.data
cp /root/Mesen-S/Libretro/mesen_s_libretro_emscripten.bc .
emmake ./build-emulatorjs.sh --clean --legacy  # WebGL1: mesen_s-legacy-wasm.data

# Empacota como o build oficial do EmulatorJS: core.json, build.json e a licença dentro de cada .data.
cd /out
cp /root/Mesen-S/LICENSE license.txt
echo '{"name":"mesen_s","extensions":["smc","sfc","swc","fig","bs"],"options":{},"save":"srm","license":"LICENSE","repo":"https://github.com/libretro/Mesen-S"}' > core.json
printf '{\n    "minimumEJSVersion": "4.2.3",\n    "version": "355k-1"\n}\n' > build.json
for f in mesen_s-wasm.data mesen_s-legacy-wasm.data; do
  cp "/root/EmulatorJS/data/cores/$f" .
  7z a -t7z "$f" core.json build.json license.txt
done
echo "{ \"core\": \"mesen_s\", \"buildStart\": \"$(date -u +%Y-%m-%dT%H:%M:%S+00:00)\", \"options\": {} }" > mesen_s.json
rm core.json build.json license.txt
ls -la /out
