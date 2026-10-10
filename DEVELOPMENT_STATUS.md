# DEVELOPMENT_STATUS

> Ler isto no início de cada sessão. Continuar de onde ficou. Nunca recomeçar do zero.

**Projeto:** UNKNOWN (antes «Ainda Estás Acordado?») · Godot 4.3 · Forward+ · pt-PT
**Última atualização:** sessão 1 (2026-10-08) · versão 0.9.0
**Branch:** `claude/relaxed-cray-lgubk6` — no GitHub (`Geadas11/Claude_steam_game`)

---

## Estado geral

| Área | Estado |
|---|---|
| Arquitetura (Core) | ✅ completa e testada |
| Shell do telemóvel | ✅ completa (bloqueio, PIN, ecrã principal, cortina de notificações, auto-bloqueio) |
| 13 aplicações | ✅ funcionais |
| Motor narrativo (DSL `.story`) | ✅ completo; retoma beats a meio após carregar |
| História — 11 capítulos | ✅ escritos de ponta a ponta + arcos secundários |
| 5 finais (+ epílogos condicionais) | ✅ todos alcançáveis (testado automaticamente); epílogos antes da imagem final (`coda`) |
| Investigação | ✅ 194 pistas com relações e etiquetas; reconstrução final; 7 puzzles |
| Terror | 🟡 integrado e variado (ver tabela); falta afinação com jogadores humanos |
| Áudio | 🟡 procedural, funcional; afinar mistura em jogo real |
| Steam | 🟡 ponte GodotSteam + 37 conquistas + guia (`docs/STEAM.md`); builds Win/Linux testadas; falta App ID |
| Duração | 🟡 estimativa ~4–6 h na 1.ª passagem, 8–10 h para tudo (objetivo do documento: 14 h+) |

## Conteúdo

- **11 capítulos** em `data/chapters/` + `global.story` (chamadas de amigos, reações globais, consola ECO)
- **21 personagens** com vozes distintas (ver `docs/STORY_BIBLE.md`)
- **43 fotografias** procedurais com variantes que mudam (algumas *enquanto o jogador olha*)
- **36 páginas web** (7 escondidas: só aparecem com a pesquisa certa)
- **30 emails**, **25 ficheiros**, **11 notas** (1 protegida), **8 mensagens de voz**, mapa com 12 locais
- **194 pistas**, quadro com etiquetas Facto/Hipótese/Mentira/Incompleta/Dúvida + filtros
- **Puzzles:** PIN 1410 · palavra-passe do blogue (tejo) · nota "privado" (mesma palavra-passe) ·
  cópia do telemóvel antigo (0202) · modo de programador (7 toques) · chave ECO (mare) ·
  reconstrução da noite (5 perguntas, opções desbloqueadas por pistas)
- **Arcos secundários:** Rita (outra "sujeita" — 41 telemóveis oferecidos pela clínica), o primo do
  Pedro ("o aquário"), a patente do espelho (a Inês é coinventora), a Marta lembra-se de vocês (e viu-te pôr flores no cais),
  a mãe ao domingo, a Carla e a fotografia dentro do livro, o caixote da secretária da Inês (Rui),
  o Sr. Armando disposto a testemunhar, a consola do ECO (2 sessões)
- **Rejogabilidade:** a voz lembra-se de iterações anteriores; o ecrã do título (e a música) muda conforme o último final
- **Consequências pequenas que voltam:** o livro que recomendaste à Marta (cap. 1 → 10), as ações do
  Pedro (cap. 1 → epílogo), a chamada da Sofia na última noite, a mãe e a chamada das 04:30

## Momentos de terror (por capítulo)

