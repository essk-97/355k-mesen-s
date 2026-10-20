# Mesen-S para o EmulatorJS 4.2.3 (355k)

Núcleo de Super Nintendo [Mesen-S](https://github.com/libretro/Mesen-S) (GPL-3.0) compilado para o [EmulatorJS](https://github.com/EmulatorJS/EmulatorJS) 4.2.3, usado no 355k no lugar do snes9x (cuja licença proíbe uso comercial).

Licença: GPL-3.0, a mesma do Mesen-S (ver `LICENSE`).

## Como foi compilado

`build.sh` faz tudo dentro da imagem oficial do Emscripten:

```bash
docker run --rm -v "$PWD/build.sh:/build.sh:ro" -v "$PWD/out:/out" emscripten/emsdk:3.1.74 bash /build.sh
```

- **Mesen-S:** `libretro/Mesen-S`, commit `9e4fdeb9b336470bc96beb8765b2e79c86a2da1e`. O script clona a ponta do repositório; para repetir exatamente, faça checkout desse commit.
- **RetroArch adaptado do EmulatorJS:** `EmulatorJS/RetroArch`, commit `31ccb892522a7b0e914dc71731f0834c6495a218` (o da época do EmulatorJS 4.2.3).
- **Emscripten:** 3.1.74.

Nenhum arquivo-fonte do Mesen-S ou do RetroArch foi modificado. Ajustes feitos só na linha de comando do build:

1. `SHARED=-shared`: o Makefile passa `--no-undefined`, que o linker do Emscripten não aceita.
2. `ALTTARGET=copia-descartada.bc`: o Makefile copia o núcleo com um nome alternativo, que com `TARGET_NAME=mesen_s` cairia no mesmo arquivo.
3. O `.bc` do núcleo é refeito sem `SevenZip/*.o`: o RetroArch já traz o SDK do 7-Zip, e as duas cópias davam símbolos duplicados. A do Mesen-S só serve para abrir ROM dentro de `.7z`, o que não acontece no EmulatorJS (ele entrega a ROM já aberta).

Depois do build, cada `.data` recebe `core.json`, `build.json` (`minimumEJSVersion` 4.2.3) e a licença, como faz o build oficial do EmulatorJS.

## Arquivos em `dist/`

- `mesen_s-wasm.data` (WebGL2) e `mesen_s-legacy-wasm.data` (WebGL1): vão em `emulatorjs/cores/`.
- `mesen_s.json`: vai em `emulatorjs/cores/reports/`.

## Testado (19/10/2026)

ROM de teste mínima, no EmulatorJS 4.2.3, Chrome sem janela: imagem ok, save do cartucho (SRAM) ok, estados salvos ok, estado de outro núcleo (snes9x) recusado sem derrubar o emulador. Velocidade máxima ~115 quadros/s nesse ambiente (snes9x: 500–1.700); o jogo precisa de 60.
