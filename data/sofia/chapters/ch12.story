# =====================================================================
# SOFIA — CAPÍTULO 12 · ter 13 out, 19:00 → 22:30 · Lisboa → Santa Maria
# Véspera. Vai para o turno da noite (R15: fica no seu sítio). No posto,
# ninguém atende o telefone. Conversas ficam «visto» e mais nada.
# =====================================================================
@chapter ch12
@title Consequências
@start 2026-10-13 19:00

@beat setup
set chapter_n=12
ambient room
location sofia_casa
battery 58
wait 2
world spawn entrada
@end

@beat to_shift
@when at("21:30")
location hospital
wait 2
world spawn posto
world lights on
world think Troquei o turno e destroquei. Estou aqui. Se ele ligar, estou acordada.
@end

@beat nobody
@when at("22:10")
patricia> {silent} .
wait 30
world think A Patrícia mandou um ponto e deixou de responder. Visto às 22:10.
@end