| Cap. | Momentos |
|---|---|
| 1 | Fotografia tirada da rua 3 min antes da 1.ª mensagem; "Dorme, Daniel." |
| 2 | Foto da porta do quarto de dentro, às 03:02; mar no correio de voz; sabe dos Saramagos; "Para de perguntar." → "Estás a assustar-me."; voz de mulher na chamada; alguém debaixo do candeeiro |
| 3 | O número era de uma morta; "Faz quatro dias que me perguntas isso"; "Tu estavas lá."; chamada às 03:17 |
| 4 | O pescador viu-te ir embora a pé enquanto ela te chamava; a médica sabe quantas horas dormiste — e o que pesquisaste |
| 5 | Mensagem antiga muda; mensagem enviada sem ti; pesquisas que não fizeste; nota do futuro; vulto no corredor; contacto muda de nome (e não o consegues bloquear); "Localização atualizada · Cais Velho"; foto tirada por trás; "Aplicação desconhecida — Algo correu mal."; a tua voz a sussurrar numa gravação; reinício + PIN = data da morte; reflexo no ecrã apagado; 17 min de silêncio; 3 pancadas; a Sofia escreve "Ainda estás acordado?"; a voz repete a tua frase |
| 6 | Últimas mensagens restauradas ("Ele está aqui"); uma captura de ecrã que não tiraste: "Vou já", por enviar, 03:13; o fundo de ecrã ganha uma pessoa enquanto olhas; o caixote da secretária da Inês (post-it "D. — p. 317") |
| 7 | Rosto na janela; o telemóvel escreve e envia sozinho; mensagem do João que o João não enviou; a médica sabe demais |
| 8 | O registo prevê as 11:04 e acontece; o telemóvel abre sozinho a captura do que fizeste; a fotografia do cais aproxima-se enquanto olhas; fotografado a dormir; vaga de internamento "sem telemóvel" |
| 9 | A gravação do cais; alguém atrás de ti na câmara frontal; a Rita "está bem"; a mãe lembra-se de uma chamada tua às 04:30, só com o mar |
| 10 | Uma chamada perdida de "Eu" — e uma mensagem de voz com a tua voz, junto ao mar; ligar de volta: alguém respira ao teu ritmo |
| 11 | A caminhada: "voltaste" |
| 3–10 | Vibrações fantasma raras; recibo "Lida · 03:17"; a voz comenta as etiquetas do teu quadro de pistas |

## Funcionalidades técnicas

- **Core:** GameState serializável · StoryParser (DSL → programas lineares, `if/elif/else`) ·
  Director (beats paralelos, condições via `Expression`, escolhas, chamadas recebidas/efetuadas,
  interpolação `${var}`, ~55 comandos) · Clock (aceleração ×6 quando parado + opção 1–3×; bateria
  drena com avisos) · Saves (5 espaços + auto + rápido; escrita atómica + `.bak`) · Audio
  procedural (~45 sons) · Achievements (37, espelho Steam) · Settings (volumes por barramento, texto,
  velocidade de mensagens/relógio, legendas, avisos de pistas, alto contraste, reduzir efeitos/movimento,
  suavizar sons súbitos,
  ecrã/vsync/resolução, **remapeamento de teclas**)
- **Menus:** pausa com **"Até agora"** (resumo de cada capítulo já jogado) e **"Decisões"**;
  ao **Continuar** aparece um cartão "Anteriormente…"; texto dos finais avança com clique/tecla;
  Extras com estatísticas entre partidas e créditos (com contactos de apoio); epígrafes de Pessoa nos
  cartões de capítulo.
- **Música procedural:** menu, memória e uma caixa de música desafinada (finais C/D e título depois deles).
- **Telemóvel real (QR) — versão 2:** a página é agora uma cópia do telemóvel do jogo: mesmo ecrã
  principal (fundo, relógio, 12 apps com os mesmos ícones em SVG, avisos), letra Inter servida pelo
  jogo. Mensagens, Telefone (recentes + ligar), Contactos, Galeria (fotos reais em JPEG, com zoom),
  Notas e Email funcionam no próprio telemóvel; Mapas, Ficheiros, Navegador, Relógio, Definições,
  Câmara e ECO abrem no ecrã do PC. Tudo o que se abre no telemóvel abre também no PC, para a
  história reagir como sempre; o PIN do telemóvel do jogo nunca é saltado. Botão "voltar" do
  telemóvel funciona.
- **Telemóvel real (QR) — v3, espelho do telemóvel do jogo:** no início de cada sessão o jogo pergunta
  "Que telemóvel vais usar?" (o meu / o do jogo). Com o do jogador, o telemóvel do jogo é desenhado
  numa SubViewport (630×1320) e enviado em JPEG por WebSocket (8 fps parado, 20 fps a mexer, só quando
  muda; codificação numa thread). O toque volta como toque/arrastar/deslizar (scroll), o teclado do
  telemóvel escreve nos campos do jogo, o gesto "voltar" funciona, há som de notificação, toque de
  chamada e vibração. Ecrã inteiro + "Adicionar ao ecrã principal" (manifest e ícones). O PC mostra só
  um relógio; o outro telemóvel não aparece nessa sessão. Se a ligação cai, o jogo pausa e mostra o QR
  para voltar a ligar. Ficheiros: `scripts/net/companion.gd`, `companion/index.html`,
  `scripts/menu/phone_choice_panel.gd`. Testes: `--only=companion` (15 verificações).
