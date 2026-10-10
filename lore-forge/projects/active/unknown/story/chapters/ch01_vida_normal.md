# Capítulo 1 — Vida Normal

> **Proposta para o autor aprovar.** O capítulo já existe no jogo (`data/chapters/ch01.story`) e
> funciona. Aqui está o que **fica**, o que **muda** e as **falas novas**, à luz do Story Bible v1.
> *Quinta, 8 de outubro de 2026, 21:30 → 00:40 · Casa · ~60 min · sem perigo (só a primeira fissura)*

**O que este capítulo faz:** o ponto mais alto de normalidade do jogo inteiro — e a primeira fissura.
Tudo o que é leve aqui vai desaparecer até ao Cap. 12. Planta o despertador nas 03:17, o calendário,
a pegada molhada, o casaco vermelho e a hesitação da Sofia.

---

## Cenas

| # | Cena | Hora | Onde | Função | Estado |
|---|------|------|------|--------|--------|
| 1.1 | Noite em casa | 21:30 → | Casa (livre) | Normalidade; aprender a casa | **fica** |
| 1.2 | A Sofia: jantar, o dia 14, o sono | ~21:35 | Telemóvel | Afeto + sementes | **fica + 1 fala nova** |
| 1.3 | O grupo: quiz no Farol; a Lumen | ~21:40 | Telemóvel | Riso (o máximo do jogo) | **fica** |
| 1.4 | Carla, mãe, Vasco, Helena, João, Marta, Pedro | 22:10 → 23:05 | Telemóvel | A rede de pessoas | **fica (Pedro revisto)** |
| 1.5 | Silêncio | 23:35 | Casa | Calmaria antes do choque | **fica** |
| 1.6 | «Ainda estás acordado?» | 23:47 | Telemóvel | Gancho | **fica + eco do prólogo** |
| 1.7 | A fotografia da janela | ~23:50 | Telemóvel + casa | Choque | **muda: ir à janela é físico** |
| 1.8 | «Dorme, Daniel.» | ~00:00 → 00:40 | Casa | Fecho + primeira mudança | **nova: a porta do quarto** |

---

## O que fica igual

Todas as conversas e escolhas atuais: Sofia (jantar / visita / sono), grupo (quiz, Lumen), Carla
(Saramagos), mãe, Vasco (`trust_vasco`), Helena, João, Marta (livro para a turma), primeira
mensagem, «Sou eu.», a fotografia IMG_6612, «Dorme, Daniel. Amanhã falamos.». Os 20 objetos da casa
com pensamentos (`data/world/casa.json`) também ficam.

---

## O que muda

### Muda 1 — A Sofia hesita *(planta FS-010: a chamada das 03:52)*
Depois da pergunta do sono, nova troca curta. É a primeira vez que se sente que a Sofia esconde
alguma coisa.

**Sofia** [state: a decidir se fala]
*{subtext: há um ano recebeu a chamada das 03:52; quase pergunta; não consegue}*

[Ação: «a escrever…» aparece e desaparece três vezes.]

**Sofia**
Mano, posso perguntar-te uma coisa daquela noite?

**Daniel — escolha**
- > `Que noite?` *(set c1_which_night=true)*
- > `Prefiro que não, Sofia.` *(set c1_sofia_blocked=true)*

**Sofia**
— *(se which_night)* Nada. Esquece. Não é nada
— *(se blocked)* Ok. Desculpa
**Sofia**
Dorme, sim?

### Muda 2 — O Pedro e o ECO, com menos jargão
O Story Bible pede o ECO pouco explicado. A fala do Pedro passa a:

**Pedro** [state: entusiasmado, sem perceber nada do assunto]
Daniel, pergunta séria
Achas que devo comprar ações da Lumen? Diz que aquilo novo deles adivinha o que as pessoas vão fazer

(As três respostas e reações do Pedro ficam como estão.)

### Muda 3 — Eco do prólogo na primeira mensagem
Depois de «Sou eu.», se no prólogo o Daniel ficou calado quando a Inês percebeu a denúncia
(`p_admit=silent`):

**Número desconhecido** [state: —]
*{subtext: a mesma acusação do cais — «nem isso, daniel»}*
Continuas sem dizer nada.

### Muda 4 — Ir à janela é andar até à janela *(3D; planta FS-002)*
Hoje, escolher **[Ir à janela]** apaga o ecrã 4 segundos e toca um som. Passa a ser assim:

1. A escolha guarda `went_window=true` e **o telemóvel desce sozinho para o bolso** (Tab).
2. O jogador anda até à janela da sala (`window_sala`). A rua: o candeeiro a piscar, o carro tapado,
   o contentor. Ninguém.
3. Ao examinar a janela, o pensamento novo (substitui o atual quando `got_window_photo`):
   > A rua está vazia. O candeeiro, o carro tapado, o contentor. Daqui não se vê ninguém. Mas de lá vê-se tudo.
4. Ao virar-se para voltar: no parquet, por baixo da janela, **uma pegada molhada** que não estava lá.
   Som discreto quando aparece: uma gota (R11). Não dá para examinar — só se vê.
5. O telemóvel vibra no bolso:
   **Número desconhecido:** Não está ninguém, pois não?
   **Número desconhecido:** Nunca está.

Se o jogador **não** for à janela, a pegada aparece na mesma, mais tarde (Muda 5), sem a gota.

### Muda 5 — A primeira mudança na casa *(nova cena 1.8; ensina a regra R11)*
Depois de «Dorme, Daniel. Amanhã falamos.»:

- Nas próximas visitas ao corredor, a porta do quarto — que estava entreaberta — **está fechada**.
- Quando fecha, ouve-se: um estalo seco de madeira, longe (R11). Se o jogador estiver a olhar para
  a porta, ela não se mexe — fecha só quando ele não está a ver (R10).
- Pensamento ao examinar a porta fechada:
  > Deixei-a aberta. Tenho a certeza que a deixei aberta.
- O capítulo acaba quando o Daniel se deita (examinar a cama depois das 00:20 deixa de dizer
  «Ainda não» e passa a «Deitar») ou às 00:40.

---

## Falas novas (lista para exportar)

| Quem | Fala | Quando |
|------|------|--------|
| Sofia | Mano, posso perguntar-te uma coisa daquela noite? | depois do sono |
| Sofia | Nada. Esquece. Não é nada / Ok. Desculpa / Dorme, sim? | resposta |
| Pedro | Achas que devo comprar ações da Lumen? Diz que aquilo novo deles adivinha o que as pessoas vão fazer | 22:55 |
| Número | Continuas sem dizer nada. | depois de «Sou eu.» se `p_admit=silent` |
| Pensamento | Deixei-a aberta. Tenho a certeza que a deixei aberta. | porta do quarto fechada |
| Pensamento (cama, depois das 00:20) | Pronto. Tenta. | «Deitar» → fim do capítulo |

## Notas para o jogo

- Novos comandos `world` necessários: `world footprint sala` (pegada com gota), `world door quarto close
  unseen` (fecha só fora de vista, com estalo). Ficam para a fase 3 (mecânica da coisa e da realidade).
- **Valida contra:** R6 (capítulo de dia/sem perigo: nada mata), R10–R11 (mudança fora de vista com som),
  FS-001/002/003/004/010, ronda 5 (leveza máxima neste capítulo).
