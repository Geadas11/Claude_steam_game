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
| Windows | `WinAppDataRoaming` | `AindaEstasAcordado/saves` | `*.json` |
| Linux | `LinuxXdgDataHome` | `AindaEstasAcordado/saves` | `*.json` |
| Windows/Linux | (idem) | `AindaEstasAcordado` | `profile.json` (conquistas/finais) |

`settings.cfg` deve ficar **fora** da nuvem (resolução/ecrã inteiro são por máquina).

## 3. Builds

```bash
godot --headless --export-release "Windows Desktop" builds/windows/AindaEstasAcordado.exe
godot --headless --export-release "Linux" builds/linux/AindaEstasAcordado.x86_64
```
Os presets incluem `*.json, *.story` e excluem `tests/` e `tools/`. Ambas as builds foram
geradas e a de Linux foi testada a arrancar e a carregar a história.

## 4. Conquistas (34)

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
| `all_achievements` | Ainda estou acordado | Desbloquear todas as conquistas. | sim |

## 5. Descritores de conteúdo (questionário Steam)

- Violência: não gráfica (uma morte por queda, só em áudio/texto).
- Temas maduros: morte, luto, menções a suicídio (contestadas pela narrativa), vigilância,
  manipulação psicológica, saúde mental. O jogo mostra contactos reais de apoio emocional
  (SOS Voz Amiga, SNS 24) se o jogador pesquisar temas de crise.
- Sons súbitos e cintilação: opções "Reduzir efeitos visuais" e "Reduzir movimento".
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
em que acreditas · 34 conquistas · legendas e opções de acessibilidade.

## 7. Pendente antes de lançar

- [ ] App ID e depots reais; remover `steam_appid.txt` das builds.
- [ ] Ícone final (`icon.svg` é provisório) e cápsulas da loja.
- [ ] Tradução para inglês (todo o texto está em `data/`).
- [ ] Teste em Steam Deck (resolução 1280×800; a UI escala pela altura).