- **Telemóvel:** ver README. Inclui cortina de notificações com atalhos (não incomodar, lanterna que
  ilumina a sala), auto-bloqueio, foco para comando, transições, interferência por shader.
- **Qualidade visual (sessão 2):** letra Inter, contraste ≥ 4,5:1, sem emojis como ícones; fundo do
  ecrã com pôr do sol fotográfico (`tools/render_sunset.py`, com variante "alguém na água") e véu em
  gradiente; animação ao toque em todos os botões (encolhe e volta com mola, só escala — nada se mexe à
  volta); apps abrem e fecham com esbatimento; ecrãs dentro das apps deslizam (entrar → da direita,
  voltar → da esquerda); mensagens novas aparecem com um pequeno "pop". Tempos partilhados em `UI.T_*`;
  "Reduzir movimento" desliga tudo.

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
- `app()` ficava "messages" ao abrir uma conversa a partir de uma notificação (o `open_app` escrevia
  por cima depois do `setup`) → beats do tipo `app() == "messages:x"` não disparavam. Teste de regressão.
- Duas escolhas na mesma conversa: a segunda apagava a primeira (beat preso) → fila por conversa.
- Cabeçalho da conversa não mudava quando o contacto era renomeado.
- **Os avisos curtos (toasts) apareciam fora do ecrã** — nenhum era visível (ex.: "Dentro da capa: um
  cartão microSD"). Corrigido + fila de avisos + teste. Pistas novas passam a mostrar "Nova pista: …"
  (clicável fora das conversas: abre Notas → Pistas; pode ser desligado nas Definições).
- Conquistas desbloqueadas ao mesmo tempo sobrepunham-se → empilham.

## Testes

- `tools/check.sh` — compila todos os scripts (falha em erros de parse).
- `tools/run_tests.sh` — em paralelo: validação de dados (~5700 verificações: referências, expressões,
  pistas, finais), gravação/carregamento (incl. ficheiro corrompido → `.bak`), 5 jogadas completas
  (uma por final, via `tests/walkthrough.json`) e varrimento da UI com estado de fim de jogo
  (todas as apps, conversas, fotos, emails, ficheiros, páginas, definições, locais).
  Falha se aparecer qualquer `SCRIPT ERROR`. **Estado: tudo verde.**
- Revisão visual por capturas (Xvfb, `--shot`/`--do`): título (3 variantes), bloqueio, mensagens, todas
  as apps, chamada, câmara (3 eventos), cortina, menus, transição de capítulo, final, Steam Deck 1280×800.
- Export: builds Windows e Linux; a de Linux arranca e carrega a história.
- Testes de resistência em tempo real (`--autoplay`, Xvfb): todos os capítulos, 1 a 11 (o 11 até ao
  ecrã de final) — sem erros de script.
- Testes de regressão para bugs desta sessão: `app()` ao abrir conversa por notificação, avisos dentro
  do ecrã, painéis "Até agora"/"Decisões" com conteúdo, resumo para cada capítulo.

## Problemas conhecidos
- Duração abaixo do objetivo de 14 h (ver prioridades).
- Ainda sem teste com jogadores humanos: ritmo de capítulos diurnos (`rate 2`) por confirmar.
- Fotografias com pessoas têm aspeto ilustrado (estilo assumido, mas menos "real").
- Sem tradução para inglês.
- No contentor de desenvolvimento não há placa de som (erros ALSA nos logs são do ambiente).

## Pedidos do dono do projeto (sessão 2)
- Duração **acima de 10 h** → capítulos novos + mais profundidade nos atuais (plano em `docs/EXPANSION.md`).
- **Multiplayer cooperativo online** → 🟡 fase 1 feita: ligação direta (código de sala, UPnP),
  Daniel (anfitrião) + Sofia (convidada), conversa partilhada, relógio e capítulos sincronizados,
  cap. 1 da Sofia. Steam preparado, por ativar quando houver App ID. Ver `docs/COOP.md`.
- **Telemóvel real** do jogador → ✅ v3: escolha por sessão, o telemóvel do jogo passa para o real (stream).
- **Jogo 3D realista (tipo Phasmophobia)** com perigo real, sustos e cooperativo em locais diferentes →
  plano em 5 fases: 1) telemóvel real + escolha ✅; 2) base 3D (Forward+, primeira pessoa, casa do
  Daniel) ✅; 3) entidade que caça e mata, esconderijos; 4) mais locais; 5) cooperativo 3D (Sofia em Lisboa).

