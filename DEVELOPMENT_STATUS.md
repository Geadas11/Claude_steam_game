# DEVELOPMENT_STATUS

> Ler isto no início de cada sessão. Continuar de onde ficou. Nunca recomeçar do zero.

**Projeto:** Ainda Estás Acordado? (PROJECT UNKNOWN) · Godot 4.3 · GL Compatibility · pt-PT
**Última atualização:** sessão 1 (2026-10-08)
**Branch:** `claude/relaxed-cray-lgubk6` (commits locais; o *push* para o GitHub falhou com 403 —
ver "Problemas conhecidos")

---

## Estado geral

| Área | Estado |
|---|---|
| Arquitetura (Core) | ✅ completa e testada |
| Shell do telemóvel | ✅ completa (bloqueio, PIN, ecrã principal, cortina de notificações, auto-bloqueio) |
| 13 aplicações | ✅ funcionais |
| Motor narrativo (DSL `.story`) | ✅ completo; retoma beats a meio após carregar |
| História — 11 capítulos | ✅ escritos de ponta a ponta + arcos secundários |
| 5 finais (+ epílogos condicionais) | ✅ todos alcançáveis (testado automaticamente) |
| Investigação | ✅ 163 pistas com relações e etiquetas; reconstrução final; 7 puzzles |
| Terror | 🟡 integrado e variado (ver tabela); falta afinação com jogadores humanos |
| Áudio | 🟡 procedural, funcional; afinar mistura em jogo real |
| Steam | 🟡 ponte GodotSteam + 30 conquistas + guia (`docs/STEAM.md`); builds Win/Linux testadas; falta App ID |
| Duração | 🟡 estimativa ~4–6 h na 1.ª passagem, 8–10 h para tudo (objetivo do documento: 14 h+) |

## Conteúdo

- **11 capítulos** em `data/chapters/` + `global.story` (chamadas de amigos, reações globais, consola ECO)
- **21 personagens** com vozes distintas (ver `docs/STORY_BIBLE.md`)
- **38 fotografias** procedurais com variantes que mudam (algumas *enquanto o jogador olha*)
- **35 páginas web** (6 escondidas: só aparecem com a pesquisa certa)
- **29 emails**, **25 ficheiros**, **11 notas** (1 protegida), **7 mensagens de voz**, mapa com 12 locais
- **163 pistas**, quadro com etiquetas Facto/Hipótese/Mentira/Incompleta/Dúvida + filtros
- **Puzzles:** PIN 1410 · palavra-passe do blogue (tejo) · nota "privado" (mesma palavra-passe) ·
  cópia do telemóvel antigo (0202) · modo de programador (7 toques) · chave ECO (mare) ·
  reconstrução da noite (5 perguntas, opções desbloqueadas por pistas)
- **Arcos secundários:** Rita (outra "sujeita" — 41 telemóveis oferecidos pela clínica), o primo do
  Pedro ("o aquário"), a patente do espelho (a Inês é coinventora), a Marta lembra-se de vocês,
  a mãe ao domingo, a Carla e a fotografia dentro do livro
- **Rejogabilidade:** a voz lembra-se de iterações anteriores; o ecrã do título muda conforme o último final

## Momentos de terror (por capítulo)

| Cap. | Momentos |
|---|---|
| 1 | Fotografia tirada da rua 3 min antes da 1.ª mensagem; "Dorme, Daniel." |
| 2 | Foto da porta do quarto de dentro, às 03:02; mar no correio de voz; sabe dos Saramagos; "Para de perguntar." → "Estás a assustar-me."; voz de mulher na chamada; alguém debaixo do candeeiro |
| 3 | O número era de uma morta; "Faz quatro dias que me perguntas isso"; "Tu estavas lá."; chamada às 03:17 |
| 4 | O pescador viu-te ir embora a pé enquanto ela te chamava |
| 5 | Mensagem antiga muda; mensagem enviada sem ti; pesquisas que não fizeste; nota do futuro; vulto no corredor; contacto muda de nome; "Localização atualizada · Cais Velho"; foto tirada por trás; "Aplicação desconhecida — Algo correu mal."; a tua voz a sussurrar numa gravação; reinício + PIN = data da morte; reflexo no ecrã apagado; 17 min de silêncio; 3 pancadas; a Sofia escreve "Ainda estás acordado?"; a voz repete a tua frase |
| 6 | Últimas mensagens restauradas ("Ele está aqui"); o fundo de ecrã ganha uma pessoa enquanto olhas |
| 7 | Rosto na janela; o telemóvel escreve e envia sozinho; mensagem do João que o João não enviou; a médica sabe demais |
| 8 | O registo prevê as 11:04 e acontece; o telemóvel abre sozinho a captura do que fizeste; a fotografia do cais aproxima-se enquanto olhas; fotografado a dormir; vaga de internamento "sem telemóvel" |
| 9 | A gravação do cais; alguém atrás de ti na câmara frontal; a Rita "está bem" |
| 11 | A caminhada: "voltaste" |
| 3–10 | Vibrações fantasma raras; recibo "Lida · 03:17"; a voz comenta as etiquetas do teu quadro de pistas |

