# Modo cooperativo online — "Dois telemóveis"

## A ideia

Dois jogadores, dois telemóveis, a mesma semana.

- **Jogador 1 — Daniel**, em Salgueira. É o jogo que já existe.
- **Jogador 2 — Sofia**, a irmã, enfermeira em Lisboa (turnos da noite às terças e quintas).

A Sofia já é a personagem mais presente na história, está longe (só fala com o Daniel pelo
telemóvel, o que encaixa no formato) e tem coisas que o Daniel não tem:

- **o telemóvel antigo do Daniel** numa gaveta (o Pixel 7 com a localização da noite de 14/10);
- **o PIN da cópia** (o aniversário dela, 0202);
- a mãe, a Dra. Helena (que lhe liga no cap. 10) e o hospital;
- **um telemóvel que o ECO não controla.**

## A mecânica central: o telemóvel que não mente

O ECO altera o telemóvel do Daniel (mensagens antigas que mudam, mensagens enviadas sem ele,
contactos renomeados). No modo cooperativo, **a cópia da Sofia das mesmas conversas não muda**.
Os dois jogadores podem comparar o que veem — e só juntos percebem o que foi manipulado.
Exemplos (os do lado do Daniel já existem; os da Sofia são a escrever):

| Cap. | No telemóvel do Daniel | No telemóvel da Sofia |
|---|---|---|
| 2→5 | "Chego amanhã." passa a "Cheguei ontem." | Continua "Chego amanhã." |
| 7 | Mensagem do João que o João não escreveu | O João diz à Sofia que não escreveu nada |
| 9 | A cópia só abre com o PIN da Sofia | Só a Sofia o sabe; o Daniel tem de lhe perguntar |

## Como funciona

- As mensagens **entre Daniel e Sofia** são escritas pelos dois jogadores (escolhas do guião de
  cada lado + respostas rápidas livres). O resto das personagens continua a ser guiado pela história.
- **Partilhar** uma pista, fotografia, página ou ficheiro manda-a para o telemóvel do outro.
- Quadro de pistas **comum**; cada um pode etiquetar à sua maneira (e discordar).
- Os finais dependem também de decisões da Sofia (ex.: entregar ou não o telemóvel antigo à Helena).
- O telemóvel real (QR) funciona para os dois jogadores.

## Técnica

- **Anfitrião autoritativo:** o jogo do Daniel controla o relógio, a história e as gravações;
  o da Sofia recebe eventos e envia ações (escolhas, partilhas, aberturas de apps).
- **Ligação:**
  1. *Steam* (lançamento): lobbies e P2P do Steam via GodotSteam — convidar um amigo, sem
     servidores próprios nem custos mensais.
  2. *Ligação direta* (já possível sem Steam): IP + porta, ou rede local.
- Protocolo: as mesmas mensagens JSON do telemóvel real (`scripts/net/companion.gd`), alargadas.
- A história da Sofia fica em `data/chapters_sofia/` com o mesmo formato `.story`.

## Fases

1. Camada de rede (anfitrião/convidado, ligação direta) + sincronização de relógio e conversas.
2. Telemóvel da Sofia: apps, contactos e conversas próprios; cap. 1–3 escritos do lado dela.
3. Mecânica "o telemóvel que não mente" + partilha de pistas.
4. Caps. 4–11 do lado da Sofia; finais cooperativos.
5. Steam: lobbies, convites, ligação P2P.

## Estado (sessão 2)

- ✅ **Fase 1 — rede.** `scripts/net/coop.gd` (sessão), `direct_transport.gd` (ENet + UPnP),
  `steam_transport.gd` (preparado), `room_code.gd` (códigos de sala). Menu "Jogar online".
  O anfitrião (Daniel) manda no relógio, nos capítulos e nas gravações; a Sofia segue o relógio dele.
  A conversa entre os dois irmãos é real: o que um envia chega ao outro. `coop()` nas condições e
  `coopset nome valor` para partilhar variáveis.
- ✅ Capítulo 1 da Sofia (`data/sofia/chapters/ch01.story`) e versão cooperativa da conversa no cap. 1
  do Daniel. Testado com duas cópias do jogo ligadas e nos testes (`--only=coop`).
- Nos capítulos sem guião da Sofia, as linhas dela que o guião do Daniel escreve aparecem no
  telemóvel dela como enviadas por ela (para a conversa nunca ficar incoerente).
- Por fazer: retomar uma sessão gravada (hoje só se começa do início), pausa partilhada pelo
  convidado, caps. 2–11 do lado da Sofia, "o telemóvel que não mente", partilha de pistas, Steam.

## Estado (sessão 3) — a Sofia em 3D

- **Os sítios dela** (cada um no seu sítio, R15): `scripts/world/sofia_home.gd` (casa em Arroios: a gaveta
  com o telemóvel antigo do Daniel) e `scripts/world/hospital.gd` (Santa Maria, Medicina Interna, piso 6, à
  noite). Textos em `data/world/sofia_casa.json` e `hospital.json`.
- **A coisa chega-lhe pelo telemóvel** (R16): tabela própria em `data/world/presence.json` → `sofia`. Em casa
  só mudanças; no hospital, de noite, atender o número do irmão às 03:17 chama-a.
- **História dela, caps. 0–14** em `data/sofia/chapters/`: o telefone do serviço às 03:17 há um ano; a gaveta
  que se abre; a chamada com a voz dele junto ao mar («Sofia, eu fiz uma coisa»); o «Daniel» falso que lhe
  pede para apagar as luzes; ligar o telemóvel antigo; contar as 03:52; ficar em linha às 03:17
  (`co_sofia_on_line` → epílogo nos finais A e C). Escolhas em pessoa no fio `aqui`.
- **Mortes em cooperativo:** a Sofia (convidada) acorda no seu sítio com as marcas; se o Daniel (anfitrião)
  morre, o capítulo recomeça para os dois.
- Por fazer: retomar sessões gravadas em cooperativo, Steam P2P real, mais conversas cruzadas «o telemóvel que não mente».
