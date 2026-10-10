# =====================================================================
# SOFIA — CAPÍTULO 4 · sáb 10 out, 10:15 → 19:00 · Lisboa
# Dia. A mãe, a Patrícia, o irmão a investigar. A gaveta está aberta.
# =====================================================================
@chapter ch04
@title Investigação
@start 2026-10-10 10:15

@beat setup
set chapter_n=4
rate 2
ambient room
location sofia_casa
battery 88
wait 2
world spawn cama
@end

@beat drawer_open_day
@when at("11:00")
world think A gaveta está entreaberta. Eu fecho sempre a gaveta.
@end

@beat patricia4
@when at("14:20")
patricia> Trocaste o turno de terça? A chefe diz que pediste o dia 14 e depois desmarcaste
patricia> Eu não te deixo vir trabalhar no dia 14 Sofia. Já falámos disto
@end

@beat patricia4_reply
@when beat("patricia4") and read("patricia")
wait 1
choice patricia c4s_shift
  > Prefiro estar a trabalhar do que sozinha em casa. | set s_works_14=true
  > Tens razão. Vou pedir outra vez a troca. | set s_works_14=false
end
wait 15
if flag("s_works_14")
  patricia> Então fico contigo. Eu também não gosto de outubro
else
  patricia> Boa. Vai ter com ele. Lisboa–Faro são três horas
endif
@end