## Higgsfield (sessão 2)

- `tools/higgsfield/main.py`: exemplo com o SDK oficial (`higgsfield-client`) e o modelo
  `bytedance/seedance-2.5/text-to-video` (5 s, 720p, 16:9). Credenciais em `.env.local` (`HF_KEY`,
  ignorado pelo Git). `tools/gen_images.py` passa a usar o Higgsfield (Seedream 4) quando `HF_KEY`
  ou `HF_KEY_FILE` existe.
- Modelos (confirmados na API): fotos sem pessoas de referência → `higgsfield-ai/soul/v2/standard`
  (1080p); fotos com personagens e variantes → `alibaba/qwen-image-3/edit` (até 3 referências, 2k).
- Rede aberta e chave aceite. **Bloqueado:** a conta não tem créditos (`not_enough_credits`); ainda
  não foi gerado nada.

## Fotografias realistas (sessão 2)

- **50 fotografias reais no jogo** (40 + 10 variantes que mudam enquanto se olha), geradas com o
  OpenArt (Nano Banana Pro, 2K, plano Starter, sem marca de água) em `art/photos/`.
- **10 retratos de referência** das personagens em `art/refs/` (fora da build: `.gdignore`); todas as
  fotos com pessoas usam-nos, por isso as caras são as mesmas em todo o jogo.
- Fotos de noite demasiado claras passam por `tools/night_grade.py`; `tools/fetch_image.py` descarrega
  e normaliza. As zonas de pistas (`data/photos.json`) foram reposicionadas foto a foto.
- Continuam desenhadas pelo jogo: IMG_6800, IMG_RITA, IMG_SCR_0313 (capturas de ecrã).
- Custo: cerca de 2 560 créditos (64 gerações de 40 + 1 de teste).

## Casa 3D (fase 2)

- **Renderizador Forward+** (Vulkan / D3D12). O jogo passa a ter o Daniel em primeira pessoa na casa
  dele: Rua das Gaivotas 12, rés-do-chão (bate com a IMG_6612: sofá contra a janela, TV à direita,
  lâmpada nua). Sala, quarto, corredor comprido, cozinha, casa de banho, arrumos, patamar e a rua
  com candeeiros de sódio e o prédio da frente. Construída em código (`scripts/world/house.gd`) com
  31 modelos e 12 texturas CC0 do Poly Haven (`tools/fetch_polyhaven.py`, `assets/3d/CREDITS.md`).
- **Controlos:** WASD, Shift (correr, com fôlego), C/Ctrl (agachar), F (lanterna com atraso de
  mão), E (usar), Tab (telemóvel), comando suportado. Passos procedurais (madeira/azulejo), portas
  que abrem e empurram, interruptores por divisão, quadro elétrico, TV, candeeiro de secretária,
  óculo da porta da rua (vista olho-de-peixe do patamar).
- **Telemóvel:** com "o telemóvel do jogo" fica na mão do Daniel à direita (Tab guarda/tira; com
  ele guardado aparece "Tab · Mensagem · Sofia" e vibra). Com "o meu telemóvel" o PC mostra só a
  casa e o telemóvel real é o do jogo.
- **História na casa:** 20 coisas para examinar com pensamentos do Daniel (`data/world/casa.json`,
  condições iguais às dos `.story`, ex.: o frigorífico lembra o que disseste à Sofia ao jantar).
  Cada uma marca `w_<id>` para a história. Novo comando `world` nos `.story` (luzes, piscar,
  quadro, TV, portas, luz do patamar, tremor, pensamentos). Pancadas, passos e a porta ouvem-se
  na porta da rua/no patamar (som 3D); respiração e sussurros atrás do jogador.
- **Hora do dia:** a luz segue o relógio do jogo (Porto em outubro: nasce ~07:40, põe-se ~19:05);
  capítulos de madrugada começam na cama, de noite no sofá; candeeiros da rua só de noite.
- **Qualidade gráfica** (Definições): Baixa / Média / Alta (SSIL, SSAO, nevoeiro volumétrico,
  sombras). Sensibilidade do rato, campo de visão, inverter Y.
