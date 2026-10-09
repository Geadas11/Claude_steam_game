# Guia de teste com jogadores

O jogo foi testado automaticamente (5 jogadas completas, uma por final, varrimento da UI,
testes de resistência em tempo real por capítulo). O que falta é aquilo que só uma pessoa
consegue dizer: se tem ritmo, se assusta, se se percebe.

## Preparação

- Build: `godot --headless --export-release "Windows Desktop" builds/windows/UNKNOWN.exe`
  (ou `"Linux"`). Ou correr do editor: `godot --path .`
- Jogar **à noite, com auscultadores**, sem guia. Quem observa não ajuda.
- Gravações em `user://saves/`, perfil (conquistas, finais) em `user://profile.json`.
  Para recomeçar do zero, apagar a pasta `UNKNOWN` em `~/.local/share/` (Linux)
  ou `%APPDATA%` (Windows).

## Sessões sugeridas

| Sessão | Capítulos | Duração aprox. | Foco |
|---|---|---|---|
| 1 | 1–3 | 60–80 min | Gancho, clareza, primeira chamada |
| 2 | 4–6 | 70–90 min | Investigação livre, terror do cap. 5 |
| 3 | 7–9 | 70–90 min | Confiança, sistema, reconstrução |
| 4 | 10–11 | 45–60 min | Consequências, final |

## O que observar (sem perguntar)

- Onde a pessoa **fica parada** mais de 1 minuto sem saber o que fazer.
- Que apps **nunca abre** (Mapas? Ficheiros? Notas → Pistas?).
- Se **lê** os avisos curtos no fundo do ecrã ("Nova pista: …").
- Reações físicas: afastar-se do ecrã, rir, tirar os auscultadores.
- Se volta a abrir fotografias para as **ampliar** (há pormenores escondidos).

## Perguntas no fim de cada sessão

1. O que achas que aconteceu à Inês? Quem é que te escreve?
2. Houve algum momento em que não sabias o que fazer? Quando?
3. Qual foi o momento mais desconfortável? Houve algum que pareceu barato?
4. Algum diálogo soou falso? Alguma personagem pareceu igual a outra?
5. O tempo dentro do jogo passou demasiado devagar ou depressa?
6. Percebeste que as tuas respostas tinham consequências? Qual te pesou mais?
7. (Sessão 4) O final fez sentido? Querias jogar outra vez para ver outro?

## Pontos de risco conhecidos

- **Cap. 3:** o jogador tem de descobrir sozinho de quem é o número (há 3 empurrões: 00:05, 00:40, 01:30).
- **Cap. 5:** o PIN muda para 1410 depois do reinício — quem não ligou a data ao PIN fica preso?
- **Cap. 8:** "toca 7 vezes no número da versão" — descobrem as opções de programador?
- **Cap. 9:** a palavra-passe da cópia (0202) e a reconstrução: as opções certas só aparecem com
  as pistas certas. Muitos "???" são frustrantes ou motivadores?
- **Cap. 10:** abrir o livro ou deixá-lo — percebe-se que é a decisão mais importante do jogo?
- **Ritmo dos capítulos diurnos** (`rate 2`): demasiado lento? O relógio acelera ×6 após
  25 s sem input, e há a opção "Velocidade do relógio" nas Definições.

## Registo

Para cada sessão: data, build (`git rev-parse --short HEAD`), capítulos, duração real,
final obtido, respostas às perguntas, e momentos (hora do jogo + o que aconteceu).
