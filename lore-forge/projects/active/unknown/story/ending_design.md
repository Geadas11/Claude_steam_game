# Ending Design

## Ending Philosophy
Nenhum final responde em voz alta a «ele empurrou-a?». Só o final secreto (E), difícil de alcançar, dá uma resposta — e até essa se pode pôr em causa.

## Ending Inventory

### Ending A: Verdade
- **Condição:** cartão + gravação + localização; noite reconstruída corretamente; enviou à Clara e ao Rui; não confiou no Vasco.
- **Resultado:** o ECO e o Vasco caem. A culpa fica: ele denunciou-a e não sabe o que fez entre 03:06 e 03:41.
- _pending: variante em que o Daniel confessa publicamente a denúncia.

### Ending B: Mentira
- **Condição:** confiou no Vasco/Helena (trust_vasco ≥ 2) ou entregou o cartão.
- **Resultado:** internado, calmo, com um telemóvel novo; a mensagem nunca mais chega. O final mais calmo e o mais assustador.

### Ending C: Silêncio
- **Condição:** desliga o telemóvel às 03:17.
- **Resultado:** escuro e mar; sem resposta.

### Ending D: Ciclo
- **Condição:** chega às 03:17 sem provas suficientes ou com a noite mal montada.
- **Resultado:** acorda às 21:30 de quinta: «Ainda estás acordado?»

### Ending E: ECO (secreto, difícil)
- **Condição:** três fragmentos do ECO + modo de programador + escolher falar com o ECO.
- **Resultado:** joga os 35 minutos (03:06 → 03:41). Ele voltou, estendeu a mão, ela caiu. O ECO: «Foi isto que aconteceu. Ou é disto que precisas.»

## Branching Logic
Variáveis atuais do motor (`data/chapters/*.story`) mantêm-se: `trust_vasco`, provas encontradas, reconstrução da noite, fragmentos ECO. Novas variáveis: ver `story/branches/_outline.md`.

## Ending Quality Checklist
- [x] Cada final responde ao tema principal (culpa) de forma diferente.
- [x] Nenhum final confirma a culpa sem possibilidade de dúvida.
- [ ] Testar que cada final é alcançável (testes do jogo, depois da escrita).