- Testes: `--only=world` (35 verificações: andar, paredes, fôlego, agachar, portas, porta
  trancada, examinar, interruptores, quadro elétrico, comandos `world`, som na porta, óculo).
- Builds de teste divididos (`tools/split_pack.gd` + autoload `Packs`): base + `_3d_N.pck`.
- **Ainda não (na altura da fase 2):** perigo/entidade (fase 3), outros locais — livraria, cais, farol (fase 4; por
  agora esses capítulos passam-se em casa), cooperativo 3D da Sofia (fase 5).

## História — Lore Forge (sessão 3)

- O autor vai escrever a história de novo antes das fases 3–5. Instalado o framework
  [Lore Forge](https://github.com/immane/lore-forge) (MIT) em `lore-forge/` (detalhes em `lore-forge/VENDOR.md`).
- Projeto: `lore-forge/projects/active/unknown/` (modelo de ficção interativa). Fase atual: Concept Discovery
  (entrevista em modo diferido: respostas em `.pending/interview_scratch.md`, «build» escreve o Story Bible).
- Story Bible v1 construído (entrevista + rascunho aprovado): 15 capítulos (prólogo + 14), 5 finais, regras da
  coisa (R1–R16), provas equilibradas das duas versões, segredo da Sofia (chamada das 03:52).
- Plano dos capítulos aprovado: `lore-forge/projects/active/unknown/story/chapters/_outline.md`.
- **Fase 4 do jogo passa a incluir** os cenários 3D: Livraria Maré, casa do Rui, Clínica Atlântico, caminho até
  ao cais (EN125, bombas, Largo do Cais), Cais Velho e, no cooperativo, casa e hospital da Sofia em Lisboa.
  Exigência do autor: cenários «bem bons» (realismo igual ou superior à casa).
- Próximo passo da história: cenas e diálogos capítulo a capítulo; depois exportar para `data/chapters/*.story`.

## Cenários 3D (fase 4, sessão 3)

Ordem pedida pelo autor: cenários → a coisa que persegue → história nos cenários → cooperativo da Sofia.

- **Arquitetura:** `Location` (`scripts/world/location.gd`) é a base de todos os sítios (luzes por divisão,
  interruptores, quadro, textos `data/world/<id>.json`, spawns, limites das divisões, esconderijos,
  coisas que mudam quando não se olha (R10/R11), malha de navegação). `GameWorld.go_to(id, onde)` troca de
  sítio; o `main.gd` segue o comando `location` da história (um sítio sem versão 3D — o farol — mostra só
  o telemóvel sobre fundo escuro). Novos comandos `world goto` e `world rain`.
- **Esconderijos:** E num esconderijo → vista de dentro (frestas do roupeiro / escuro), só os olhos mexem; E sai.
- **Livraria Maré** (`bookshop.gd`): salão de 5 m de pé-direito, galeria a toda a volta, escada central,
  milhares de livros (MultiMesh + shader de lombadas), balcão com caixa registadora, canto de leitura,
  escritório, arrecadação, lustre. Pista: o Ricardo Reis na prateleira de cima da galeria.
- **Clínica Atlântico** (`clinic.gd`): receção, corredor com fluorescentes por zonas, gabinete da
  Dr.ª Helena, arquivo (a ficha), posto de enfermagem (chaves), seis quartos com portas de visor
  (quarto 4: «Daniel R.»), rouparia, WC, escada com portão fechado.
- **Caminho e Cais Velho** (`road.gd`, também `cais`): Rua das Gaivotas, EN125 com campos e postes,
  bombas de gasolina, Largo do Cais (Café do Largo, câmara, néon «O FAROL»), cais de pedra e de madeira
  com a grade partida, escadas para a água, flores no poste; mar com ondulação (shader), chuva,
  barcos que balançam, farolim a piscar, candeeiro avariado.
- **Casa do Rui** (`rui_house.gd`): azulejos, chão de tijoleira, vigas; mesa, aparador com a
  fotografia, redes, calendário de outubro de 2025; quarto da Inês (caixa «INÊS», casaco vermelho).
- Texturas/modelos CC0 do Poly Haven (lista em `tools/fetch_polyhaven.py`; importação com `tools/set_imports.py`).
- Teste `--only=world`: cada sítio constrói-se, cada spawn fica de pé, cada esconderijo entra e sai,
  cada coisa examinável tem texto, a navegação gera malha.
- **Falta (fase 4):** casa e hospital da Sofia em Lisboa (com o cooperativo, fase 5).

## A coisa (fase 3, sessão 3)

`scripts/world/presence.gd` + `data/world/presence.json` (forma, mata?, agressividade e mudanças por capítulo).
Segue `knowledge/rules.md` R1–R11.

- **Atenção (0–100)** sobe com: ecrã do telemóvel aceso na mão *no escuro* (debaixo de uma luz é só um
  telemóvel), atender chamadas, escuro, aproximação das 03:17, barulho (correr, portas, falar ao
  telefone). Desce com luz, silêncio, esconder-se, telemóvel guardado.
- **Estados:** longe → perto (sons, pegadas, aparece fora de vista) → espreita (vem para onde te ouviu,
  fica a olhar a 3 m) → caça (vem buscar-te; batimento) → procura (estás escondido: procura uns segundos
  e desiste; se acenderes o ecrã ao pé dela, encontra-te). No escuro total com o telemóvel: perto ~20 s,
  espreita ~45 s, caça ~65 s.
- **Luz afasta (R5):** pára onde começa a luz, faz piscar a lâmpada e acaba por ir embora; acender a luz onde
  ela está ou apontar a lanterna faz com que «nunca tenha estado lá». Candeeiros de rua contam (`lamps`).
- **Nunca nítida (R2):** silhueta de fumo escuro (alfa pontilhado, contorno a desfazer-se, pés perdidos no
  chão); olhada de frente desaparece. Pegadas molhadas (decals). Abre portas no caminho (com som); portas
  trancadas: abana o puxador e aparece noutro lado.
- **Formas (R3):** pegada, telemovel (só falhas no ecrã), observado, substituido (altura do Daniel, passos
  dele), vozes (sussurros), proprio (os teus passos continuam depois de parares), afogar (água, respiração),
  fechado (fecha portas atrás de ti), sozinho (apaga as luzes divisão a divisão), todas.
- **De dia não mata (R6)**, salvo `day_kills` (clínica, cap. 11). Capítulo sem mortes: chega, e desaparece.
- **Mudanças fora de vista (R10/R11)** com o som no sítio (`w_changes`).
- **Morte (R7–R9):** vira-se, ela está ali (desfocada), negro, silêncio → volta ao início do capítulo
  (slot `chapter`, guardado em cada início; `run_id` evita misturar jogos). Marca: `deaths_<cap>`,
  `deaths_total`, `ja_falamos` (para a história) e 1–3 coisas mudadas, ouvidas no escuro. Ninguém diz «morreste».
- **História:** `world presence off|on|calm|near|stalk|hunt [s]|form <f>|attention <n>`. Variáveis para os
  `.story`: `w_presence`, `w_caught`, `w_glimpses`, `w_footprints`, `w_doors_opened`, `w_doors_closed`.
- **Definições → Ameaça:** Normal / Reduzida / Só história (nunca apanha).
- Teste `--only=presence` (29): atrai/afasta, de dia nada, caça e apanha em todos os sítios, luz protege,
  cap. sem mortes, pegadas, portas, esconderijo, mudanças com som, morte → recomeço com marca.

## Próximas prioridades
1. **Sessão de jogo humana** (caps. 1–3 primeiro): ritmo, clareza, silêncios, sustos — guia em `docs/PLAYTEST.md`.
2. **Mais profundidade por capítulo** para chegar às 14 h: mais conversas laterais com escolhas,
   investigações secundárias com recompensa (ex.: o "aquário" da Lumen como capítulo opcional),
   mais pormenores escondidos nas fotografias (ainda sem *hotspots*: IMG_2190, 2155,
   1650, 3301).
   Feito nesta sessão: ~35 novos beats (Rui, Clara, Marta, Sofia, mãe, João, Sr. Armando, Helena,
   ECO), 4 fotografias novas + 6 com pormenores escondidos, 23 pistas, 3 conquistas, epílogos para escolhas pequenas.
3. Integrar GodotSteam real + App ID; Auto-Cloud (`docs/STEAM.md`).
4. Tradução EN (todo o texto está em `data/`).
5. Afinar mistura de áudio por capítulo; considerar música original para o menu e finais
   (já há 3 peças procedurais: menu, memória, caixa de música).
6. Rever com um falante nativo os textos novos (sobretudo as vozes da Marta, do João e da mãe).
