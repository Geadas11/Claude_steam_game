# Ainda Estás Acordado?
*(codename: PROJECT UNKNOWN)*

Thriller de terror psicológico para PC/Steam jogado inteiramente através de um
smartphone fictício. Mistério, investigação, escolhas com consequências e
cinco finais. Em português europeu.

> "Ainda estás acordado?" — uma mensagem de um número desconhecido, às 23:47.
> O número pertencia a uma pessoa que morreu há um ano.

## Correr o jogo

Requer **Godot 4.3** (renderizador *GL Compatibility*).

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
xvfb-run -a godot --rendering-driver opengl3 -- --chapter=ch05 --autoplay=300
```

Capturas de ecrã para revisão visual (precisa de X/Xvfb). `--do=` aceita passos
separados por vírgulas, entre outros: `wait:s`, `unlock`, `open:app[:param]`,
`time:HH:MM`, `choose:thread:i`, `showphoto:id`, `clueloud:id`, `call:who`,
`pause`, `recap`, `extras`, `ending:A`, `press`, `continue:auto`, `dump`
(ver `_debug_script` em `scripts/main.gd`):

```bash
xvfb-run -a godot --rendering-driver opengl3 -- --newgame \
  --do=wait:1,unlock,open:messages:sofia --shot=/tmp/msgs.png:10
```

## Estrutura

```
scripts/core/     GameState, Director (motor narrativo), StoryParser, Clock,
                  Saves, Audio + SoundSynth (som procedural), Achievements, Settings
scripts/phone/    Phone (ecrã, bloqueio, notificações, chamadas, efeitos) e apps/
scripts/ui/       UI kit, Glyph (ícones vetoriais), PhotoView + PhotoPresets
                  (fotografias procedurais), shader de interferência
scripts/menu/     sala, menu inicial, pausa, definições, gravações, extras, finais
data/             toda a narrativa: chapters/*.story, characters, photos, pages,
                  emails, files, notes, voicemails, map, clues, endings, achievements
docs/             STORY_BIBLE.md (spoilers!), STORY_FORMAT.md
tests/            run_tests + walkthrough.json
tools/            check.sh, gen_photos.py, gen_clues.py
```

Não há assets binários: sons e fotografias são gerados em tempo real a partir de
dados, o que permite ao jogo alterar subtilmente uma fotografia entre duas
visualizações.

## Steam

`scripts/core/achievements.gd` usa o singleton `Steam` do
[GodotSteam](https://godotsteam.com) quando presente (36 conquistas, ids iguais
aos de `data/achievements.json`). Sem Steam, tudo funciona localmente.
As gravações ficam em `user://saves/` (pasta `AindaEstasAcordado`) — configurar
o Steam Auto-Cloud para esse caminho. Ver `DEVELOPMENT_STATUS.md`.