## Funcionalidades técnicas

- **Core:** GameState serializável · StoryParser (DSL → programas lineares, `if/elif/else`) ·
  Director (beats paralelos, condições via `Expression`, escolhas, chamadas recebidas/efetuadas,
  interpolação `${var}`, ~55 comandos) · Clock (aceleração ×6 quando parado + opção 1–3×; bateria
  drena com avisos) · Saves (5 espaços + auto + rápido; escrita atómica + `.bak`) · Audio
  procedural (~45 sons) · Achievements (30, espelho Steam) · Settings (volumes por barramento, texto,
  velocidade de mensagens/relógio, legendas, alto contraste, reduzir efeitos/movimento,
  ecrã/vsync/resolução, **remapeamento de teclas**)
- **Telemóvel:** ver README. Inclui cortina de notificações com atalhos (não incomodar, lanterna que
  ilumina a sala), auto-bloqueio, foco para comando, transições, interferência por shader.

## Decisões técnicas

- **Godot 4.3, GL Compatibility**: UI 2D pesada, export simples, corre em Xvfb (capturas automáticas).
- **UI em código** (não `.tscn`), tema único em `UI.build_theme()`.
- **Fotografias e som procedurais**: zero assets binários; a história altera fotografias sem prova.
- **DSL própria** para narrativa, validada por testes; **expressões Godot** para condições.
- **Lambdas GDScript capturam locais por valor** — usar Dictionary/Array como caixa.
- **`load()` de um script com erros não devolve null** — `check.sh` usa `can_instantiate()`.

## Bugs corrigidos nesta sessão
- `inc` em opções de escolha era lido como `set` (contadores viravam booleanos; final B inalcançável).
- Botões com `autowrap` escondiam a conversa → `UI.wrap_button`.
- Bloqueio sobreposto ao ecrã principal; barra de estado escondida pelas chamadas.
- Inatividade usava `_unhandled_input` (cliques não contavam) → `_input`.
- Polígono degenerado (barba) → erros de triangulação.
- Crash ao abrir notas com data "?".
- Gravar entre capítulos podia bloquear → `chapter_complete`.
- Consola ECO só no cap. 8 → final secreto inalcançável para quem chegasse mais tarde.
- Testes escreviam no perfil/gravações do jogador → pastas separadas.
- Erro de inferência de tipos no filtro de pistas (apanhado pelo teste de UI).
- Possíveis bloqueios no fim dos caps. 4 e 5 → *fallbacks* temporais.
- Ecrã principal reconstruído a cada mudança de estado.

## Testes

- `tools/check.sh` — compila todos os scripts (falha em erros de parse).
- `tools/run_tests.sh` — em paralelo: validação de dados (~4300 verificações: referências, expressões,
  pistas, finais), gravação/carregamento (incl. ficheiro corrompido → `.bak`), 5 jogadas completas
  (uma por final, via `tests/walkthrough.json`) e varrimento da UI com estado de fim de jogo
  (todas as apps, conversas, fotos, emails, ficheiros, páginas, definições, locais).
  Falha se aparecer qualquer `SCRIPT ERROR`. **Estado: tudo verde.**
- Revisão visual por capturas (Xvfb, `--shot`/`--do`): título (3 variantes), bloqueio, mensagens, todas
  as apps, chamada, câmara (3 eventos), cortina, menus, transição de capítulo, final, Steam Deck 1280×800.
- Export: builds Windows e Linux; a de Linux arranca e carrega a história.

## Problemas conhecidos
- **Push para o GitHub falhou (403)**: a app GitHub do Claude não tem acesso a
  `Geadas11/Claude_steam_game`. Ligar/instalar em https://claude.ai/connect-github e fazer push do branch.
- Duração abaixo do objetivo de 14 h (ver prioridades).
- Ainda sem teste com jogadores humanos: ritmo de capítulos diurnos (`rate 2`) por confirmar.
- Fotografias com pessoas têm aspeto ilustrado (estilo assumido, mas menos "real").
- Sem tradução para inglês.
- No contentor de desenvolvimento não há placa de som (erros ALSA nos logs são do ambiente).

## Próximas prioridades
1. **Sessão de jogo humana** (caps. 1–3 primeiro): ritmo, clareza, silêncios, sustos.
2. **Mais profundidade por capítulo** para chegar às 14 h: mais conversas laterais com escolhas,
   investigações secundárias com recompensa (ex.: o "aquário" da Lumen como capítulo opcional),
   mais pormenores escondidos nas fotografias.
3. Integrar GodotSteam real + App ID; Auto-Cloud (`docs/STEAM.md`).
4. Tradução EN (todo o texto está em `data/`).
5. Afinar mistura de áudio por capítulo; considerar música original para o menu e finais.
