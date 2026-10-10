# =====================================================================
# SOFIA — CAPÍTULO 11 · ter 13 out, 14:00 → 19:00 · Lisboa
# O irmão está na clínica. A Sofia segue a localização dele. A Helena
# liga-lhe a pedir que o convença a ficar.
# =====================================================================
@chapter ch11
@title A Clínica
@start 2026-10-13 14:00

@beat setup
set chapter_n=11
rate 2
ambient room
location sofia_casa
battery 84
wait 2
world spawn sofa
@end

@beat helena_calls
@when at("18:20")
call helena id=c11s_helena ring=18
  helena: Sofia? Fala a Dra. Helena Sousa, médica do seu irmão. | 3
  helena: O Daniel está aqui na clínica. Está em risco. Preciso que o convença a ficar uns dias. | 4.5
  wait 1
  helena: Ele confia em si. Diga-lhe que é para o bem dele. | 3
end
wait 4
world think Nunca dei o meu número à médica dele. Nunca.
coopset co_helena_called_sofia true
@end
