# UNKNOWN

## Metadata

- **Title**: UNKNOWN (antes «Ainda Estás Acordado?»)
- **Genre**: Terror psicológico / ficção interativa em primeira pessoa (3D realista) com telemóvel
- **Target Medium**: Custom Engine — Godot 4.3 (motor narrativo próprio: `data/chapters/*.story`)
- **Target Platform**: PC (Steam)
- **Language**: Português europeu
- **Scope**: jogo completo, mais de 10 horas
- **Rating**: mature
- **Status**: pre-production — Story Bible v1 construído
- **Created**: 2026-10-09
- **Last Modified**: 2026-10-09

## Current Phase

Character Discovery (Concept Discovery concluída a 2026-10-09)

## O que o autor já decidiu (fora da história)

- Jogo 3D realista na primeira pessoa, «tipo Phasmophobia».
- Tem de haver perigo real: algo que mata, terror, sustos e tensão.
- O telemóvel é a ponte da história: o do jogo (na mão da personagem) ou o telemóvel real do jogador.
- Cooperativo: cada jogador no seu lugar; as pistas de um podem não fazer sentido para o outro.
- Personagens jogáveis atuais: Daniel e Sofia (por confirmar no novo Story Bible).

## Material existente

A versão atual do jogo já tem uma história completa (11 capítulos, 5 finais):
`docs/STORY_BIBLE.md` e `data/chapters/*.story` na raiz do repositório.
Escolha do autor: partir dela e melhorá-la. O que mudou está em `knowledge/canon.md` (Deprecated Canon).

## Design Pillars

1. Nunca ter a certeza (a realidade mente, com som discreto)
2. Perigo real (a coisa mata; morrer recomeça o capítulo com marcas)
3. O telemóvel é a ponte

## Elevator Pitch

Seis noites antes do aniversário da morte da Inês, o telemóvel do Daniel recebe uma mensagem do número dela. Uma conspiração verdadeira explica quase tudo — menos a coisa que o caça pela casa, e se foi ele que a empurrou.

## Inspirations

| Work | What We Borrow | What We Subvert |
|------|----------------|-----------------|
| Phasmophobia | perigo real, investigação em primeira pessoa, tensão | _pending |
| _pending | | |

## Scope Boundaries

- **Chapter Count**: 15 (prólogo + 14)
- **Ending Count**: 5 (um secreto)
- **Duração estimada**: 16–20 h (1.ª vez), 28–35 h (todos os finais)
- **Content Warnings**: morte, luto, culpa, perda de memória, vigilância, internamento psiquiátrico, sons súbitos

## Narrative Structure

- **Type**: _pending
- **Failure Design**: die-and-retry (há morte; regras por definir)

## Technical Notes

- **State Tracking**: variáveis e flags do motor (`set`, `flag()`, `vs()` nos `.story`).
- Exportação para o jogo: `data/chapters/*.story` (formato em `docs/STORY_FORMAT.md`), não Dialogic.
