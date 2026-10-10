# =====================================================================
# SOFIA — CAPÍTULO 14 · qua 14 out, 02:50 → 03:17 · Santa Maria
# Às 03:17 está (ou não) em linha com o irmão. O telefone do serviço toca.
# =====================================================================
@chapter ch14
@title Final
@start 2026-10-14 02:50

@beat setup
set chapter_n=14
ambient hum
location hospital
battery 31
wait 2
world spawn posto
world lights off corredor_c
@end

@beat stay_on_line
@when at("03:05")
choice aqui c14s_line
  > [Ligar ao Daniel e ficar em linha até às três e dezassete] | set s_on_line=true
  > [Não ligar. Ele pediu-me para não ligar] | set s_on_line=false
end
if flag("s_on_line")
  coopset co_sofia_on_line true
  world think Liguei. Ouço o mar do lado dele. Não digo nada. Ele também não. Estamos os dois aqui.
endif
@end

@beat ward_phone
@when at("03:17")
set s_ward_phone=true
world change telefone
world presence hunt 30
wait 4
world think O telefone do serviço outra vez. Não atendo. Este ano não atendo.
@end
