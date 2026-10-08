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
