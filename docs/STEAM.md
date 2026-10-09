# Steam — guia de lançamento

## 1. Integração (GodotSteam)

O jogo já fala com o Steam quando o singleton `Steam` existe (ver
`scripts/core/achievements.gd`). Sem ele, tudo funciona em modo local.

1. Instalar **GodotSteam GDExtension** para Godot 4.3 em `addons/godotsteam/`
   (https://godotsteam.com). Não é preciso alterar código: o singleton passa a existir.
2. Criar `steam_appid.txt` na raiz (só para desenvolvimento; **não** incluir na build final).
3. Em `achievements.gd`, `steamInitEx()` é chamado no arranque; `run_callbacks()` todos os frames.
4. Conquistas: os ids no Steamworks têm de ser **exatamente** os da tabela abaixo.

## 2. Steam Cloud (Auto-Cloud)

As gravações são JSON pequenos (< 1 MB). Configurar Auto-Cloud no Steamworks:

| SO | Raiz | Subcaminho | Padrão |
|---|---|---|---|
| Windows | `WinAppDataRoaming` | `UNKNOWN/saves` | `*.json` |
| Linux | `LinuxXdgDataHome` | `UNKNOWN/saves` | `*.json` |
| Windows/Linux | (idem) | `UNKNOWN` | `profile.json` (conquistas/finais) |

`settings.cfg` deve ficar **fora** da nuvem (resolução/ecrã inteiro são por máquina).

## 3. Builds

```bash
godot --headless --export-release "Windows Desktop" builds/windows/UNKNOWN.exe
godot --headless --export-release "Linux" builds/linux/UNKNOWN.x86_64
```
Os presets incluem `*.json, *.story` e excluem `tests/` e `tools/`. Ambas as builds foram
geradas e a de Linux foi testada a arrancar e a carregar a história.

## 4. Conquistas (37)

| id | Nome | Descrição | Secreta |
|---|---|---|---|
| `first_message` | Ainda acordado | Responder à primeira mensagem. |  |
| `ch1_done` | Vida normal | Terminar o capítulo 1. |  |
| `ch3_done` | Há um ano | Descobrir de quem é o número. |  |
| `ch5_done` | Não fui eu | Sobreviver à noite em que o telefone mudou. |  |
| `ch8_done` | O sistema | Perceber o que corre dentro do telefone. |  |
| `first_note` | Teoria | Escrever a tua primeira nota. |  |
| `clues_10` | Reparaste | Encontrar 10 pistas. |  |
| `clues_30` | Obsessivo | Encontrar 30 pistas. |  |
| `clues_all` | Tudo o que havia para ver | Encontrar todas as pistas. | sim |
| `hidden_files` | Ficheiros ocultos | Mostrar os ficheiros que o sistema esconde. |  |
| `developer` | Agora és programador | Ativar as opções de programador. |  |
| `eco_console` | Consola | Abrir a consola do ECO. | sim |
| `pin_first_try` | O dia em que deixaste de dormir | Acertar no PIN à primeira. | sim |
| `answered_dead` | Atendeste | Atender uma chamada de alguém que morreu. | sim |
| `photographed_ghost` | Prova | Fotografar aquilo que não devia estar na fotografia. | sim |
| `deduction_perfect` | A noite inteira | Reconstruir a noite de 14 de outubro sem erros. |  |
| `no_reply` | Não respondas | Ignorar o número desconhecido duas vezes seguidas. | sim |
| `armando` | Testemunha | Falar com o homem que a encontrou. |  |
| `dnd_ignored` | Não incomodar | Descobrir que há coisas que ignoram o modo Não incomodar. | sim |
| `blog_unlocked` | O companheiro de casa | Entrar no blogue da Inês. |  |
| `backup_unlocked` | O PIN antigo | Abrir a cópia de segurança do telemóvel antigo. |  |
| `found_card` | Onde a maré não chega | Encontrar a cópia da Inês. |  |
| `ending_A` | Verdade | Chegar ao final Verdade. |  |
| `ending_B` | Mentira | Chegar ao final Mentira. |  |
| `ending_C` | Silêncio | Chegar ao final Silêncio. |  |
| `ending_D` | Loop | Chegar ao final Loop. |  |
| `ending_E` | Eco | Chegar ao final secreto. | sim |
| `three_endings` | Outra vez | Ver três finais diferentes. |  |
| `all_endings` | Todas as versões | Ver os quatro finais principais. |  |
| `rita_keep` | Não estás maluca | Dizer à Rita para guardar tudo. |  |
| `compare_pair` | No mesmo segundo | Comparar duas fotografias tiradas no mesmo segundo. |  |
| `private_note` | A mesma palavra-passe | Abrir a nota "privado". | sim |
| `patent` | Reivindicação 7 | Encontrar a patente do espelho. |  |
| `her_handwriting` | A letra dela | Ver o que o Rui encontrou na secretária da Inês. |  |
| `eleven_calls` | Onze vezes | Perguntar à tua mãe onde estavas nessa noite. |  |
| `call_self` | Ao mesmo ritmo | Ligar para o teu próprio número. | sim |
| `all_achievements` | Ainda estou acordado | Desbloquear todas as conquistas. | sim |

## 5. Descritores de conteúdo (questionário Steam)

- Violência: não gráfica (uma morte por queda, só em áudio/texto).
- Temas maduros: morte, luto, menções a suicídio (contestadas pela narrativa), vigilância,
  manipulação psicológica, saúde mental. O jogo mostra contactos reais de apoio emocional
  (SOS Voz Amiga, SNS 24) se o jogador pesquisar temas de crise.
- Sons súbitos e cintilação: opções "Suavizar sons súbitos", "Reduzir efeitos visuais" e "Reduzir movimento".
  Contactos de apoio também em Extras → Créditos.
- Privacidade: o jogo **não** acede a câmara, microfone, ficheiros nem localização reais.

## 6. Texto da loja (rascunho)

**PT — curto:** Às 23:47 chega uma mensagem de um número que não conheces: "Ainda estás
acordado?". O número pertencia a uma mulher que morreu há um ano. Um thriller de terror
psicológico jogado inteiramente através de um telemóvel.

**EN — short:** At 11:47 p.m. a message arrives from a number you don't know: "Are you
still awake?". The number belonged to a woman who died a year ago. A psychological horror
thriller played entirely through a phone.

**Funcionalidades:** 11 capítulos · 5 finais (1 secreto) · investigação livre numa internet
fictícia · fotografias que mudam quando não estás a olhar · quadro de pistas onde decides
em que acreditas · 37 conquistas · legendas e opções de acessibilidade.

## 7. Modo cooperativo pelo Steam (preparado, por ativar)

O jogo online já funciona com **ligação direta** (código de sala com IP e porta; tenta abrir a porta
no router por UPnP). A ligação pelo **Steam** está escrita em `scripts/net/steam_transport.gd` e
entra sozinha quando o Steam estiver disponível — o jogo escolhe o transporte em `Coop.uses_steam()`.

Como funciona com o Steam: o jogo de quem cria a sala continua a ser o servidor; o Steam cria um
*lobby* "só amigos" de 2 lugares, mostra o convite na lista de amigos (ou o amigo escreve o código de
13 caracteres) e retransmite o tráfego pelos servidores dele (Steam Datagram Relay), por isso
ninguém precisa de abrir portas nem há servidores nossos.

Para ativar, quando houver App ID:
1. Instalar o **GodotSteam** (versão GDExtension para Godot 4.3, pela Asset Library ou godotsteam.com).
2. Criar `steam_appid.txt` na raiz do projeto com o App ID (só para desenvolvimento; não vai nas builds).
3. No Steamworks: ativar **Steam Networking** e as conquistas (secção 4).
4. Testar com **duas contas Steam** em dois PCs: "Jogar online" → "Criar sala" → "Convidar amigo
   do Steam"; e também entrar com o código.
5. O código foi escrito para a API do GodotSteam 4.x mas **ainda não foi testado** (precisa de App ID):
   conferir os nomes dos sinais (`lobby_created`, `lobby_joined`, `lobby_chat_update`,
   `join_requested`, `network_messages_session_request`) e de `receiveMessagesOnChannel`.

## 8. Pendente antes de lançar

- [ ] App ID e depots reais; remover `steam_appid.txt` das builds.
- [ ] Ícone final (`icon.svg` é provisório) e cápsulas da loja.
- [ ] Tradução para inglês (todo o texto está em `data/`).
- [ ] Teste em Steam Deck (resolução 1280×800; a UI escala pela altura).
