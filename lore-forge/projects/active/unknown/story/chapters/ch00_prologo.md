# Prólogo — A Noite

> **Proposta para o autor aprovar.** Cenas e diálogo completos.
> *13 → 14 de outubro de 2025, 02:30 → 03:17 · Cais Velho e a estrada · ~30 min · sem perigo*

**O que este capítulo faz:** abre o jogo no fim. Mostra a versão que o Daniel guarda daquela noite,
e planta a dúvida antes de o jogador saber sequer quem é a Inês. Ensina a ouvir: aqui não há coisa,
só o mar, a chuva e passos — e o jogador vai aprender que os sons importam.

**Regra de memória (só neste capítulo):** a memória do Daniel não é fiável. A cara da Inês nunca se vê
(capuz, cabelo molhado, contraluz do candeeiro do cais). Algumas falas dela aparecem escritas no ecrã
um instante *antes* de ela as dizer. Ninguém comenta isto.

---

## Cena P.1 — O caminho
*02:30 → 02:38 · Estrada do cais, chuva miúda*

- **Função:** preparação. Tensão baixa, a subir.
- **Entrada:** o Daniel caminha com o telemóvel antigo na mão. O jogador aprende a andar.
- **Saída:** chega ao cais e vê-a.
- **Ambiente:** estrada sem passeio, um candeeiro de sódio a cada cinquenta metros, o mar à esquerda,
  um café fechado com uma câmara por cima da porta (planta P-B — ninguém repara).

**Telemóvel (ecrã do Daniel)**
- 02:31 — Inês: `estás a chegar`
- 02:31 — Inês: `não venhas se for para me dizer outra vez que é perigoso`
- *(o jogador pode responder ou não — só muda uma fala da cena seguinte)*
  - > `Estou a chegar.` *(set p_replied=true)*
  - > `[Não responder]`

[Ação: perto do cais, um carro passa devagar na estrada de cima, de luzes apagadas. Some-se.
Sem som de motor — só pneus na água. *(planta: o Audi do Vasco, 03:04 na câmara; aqui 02:36,
contradição de memória intencional)*]

---

## Cena P.2 — O cais
*02:38 → 03:06 · Cais Velho, ao fundo, junto às escadas para a água*

- **Função:** revelação parcial + escolha de tom. Tensão média.
- **Entrada:** ela está de casaco vermelho, de costas para o mar.
- **Saída:** ela dá-lhe o cartão; ele vai-se embora.
- **Momento irreversível:** a notificação do Vasco acende o ecrã na mão dele, e ela vê.

**Inês** [state: nervosa, a fingir calma]
*{subtext: ainda confia nele e odeia precisar disso}*
ouve. não tenho muito tempo

**Inês** [state: seca]
se vieste para me dizer que é perigoso, já sei. às 10h falo com a Clara e acabou

**Daniel — escolha de tom** *(guardada para ecoar no Cap. 13 e no final E)*
- > `Só quero que tenhas cuidado.` *(set p_tone=care)*
  **Inês:** cuidado é o que eles contam que eu tenha
- > `Isto vai destruir-te. Há outras maneiras.` *(set p_tone=fear)*
  **Inês:** dizes isso como se já soubesses qual
- > `[Ficar calado]` *(set p_tone=silent)*
  **Inês:** pois. é isso que tu fazes

[Ação: o telemóvel do Daniel vibra na mão dele. O ecrã acende-se. Ela olha para baixo antes de ele
conseguir esconder.]

**Ecrã do Daniel:** `Vasco Pimentel — Obrigado, meu caro. Eu trato disto. Fica tranquilo.`

**Inês** [state: imóvel; a voz baixa muito]
*{subtext: percebe tudo de uma vez}*
eu trato disto

**Inês**
foste tu

**Daniel — escolha** *(set p_admit)*
- > `Eu só queria que ele falasse contigo antes.` *(set p_admit=excuse)*
- > `Desculpa.` *(set p_admit=sorry)*
- > `[Não dizer nada]` *(set p_admit=silent)*

**Inês** [state: magoada, depois prática]
*{subtext: não tem tempo para o ódio; precisa que alguém guarde as provas}*
— *(se p_admit=excuse)* claro. antes. tu fazes sempre tudo antes, para não teres de estar lá depois
— *(se p_admit=sorry)* não peças desculpa. ainda não
— *(se p_admit=silent)* nem isso, daniel

[Ação: ela tira do bolso do casaco um cartão de memória pequeno e uma chave com um porta-chaves de
madeira gasto. Estende a mão. Fica à espera até ele aceitar — o jogador tem de carregar em E.]

**Inês** [state: firme]
o cartão tem tudo. a chave é da livraria, a carla deu-ma para eu ir ler de manhã

**Inês**
se me acontecer alguma coisa, já sabes

**Daniel**
*{subtext: quer que ela o mande embora para não ter de decidir}*
— *(se p_replied=true)* Vim porque disse que vinha.
— *(senão)* Eu vim.

**Inês** [state: cansada]
vai-te embora, daniel. vai para casa

[Ação: ele vira costas. O jogador controla-o de novo. Atrás, na madeira do cais, ouvem-se passos
que não são os dela — mais pesados. Se o jogador se virar, só a vê a ela, de costas, a olhar o mar.]

---

## Cena P.3 — A estrada
*03:06 → 03:17 · Estrada do cais em direção à EN125*

- **Função:** escalada. Tensão alta.
- **Entrada:** sozinho, a afastar-se.
- **Saída:** o grito às 03:17; corre de volta; negro antes de chegar.

**Telemóvel**
- 03:12 — Inês: `daniel volta`

[Ação: o jogador pode escrever. O telemóvel escreve por ele `Vou já` — o dedo do Daniel fica em cima
do botão de enviar. O jogo não deixa enviar. Durante quatro minutos de relógio do jogo (acelerados),
ele fica parado na berma. *(planta P-A: a captura das 03:13)*]

- 03:15 — Inês: `ele está aqui`

[Ação: um carro sem luzes passa por ele, a descer para o cais. *(é o segundo carro sem luzes desta
memória — a memória não bate certo; ninguém comenta)*]

[Ação: 03:17. Um grito, longe, cortado pelo vento. O jogador recupera o controlo e corre de volta
pela estrada. A chuva aumenta. A meio do caminho, o som do mar cresce até tapar tudo.]

[Ação: negro antes de ele chegar. Silêncio total durante dois segundos.]

**Texto no ecrã, branco sobre preto:**
> É isto que tu lembras.

[Corte para o Capítulo 1: quinta-feira, 8 de outubro de 2026, 21:30.]

---

## Notas para o jogo

- **Variáveis:** `p_replied`, `p_tone`, `p_admit`. Reaparecem: Cap. 13 (o caminho repete-se e o
  Daniel diz em voz alta a fala que escolheu), final E (a Inês do ECO responde à mesma escolha).
- **Sítios 3D:** estrada do cais + Cais Velho (fase 4). Até existirem, o prólogo pode ser só
  telemóvel + som sobre ecrã escuro (versão provisória).
- **Contradições intencionais novas:** dois carros sem luzes (02:36 e ~03:16) na memória do Daniel;
  o «Vou já» escrito pelo telemóvel e não por ele.
- **Valida contra:** R1 (a coisa não aparece), R13 (o telemóvel conduz a revelação), canon (02:38,
  03:06, 03:12, 03:13, 03:15, 03:17).
