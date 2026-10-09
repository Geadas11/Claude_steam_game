# UNKNOWN

## Metadata

- **Title**: UNKNOWN (antes «Ainda Estás Acordado?»)
- **Genre**: Terror psicológico / ficção interativa em primeira pessoa (3D realista) com telemóvel
- **Target Medium**: Custom Engine — Godot 4.3 (motor narrativo próprio: `data/chapters/*.story`)
- **Target Platform**: PC (Steam)
- **Language**: Português europeu
- **Scope**: jogo completo, mais de 10 horas
- **Rating**: mature
- **Status**: pre-production (história a reescrever pelo autor)
- **Created**: 2026-10-09
- **Last Modified**: 2026-10-09

## Current Phase

Concept Discovery

## O que o autor já decidiu (fora da história)

- Jogo 3D realista na primeira pessoa, «tipo Phasmophobia».
- Tem de haver perigo real: algo que mata, terror, sustos e tensão.
- O telemóvel é a ponte da história: o do jogo (na mão da personagem) ou o telemóvel real do jogador.
- Cooperativo: cada jogador no seu lugar; as pistas de um podem não fazer sentido para o outro.
- Personagens jogáveis atuais: Daniel e Sofia (por confirmar no novo Story Bible).

## Material existente

A versão atual do jogo já tem uma história completa (11 capítulos, 5 finais):
`docs/STORY_BIBLE.md` e `data/chapters/*.story` na raiz do repositório.
**Ainda não é canon deste Story Bible** — o autor decide se parte dela, se a reescreve ou se começa do zero.

## Design Pillars

1. _pending
2. _pending
3. _pending

## Elevator Pitch

_pending

## Inspirations

| Work | What We Borrow | What We Subvert |
|------|----------------|-----------------|
| Phasmophobia | perigo real, investigação em primeira pessoa, tensão | _pending |
| _pending | | |

## Scope Boundaries

- **Ending Count**: _pending
- **Content Warnings**: _pending

## Narrative Structure

- **Type**: _pending
- **Failure Design**: die-and-retry (há morte; regras por definir)

## Technical Notes

- **State Tracking**: variáveis e flags do motor (`set`, `flag()`, `vs()` nos `.story`).
- Exportação para o jogo: `data/chapters/*.story` (formato em `docs/STORY_FORMAT.md`), não Dialogic.
