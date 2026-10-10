# =====================================================================
# SOFIA — CAPÍTULO 6 · dom 11 out, 11:00 → 20:30 · Lisboa
# Dia de folga, em casa. O irmão descobre que conhecia bem a Inês.
# A Sofia lembra-se de onde conhece o casaco vermelho.
# =====================================================================
@chapter ch06
@title A Investigação Torna-se Pessoal
@start 2026-10-11 11:00

@beat setup
set chapter_n=6
rate 2
ambient room
location sofia_casa
battery 92
wait 2
world spawn sofa
@end

@beat red_coat
@when at("15:00")
world think O casaco vermelho. Lembrei-me. Estava no banco de trás do carro do Daniel, no Natal de 2024. Ele disse que era de uma colega.
set s_remembers_coat=true
coopset co_sofia_coat true
@end

@beat mae6
@when at("18:15")
mae> o teu irmao nao me atende
mae> liga-lhe tu. a ti ele atende
@end
