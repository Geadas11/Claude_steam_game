# =====================================================================
# SOFIA — CAPÍTULO 7 · dom 11 → seg 12, 21:30 → 02:30 · Santa Maria
# O espelho do que acontece ao Daniel: à 01:30 o «Daniel» liga-lhe e
# pede-lhe que apague as luzes. Ele nunca lhe chamaria «Sofia Reis».
# =====================================================================
@chapter ch07
@title Confiança
@start 2026-10-11 21:30

@beat setup
set chapter_n=7
ambient hum
location hospital
battery 66
wait 2
world spawn posto
world lights on
@end

@beat fake_brother
@when at("01:30")
call daniel id=c7s_fake ring=20
  [sfx static]
  wait 1.5
  daniel: Sofia Reis? | 1.8
  wait 1
  daniel: Estás sozinha no piso? Apaga as luzes do corredor. Quero ver uma coisa. | 3.5
  [sfx breath]
  wait 2
  daniel: Porque é que não dizes nada? | 2.4
end
if answered("c7s_fake")
  world presence hunt 35
  wait 5
  world think Ele chama-me mana. Ou parva. Nunca me chamou Sofia Reis na vida.
  set s7_answered_fake=true
endif
coopset co_sofia_fake_call true
@end

@beat bed_wet
@when at("02:00")
world think A cama 3 da 603 outra vez molhada. Mudei os lençóis às onze.
@end
