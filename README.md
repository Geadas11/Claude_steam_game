# Ainda Estás Acordado?
*(codename: PROJECT UNKNOWN)*

Thriller de terror psicológico para PC/Steam. O Daniel anda pela casa dele em
primeira pessoa (3D realista) e a história chega pelo telemóvel: o do jogo, na
mão dele, ou o telemóvel verdadeiro do jogador, ligado por QR. Mistério,
investigação, escolhas com consequências e cinco finais. Em português europeu.

> "Ainda estás acordado?" — uma mensagem de um número desconhecido, às 23:47.
> O número pertencia a uma pessoa que morreu há um ano.

## Correr o jogo

Requer **Godot 4.3** (renderizador *Forward+*; Vulkan ou Direct3D 12).

Controlos na casa: **WASD** andar · **Shift** correr · **C/Ctrl** agachar ·
**F** lanterna · **E** usar/examinar · **Tab** tirar/guardar o telemóvel ·
**Esc** pausa. Tudo pode ser mudado em Definições → Controlos.

```bash
godot --path .                 # jogar
godot --path . -- --newgame    # começar logo um jogo novo
godot --path . -- --chapter=ch05   # saltar para um capítulo (debug)
```

## Testes

```bash
./tools/check.sh                                         # compila todos os scripts
godot --headless res://tests/run_tests.tscn              # validação + gravação + 5 finais
godot --headless res://tests/run_tests.tscn -- --only=validate
godot --headless res://tests/run_tests.tscn -- --only=play --policy=B --verbose
```

Os testes validam todas as referências entre dados (fotografias, páginas,
ficheiros, pistas, finais), verificam as expressões das condições, fazem uma
volta de gravação/carregamento (incluindo ficheiro corrompido → `.bak`) e jogam o
jogo inteiro cinco vezes em modo acelerado, uma por final, a partir de
`tests/walkthrough.json`.

Teste de resistência em tempo real (não acelerado; lê conversas, abre apps,
atende chamadas e escolhe ao acaso durante N segundos):

```bash
godot --headless --path . -- --chapter=ch05 --autoplay=300
```

Capturas de ecrã para revisão visual (precisa de X/Xvfb). `--do=` aceita passos
separados por vírgulas, entre outros: `wait:s`, `unlock`, `open:app[:param]`,
`time:HH:MM`, `choose:thread:i`, `showphoto:id`, `clueloud:id`, `call:who`,
`pause`, `recap`, `extras`, `ending:A`, `press`, `continue:auto`, `dump`;
na casa: `pocket` (Tab), `at:x:z:yaw[:pitch]`, `look:yaw`, `use`, `walk:acção:s`,
`key:Tab`, `torch`, `light:sala:on`, `power:off`, `cue:lights:off`, `where`,
`snap:ficheiro.png`, `quit` (ver `_debug_script` em `scripts/main.gd`):

```bash
xvfb-run -a godot -- --newgame \
  --do=wait:2,pocket,at:2.7:3.6:0:8,wait:1,snap:/tmp/sala.png,quit
```

## Estrutura

```
scripts/core/     GameState, Director (motor narrativo), StoryParser, Clock,
                  Saves, Audio + SoundSynth (som procedural), Achievements, Settings
scripts/phone/    Phone (ecrã, bloqueio, notificações, chamadas, efeitos) e apps/
scripts/ui/       UI kit, Glyph (ícones vetoriais), PhotoView + PhotoPresets
                  (fotografias procedurais), shader de interferência
scripts/menu/     sala, menu inicial, pausa, definições, gravações, extras, finais
scripts/world/    a casa 3D: GameWorld, House (construída em código), Player,
                  Door, Hotspot, WorldHud, WB (materiais e modelos)
assets/3d/        modelos e texturas CC0 do Poly Haven (tools/fetch_polyhaven.py)
data/             toda a narrativa: chapters/*.story, characters, photos, pages,
                  emails, files, notes, voicemails, map, clues, endings, achievements
docs/             STORY_BIBLE.md (spoilers!), STORY_FORMAT.md, STEAM.md, PLAYTEST.md
tests/            run_tests + walkthrough.json
tools/            check.sh, gen_photos.py, gen_clues.py, fetch_polyhaven.py,
                  split_pack.gd (builds de teste em vários ficheiros)
```

Os sons são gerados em tempo real a partir de código. Os modelos e texturas 3D
são CC0 (Poly Haven, lista em `assets/3d/CREDITS.md`); as fotografias do
telemóvel estão em `art/photos/`.

## Steam

`scripts/core/achievements.gd` usa o singleton `Steam` do
[GodotSteam](https://godotsteam.com) quando presente (37 conquistas, ids iguais
aos de `data/achievements.json`). Sem Steam, tudo funciona localmente.
As gravações ficam em `user://saves/` (pasta `AindaEstasAcordado`) — configurar
o Steam Auto-Cloud para esse caminho. Ver `DEVELOPMENT_STATUS.md`.
