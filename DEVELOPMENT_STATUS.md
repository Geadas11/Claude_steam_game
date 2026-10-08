# DEVELOPMENT_STATUS

> Ler isto no início de cada sessão. Continuar de onde ficou. Nunca recomeçar do zero.

**Projeto:** Ainda Estás Acordado? (PROJECT UNKNOWN) · Godot 4.3 · GL Compatibility · pt-PT
**Última atualização:** sessão 1 (2026-10-08)

---

## Estado geral

| Área | Estado |
|---|---|
| Arquitetura (Core) | ✅ completa e testada |
| Shell do telemóvel | ✅ completa |
| 13 aplicações | ✅ funcionais (ver abaixo) |
| Motor narrativo (DSL `.story`) | ✅ completo, retoma beats a meio após carregar |
| História — 11 capítulos | ✅ escritos de ponta a ponta (1.º rascunho jogável) |
| 5 finais | ✅ todos alcançáveis (testado automaticamente) |
| Investigação / pistas | ✅ 136 pistas, quadro com etiquetas e relações, reconstrução final |
| Terror | 🟡 integrado na narrativa (ver "Momentos de terror"); precisa de afinação com jogo humano |
| Áudio | 🟡 procedural, funcional; precisa de mistura/afinação em jogo real |
| Steam | 🟡 ponte GodotSteam opcional + 30 conquistas; builds Windows/Linux exportadas e testadas; falta App ID real |
| Duração | 🔴 ~3–5 h numa primeira passagem (objetivo 14 h+) — ver "Próximas prioridades" |

## Funcionalidades completas

### Core (`scripts/core`)
- **GameState** — estado central serializável (mensagens, chamadas, fotos, pistas, flags, etc.)
- **StoryParser** — DSL `.story` → beats compilados em programas lineares (if/else → saltos)
- **Director** — corre beats em paralelo, condições via `Expression`, escolhas, chamadas recebidas
  e efetuadas, ~50 comandos narrativos, retoma pelo *program counter* após carregar
- **Clock** — relógio interno; acelera ×6 quando o jogador está parado e a história só espera pelo relógio
- **Saves** — 5 espaços + automático + rápido (F5/F9); escrita atómica (tmp + rename) e `.bak`
- **Audio + SoundSynth** — ~45 sons sintetizados em runtime (sem ficheiros binários), barramentos separados
- **Achievements** — 30 conquistas, perfil local + espelho Steam se o singleton existir
- **Settings** — volumes por barramento, tamanho de texto, velocidade das mensagens, legendas,
  legendas de sons, alto contraste, reduzir efeitos, reduzir movimento, ecrã inteiro, vsync, resolução

### Telemóvel (`scripts/phone`)
- Ecrã de bloqueio (notificações agrupadas, PIN após reinício com dica), ecrã principal, dock,
  barra de estado (hora, rede, wi-fi, bateria), barra de navegação, banners, toast,
  ecrã de chamada (recebida/efetuada, legendas ao vivo), interferência (shader), ecrã apagado,
  reflexo no vidro, reinício com logótipo, vibração
- Apps: **Mensagens** (lista, conversas, grupos, anexos, apagadas, escrita automática das respostas,
  "a escrever…"), **Telefone** (recentes, contactos, teclado com números especiais, correio de voz),
  **Contactos**, **Galeria** (álbuns, zoom/arrastar, metadata, pormenores escondidos clicáveis,
  fundo de ecrã), **Câmara** (visor vivo da sala, eventos armados pela história, fotografias guardadas),
  **Navegador** (internet fictícia com pesquisa real por palavras-chave, histórico com entradas
  injetadas, páginas com palavra-passe, páginas que mudam com a história), **Mapas** (mapa desenhado,
  pesquisa, distâncias, cronologia de localização), **Email** (entrada, enviados, lixo, anexos),
  **Notas** (notas do jogador editáveis, quadro de pistas com etiquetas Facto/Hipótese/Mentira/
  Incompleta/Dúvida e ligações, reconstrução da noite), **Ficheiros** (pastas, ocultos, áudio com
  transcrição, arquivos com palavra-passe), **Definições** (wi-fi, brilho, não incomodar, bateria
  com "ECO Service", contas, ficheiros ocultos, opções de programador, consola ECO),
  **Relógio** (relógio, alarmes, cronómetro), **ECO** (consola escondida)

### Conteúdo (`data/`)
- 11 capítulos (`data/chapters/ch01..ch11.story`) + `global.story` (chamadas e regras globais)
- 19 personagens com vozes distintas (ver `docs/STORY_BIBLE.md`)
- 37 fotografias procedurais com variantes (mudanças silenciosas), metadata e pormenores
- 26 páginas web, 25 emails, 25 ficheiros, 10 notas, 7 mensagens de voz, mapa com 12 locais
- 136 pistas com relações; reconstrução final com 5 perguntas
- 5 finais com texto próprio (Verdade, Mentira, Silêncio, Loop, Eco secreto)

## Momentos de terror (por capítulo)

