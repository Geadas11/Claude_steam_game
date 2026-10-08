# Formato `.story` — guia de escrita

Os capítulos vivem em `data/chapters/chXX.story`. Cada ficheiro é uma lista de
**beats**: pequenos programas que o `Director` executa quando a sua condição
`@when` fica verdadeira. Os beats compilam para instruções lineares, por isso um
jogo gravado a meio de um beat retoma exatamente na mesma instrução.

```text
@chapter ch02
@title O Contacto
@start 2026-10-09 08:05          # hora do relógio do jogo no início do capítulo

@beat nome_do_beat
@when at("10:35") and read("unknown")
@repeat                           # opcional: pode correr mais do que uma vez
... instruções ...
@end

@call joao nome_do_handler       # o jogador liga ao João
@when flag("x")
joao: Fala o João. | 2.0         # linha de diálogo (| duração opcional)
- (barulho de bar ao fundo)      # narração / legenda
[sfx breath]                     # som
@end
```

## Mensagens

| Sintaxe | Significado |
|---|---|
| `sofia> Olá` | Sofia escreve na conversa "sofia" (com indicador "a escrever…") |
| `grupo:joao> ok` | João escreve no grupo |
| `me@rui> Desculpa.` | o Daniel "envia" (sem o jogador escolher — usar com intenção) |
| `#id` | id da mensagem, para `edit`/`delete`/`retime` mais tarde |
| `[photo:IMG_6612]` `[audio:vm_x]` `[link:pagina]` `[file:id]` | anexos |
| `{instant}` | sem indicador de escrita |
| `{typing=4}` | indicador durante 4 s |
| `{time=03:02}` | data retroativa (hoje/ontem a essa hora) |
| `{date=2025-10-13 22:30}` | data absoluta |
| `{silent}` | sem notificação nem contador de não lidas |
| `{deleted}` | aparece como "Esta mensagem foi apagada" |

## Escolhas

```text
choice sofia c1_visit
  > Não precisas | set sofia_visit=false
  > {if flag("x")} Opção condicional | set a=1 b="texto"
  > [Não responder] | set ignored=true      # entre [] não é enviada
end
```

A escolha fica gravada em `choice_<id>` (índice) e no registo de escolhas.

## Controlo

`wait 2.5`, `set a=true b=3`, `inc trust_joao 1`, `if <expr>` / `elif` / `else` / `endif`.

## Chamadas recebidas

```text
call ines id=c3_ines ring=22 [unknown] [forced] [outgoing] [autoanswer]
  [sfx sea]
  ines: Daniel? | 1.8
  wait 2
end
```
Resultado em `answered("c3_ines")` / `missed("c3_ines")`.

## Comandos

`notify app "título" "texto"` · `sound x` · `ambient x|off` · `music x|off` · `stopsounds` ·
`vibrate` · `glitch intensidade duração` · `time 03:00|+15|!03:17` · `rate 2` ·
`photo ID [silent] [álbum]` · `variant FOTO variante` · `edit th id "texto"` · `delete th id` ·
`unsend th id` · `retime th id 03:17` · `contact id` · `rename id "Nome"` · `contactset id campo valor` ·
`email id [silent]` · `file id [silent]` · `note id` · `voicemail id` · `history "texto" HH:MM` ·
`unlock página` · `clue id [silent]` · `calllog quem in|out|missed HH:MM [dur]` · `open app` · `home` ·
`lock` · `screenoff s` · `restart` (pede PIN) · `reflection` · `battery n` · `location id` ·
`camera evento` · `achieve id` · `autotype th "texto"` · `typing th quem s` · `toast "texto"` ·
`hiddenapp eco on|off` · `setting chave valor` · `read th` · `alarm HH:MM "rótulo"` ·
`hidethread th` · `showthread th` · `mapmark local` · `checkpoint` · `deduction` · `endchapter` · `ending X`.

## Condições (expressões Godot)

`flag("x")`, `v("x") >= 2`, `vs("x") == "a"`, `beat("id")`, `started("id")`, `running("id")`,
`since("id", segundos)`, `at("03:17")`, `read("th")`, `unread("th")`, `has_msg("th","id")`,
`clue("id")`, `clues()`, `viewed("IMG")`, `photo_is("IMG","var")`, `visited("página")`,
`searched("termo")`, `opened("app")`, `ever_opened("app")`, `app() == "messages:rui"`,
`email_read("id")`, `file_open("id")`, `called("quem")`, `loc("id")`, `tag("pista")`,
`ded("pergunta")`, `answered("call")`, `missed("call")`, `has_photo/has_file/has_email("id")`,
`phone("chave")`, `hour()`, `ending_seen("A")`.

## Regras de escrita

- Nada de placeholders. Cada mensagem tem de soar a uma pessoa concreta.
- Cada personagem escreve de forma diferente (ver `STORY_BIBLE.md`).
- Contradições só se forem intencionais — e listadas na bíblia.
- Toda a escolha deve ter consequência (resposta imediata, flag usada mais tarde, ou ambos).
- Todo o beat que espera por uma ação do jogador precisa de um "empurrão" temporal para evitar bloqueios.
- `tests/walkthrough.json` descreve um caminho para cada final; os testes falham se algum deixar de ser alcançável.
