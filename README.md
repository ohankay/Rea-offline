# rea-offline

[REA](https://github.com/morluto/rea) (*Reverse engineer anything*) icin
**internetsiz (air-gapped) bilgisayarlara** dogrudan **indir → kur → calistir**
paketleri.

Her paket kendi Node.js calisma ortamini, `rea-agents` paketini ve tum
bagimliliklarini (frida, node-pty gibi derlenmis yerel moduller dahil) icerir.
Hedef bilgisayarda Node.js, npm veya internet gerekmez.

## Indirme

[Releases](../../releases) sayfasindan platformunuza uygun dosyayi indirip USB
vb. ile hedef bilgisayara tasiyin:

| Platform | Hafif paket | Ghidra + JDK dahil tam paket |
| --- | --- | --- |
| Linux x64 | `rea-offline-<surum>-linux-x64.tar.gz` | `...-linux-x64-ghidra.tar.gz` |
| Linux ARM64 | `rea-offline-<surum>-linux-arm64.tar.gz` | `...-linux-arm64-ghidra.tar.gz` |
| Windows x64 | `rea-offline-<surum>-win-x64.zip` | `...-win-x64-ghidra.zip` |
| macOS Apple Silicon | `rea-offline-<surum>-darwin-arm64.tar.gz` | `...-darwin-arm64-ghidra.tar.gz` |

Hafif paket: CLI, MCP sunucusu ve JavaScript/Electron, web, WASM, Android vb.
analizler. Yerel ikili (ELF/PE/Mach-O) analizi icin bir arka uc gerekir; **tam
paket** Ghidra 12.1.x ve uyumlu bir JDK 21 ile gelir, ek kurulum gerekmez.

Her arsivin yaninda `.sha256` dosyasi vardir:
`sha256sum -c rea-offline-*.sha256`

## Kurulum

**Linux / macOS**

```sh
tar -xzf rea-offline-6.7.0-linux-x64.tar.gz
cd rea-offline-6.7.0-linux-x64
./install.sh          # ~/.local/share/rea-offline + ~/.local/bin/rea
rea --help
```

Sistem geneli: `sudo PREFIX=/opt/rea-offline BIN_DIR=/usr/local/bin ./install.sh`.
Kurmadan calistirmak: `./bin/rea --help`.

**Windows**

Zip'i acin ve `install.cmd`'ye cift tiklayin (yonetici yetkisi gerekmez;
`%LOCALAPPDATA%\rea-offline` altina kurar ve kullanici PATH'ine ekler).
Yeni bir terminalde `rea --help`.

**MCP istemcisine baglama** (ornek Claude Code): `claude mcp add rea -- rea mcp`

## Paketleri kendiniz uretmek

Internetli bir makinede, hedef platformla ayni isletim sistemi/islemci uzerinde:

```sh
scripts/build.sh --rea-version 6.7.0            # hafif paket
scripts/build.sh --rea-version 6.7.0 --with-ghidra
```

Cikti `dist/` altina yazilir. GitHub Actions is akisi
([.github/workflows/build.yml](.github/workflows/build.yml)) `v*` etiketi
itildiginde (or. `v6.7.0`) veya elle tetiklendiginde tum platformlar icin
paketleri uretip internet erisimi kapali bir ortamda test eder ve bir Release
olarak yayinlar.

## Lisans

REA MIT lisanslidir (`LICENSE.rea`); paketlerdeki ucuncu taraf bilesenlerin
lisanslari `app/node_modules/rea-agents/THIRD_PARTY_NOTICES.md`, Ghidra
(Apache-2.0) ve Eclipse Temurin JDK (GPLv2 + Classpath Exception) kendi
klasorlerinde yer alir. Bu depo yalnizca paketleme betiklerini icerir.
