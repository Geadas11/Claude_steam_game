# =====================================================================
# SOFIA — CAPÍTULO 5 · sáb 10 → dom 11, 22:30 → 04:10 · Santa Maria
# Turno da noite. Às 03:17 uma chamada do número do irmão: a voz dele,
# junto ao mar. Atender no escuro chama a coisa (R16).
# =====================================================================
@chapter ch05
@title O Telefone Começa a Mudar
@start 2026-10-10 22:30

@beat setup
set chapter_n=5
ambient hum
location hospital
battery 71
wait 2
world spawn posto
world lights on
@end

@beat board
@when at("01:10")
world think Fui ao quadro ver a medicação das duas. Na linha da 604 alguém escreveu um nome que não temos.
@end

@beat lights_low
@when at("02:50")
world lights off corredor_c
wait 4
world lights off corredor_b
world think Os tubos do fundo apagaram-se. A chefe diz que é o quadro elétrico. Diz isso desde 2019.
@end

@beat brother_call
@when at("03:17")
call daniel id=c5s_daniel ring=24
  [sfx sea]
  - (o mar)
  wait 2
  daniel: Sofia. | 1.6
  wait 2.5
  daniel: Sofia, eu fiz uma coisa. | 2.4
  [sfx breath]
  wait 3
  - (só o mar)
end
if answered("c5s_daniel")
  set s5_answered=true
  world presence hunt 35
  wait 6
  world think Era a voz dele. Do ano passado. Exatamente a mesma frase. O Daniel está a dormir em Salgueira. Não está?
else
  wait 4
  world think Chamada perdida: Daniel. 03:17. Ele não me ligou. Sei que não me ligou.
endif
coopset co_sofia_317_call true
@end
