# =====================================================================
# SOFIA — CAPÍTULO 10 · seg 12 → ter 13, 22:00 → 03:30 · Lisboa
# Ligar o telemóvel antigo é o momento mais perigoso dela. E, se o irmão
# lhe contar a denúncia, conta-lhe a chamada das 03:52.
# =====================================================================
@chapter ch10
@title A Verdade
@start 2026-10-12 22:00

@beat setup
set chapter_n=10
ambient night
location sofia_casa
battery 61
wait 2
world spawn sofa
@end

@beat power_on
@when at("23:10")
world think O telemóvel antigo, em cima da mesa. Para mandar a cópia tenho de o ligar.
choice aqui c10s_power
  > [Ligar o telemóvel antigo] | set sofia_phone_on=true
  > [Ainda não] | set s10_waited=true
end
if flag("sofia_phone_on")
  sound boot
  wait 4
  world think O ecrã acende. 14 de outubro de 2025. 03:52. A última chamada: Sofia. Duração: 11 minutos.
  world presence near 60
  coopset co_sofia_phone_on true
endif
@end

@beat confess_0352
@when at("01:30") and (flag("co_daniel_confessed") or flag("sofia_phone_on"))
choice aqui c10s_0352
  > [Contar ao Daniel a chamada das 03:52] | set s_told_0352=true
  > [Ainda não] | set s_kept_0352=true
end
if flag("s_told_0352")
  coopset co_sofia_told_0352 true
  world think Escrevi-lhe tudo. Que me ligou. Que disse «eu fiz uma coisa». Que eu disse à polícia que não. Carreguei em enviar antes de me arrepender.
endif
@end

@beat water
@when at("03:17")
world sound water 6.1 7.3 -6 0.8
world think Água a correr na casa de banho. Fechei a torneira antes de me deitar.
world presence stalk 40
@end
