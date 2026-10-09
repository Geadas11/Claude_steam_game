# Branch Outline

## Branch Philosophy
Profundo e estreito: uma linha principal de 15 capítulos; as escolhas mudam quem fica do lado do Daniel,
que provas ele tem e qual dos 5 finais chega. A história atual do jogo já tem as escolhas por capítulo
(`data/chapters/*.story`); mantêm-se até serem revistas cena a cena.

## World State Design

| Variable | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| trust_vasco | int | 0 | Confiança no Vasco (final B se ≥ 2) |
| card_found | bool | false | Cartão encontrado (Cap. 8) |
| recording | bool | false | Gravação das 03:09 (Cap. 10) |
| night_rebuilt | bool | false | Noite reconstruída corretamente |
| eco_fragments | int | 0 | Fragmentos para o final E (3) |
| deaths_ch | int | 0 | Mortes no capítulo atual (marcas do recomeço) |
| marks | list | [] | Marcas deixadas pelos recomeços (para «já falámos sobre isto») |

## Endings
Ver `story/ending_design.md`.
