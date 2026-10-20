# 355k-mesen-s

Núcleo de Super Nintendo [Mesen-S](https://github.com/libretro/Mesen-S) compilado para o [EmulatorJS](https://github.com/EmulatorJS/EmulatorJS) 4.2.3, usado no [355k](https://355k.essk.space) no lugar do snes9x (cuja licença proíbe uso comercial).

Licença: **GPL-3.0**, a mesma do Mesen-S (ver `LICENSE`).

## Os arquivos

Em `dist/`, prontos para o EmulatorJS:

- `mesen_s-wasm.data` (WebGL2) e `mesen_s-legacy-wasm.data` (WebGL1): vão em `emulatorjs/cores/`;
- `mesen_s.json`: vai em `emulatorjs/cores/reports/`.

No 355k, eles se juntam ao [355k-emulatorjs](https://github.com/essk-97/355k-emulatorjs) e à [355k-ponte](https://github.com/essk-97/355k-ponte).

## Como foi compilado

`build.sh` faz tudo dentro da imagem oficial do Emscripten, da busca do código ao pacote final (uns 40 minutos):

```bash
docker run --rm -v "$PWD/build.sh:/build.sh:ro" -v "$PWD/out:/out" emscripten/emsdk:3.1.74 bash /build.sh
```

- **Mesen-S:** `libretro/Mesen-S`, commit [`9e4fdeb`](https://github.com/libretro/Mesen-S/tree/9e4fdeb9b336470bc96beb8765b2e79c86a2da1e).
- **RetroArch adaptado do EmulatorJS:** `EmulatorJS/RetroArch`, commit [`31ccb89`](https://github.com/EmulatorJS/RetroArch/tree/31ccb892522a7b0e914dc71731f0834c6495a218) (o da época do EmulatorJS 4.2.3).
- **Emscripten:** 3.1.74.

Nenhum arquivo-fonte do Mesen-S ou do RetroArch foi modificado. Ajustes feitos só na linha de comando do build:

1. `SHARED=-shared`: o Makefile passa `--no-undefined`, que o linker do Emscripten não aceita.
2. `ALTTARGET=copia-descartada.bc`: o Makefile copia o núcleo com um nome alternativo, que com `TARGET_NAME=mesen_s` cairia no mesmo arquivo.
3. O `.bc` do núcleo é refeito sem `SevenZip/*.o`, com os arquivos em ordem alfabética: o RetroArch já traz o SDK do 7-Zip, e as duas cópias davam símbolos duplicados. A do Mesen-S só serve para abrir ROM dentro de `.7z`, o que não acontece no EmulatorJS (ele entrega a ROM já aberta). A ordem fixa faz o mesmo build sair igual.

Depois do build, cada `.data` recebe `core.json`, `build.json` (`minimumEJSVersion` 4.2.3, versão `355k-1`) e a licença, como faz o build oficial do EmulatorJS.

## Testado

ROM de teste mínima, no EmulatorJS 4.2.3, Chrome sem janela: imagem, save do cartucho (SRAM) e estados salvos funcionam; estado de outro núcleo (snes9x) é recusado sem derrubar o emulador. Velocidade máxima ~115 quadros/s nesse ambiente, com o vídeo desenhado por software (snes9x: 500–1.700); o jogo precisa de 60. O teste da [355k-ponte](https://github.com/essk-97/355k-ponte) usa este núcleo.