| Cap. | Momentos |
|---|---|
| 1 | Fotografia tirada da rua 3 min antes da 1.ª mensagem; "Dorme, Daniel." |
| 2 | Foto da porta do quarto de dentro, às 03:02; mar no correio de voz; sabe dos Saramagos; "Para de perguntar." → "Estás a assustar-me."; voz de mulher na chamada; alguém debaixo do candeeiro |
| 3 | O número era de uma morta; "Faz quatro dias que me perguntas isso"; "Tu estavas lá."; chamada às 03:17 |
| 4 | O pescador viu-te ir embora a pé enquanto ela te chamava |
| 5 | Mensagem antiga muda; mensagem enviada sem ti; pesquisas que não fizeste; nota do futuro; vulto no corredor (câmara); contacto muda de nome; localização no cais; foto tirada por trás; a tua voz a sussurrar numa gravação; reinício + PIN = data da morte; reflexo no ecrã apagado; 17 min de silêncio; 3 pancadas; a Sofia escreve "Ainda estás acordado?"; a voz repete a tua frase |
| 6 | Últimas mensagens restauradas ("Ele está aqui"); pessoa na água no fundo de ecrã |
| 7 | Rosto na janela; o telemóvel escreve e envia sozinho; mensagem do João que o João não enviou; a médica sabe demais |
| 8 | O registo prevê as 11:04 e acontece; o telemóvel abre a captura do que fizeste; fotografado a dormir |
| 9 | A gravação do cais; alguém atrás de ti na câmara frontal |
| 3–10 | Vibrações fantasma raras; recibo "Lida · 03:17"; a voz comenta as etiquetas do teu quadro de pistas |

## Decisões técnicas

- **Godot 4.3, GL Compatibility**: UI 2D pesada, export simples para Windows/Linux, corre em
  máquinas fracas e em Xvfb (permite capturas automáticas).
- **UI construída em código** (não `.tscn`): mais robusto de gerar/rever; tema único em `UI.build_theme()`.
- **Fotografias procedurais** (`PhotoPresets` + `PhotoView`): a história pode mudar uma fotografia
  sem o jogador o poder provar; zero assets binários; grão/vinheta por shader.
- **Som procedural**: idem; gerado numa thread no arranque.
- **Narrativa em DSL própria** em vez de JSON: muito mais legível/escrevível; validada por testes.
- **Expressões Godot** para condições (`flag("x") and at("03:17")`), validadas no teste.
- **Lambdas GDScript capturam variáveis locais por valor** — usar Dictionary/Array como caixa (bug encontrado nos testes).

## Bugs corrigidos nesta sessão
- Deteção de inatividade usava `_unhandled_input` (cliques na UI não contavam) → `_input`.
- Polígono degenerado (barba) gerava erros de triangulação.
- Notas com data "?" faziam crash ao abrir as Notas.
- Gravar entre o fim de um capítulo e o seguinte podia bloquear o jogo → `chapter_complete` retomado ao carregar.
- Conversa da consola ECO só existia no cap. 8 → final secreto inalcançável para quem abrisse a consola mais tarde.
- Testes escreviam no perfil e na gravação automática do jogador → pastas separadas.
- `inc` dentro de opções de escolha era interpretado como `set` → contadores de confiança viravam booleanos
  (final B inalcançável). Corrigido no parser + validação que deteta chaves suspeitas.
- Botões com `autowrap` expandiam verticalmente e escondiam a conversa → `UI.wrap_button` com altura calculada.
- Ecrã de bloqueio sobreposto ao ecrã principal.
- Captura de lambdas nos testes (ver acima).
- Barra de estado escondida pelo ecrã de chamada (`move_child`).

## Testes realizados
- `tests/run_tests.tscn`: validação de dados (3500+ verificações), gravação/carregamento com
  ficheiro corrompido, 5 jogadas completas automáticas (uma por final) — **todas passam**.
- Revisão visual por capturas (Xvfb): título, bloqueio, mensagens, todas as apps, chamada, final,
  câmara (3 eventos), menus.
- Teste de fumo da UI: abre todas as apps e sub-ecrãs com o estado de fim de jogo; `tools/run_tests.sh`
  falha se aparecer qualquer SCRIPT ERROR.
- Export: builds Windows e Linux geradas com os *templates* 4.3; a build Linux arranca e carrega os dados.

## Problemas conhecidos
- Duração real abaixo do objetivo (ver prioridades).
- Ainda não houve teste com jogador humano real: ritmo dos capítulos diurnos (rate 2) por confirmar.
- Fonte padrão do Godot: evitar emoji e símbolos fora de Latin-1 nos textos.
- Sem localização para inglês (o texto está todo em `data/`, preparado para isso).

## Próximas prioridades
1. **Jogar como humano** os capítulos 1–3 e afinar ritmo/silêncios/sustos.
2. **Mais profundidade por capítulo** (objetivo 14 h): conversas laterais com o grupo, Carla e mãe;
   mais páginas web e pistas opcionais; investigações secundárias (Lumen, clínica, fórum); um
   segundo "caminho" no cap. 4 e no cap. 7.
3. Integrar GodotSteam (GDExtension) e App ID reais; configurar Auto-Cloud para `user://saves`.
4. Afinar mistura de áudio e ambiente por capítulo.
5. Tradução para inglês.
