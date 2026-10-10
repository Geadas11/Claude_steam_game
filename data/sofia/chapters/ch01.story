# =====================================================================
# SOFIA — CAPÍTULO 1 (modo cooperativo)
# quinta-feira, 8 de outubro de 2026, 21:30 → 00:40 · Lisboa
# A Sofia janta antes do turno da noite (23h, Santa Maria). Fala com o
# irmão — o outro jogador. A mãe preocupa-se. No fim, um número que ela
# não conhece sabe que o Daniel está acordado.
# =====================================================================
@chapter ch01
@title Vida Normal
@start 2026-10-08 21:30

@beat setup
ambient room
location sofia_casa
battery 81
set chapter_n=1
world phone on
wait 2
world spawn cozinha
@end

@beat to_shift
@when at("22:50")
location hospital
wait 2
world spawn pausa
world lights on
world think O cacifo, a farda, o cordão. Turno da noite. Quinta-feira.
@end

# ---------------------------------------------------------------- o Daniel (outro jogador)
@beat s_react
@when v("net_in") >= 1
wait 1
choice daniel c1s_react
  > Uau. Um adulto funcional. Estou orgulhosa | set s_dinner=ok
  > Daniel. Vai comer qualquer coisa. Agora. Eu espero | set s_dinner=push
  > Bolachas não são jantar. Vou contar à mãe | set s_dinner=mum
end
@end

@beat s_day14
@when beat("s_react")
wait 4
choice daniel c1s_day14
  > Ouve. Para a semana é dia 14. Faz um ano. Posso ir aí no fim de semana se quiseres
  > Para a semana é dia 14. Não vou fingir que não sei. Queres que vá aí?
end
@end

@beat s_visit_react
@when beat("s_day14") and v("net_in") >= 2
wait 1
choice daniel c1s_visit
  > Ok!! Vou ver os turnos. Sábado, talvez. Faço o arroz de pato que fingias não gostar | set s_going=true
  > "Estou bem, a sério" é exatamente o que dizes quando não estás. Mas ok. Não insisto. Hoje.
  > Não é drama, mano. Estiveste três semanas sem sair de casa.
end
@end

@beat s_sleep
@when beat("s_visit_react")
wait 4
choice daniel c1s_sleep
  > E estás a dormir? A Dra. Helena ainda te dá aquilo?
  > Dormes? Diz a verdade.
end
@end

@beat s_bye
@when beat("s_sleep") and v("net_in") >= 3
wait 1
choice daniel c1s_bye
  > Não olhes para o relógio quando acordas. Promete. Tenho de ir, entro às 23h
  > Mentiroso. Tenho de ir, turno às 23h. Come. Dorme. Gosto de ti, parvalhão
  > Responde à mãe, que ela já me ligou duas vezes a perguntar se estás vivo. Vou para o turno
end
@end

# ---------------------------------------------------------------- a mãe
@beat s_mae
@when at("21:52")
mae> JA FALASTE COM O TEU IRMAO
mae> desculpa as maiusculas. já falaste com ele?
@end

@beat s_mae_reply
@when beat("s_mae") and read("mae")
wait 1
choice mae c1s_mae
  > Estou a falar agora, mãe. Está vivo. | set s_mae=calm
  > Mãe, ele está pior do que diz. | set s_mae=worried
end
wait 20
if vs("s_mae") == "worried"
  mae> Eu sei. Ele diz que está bem com a mesma voz com que dizia que não tinha trabalhos de casa
  mae> Para a semana faz um ano. Não o deixes sozinho nesse dia
else
  mae> Graças a Deus. Diz-lhe que domingo há cabrito
endif
@end

# ---------------------------------------------------------------- o turno
@beat s_patricia
@when at("22:40")
patricia> Sofia, hoje somos só duas no piso 6. O Rogério meteu baixa
patricia> Trouxe o bolo de laranja. Não digas a ninguém
@end

@beat s_shift
@when at("23:02")
notify settings "Modo de foco" "Turno · as notificações continuam ativas"
@end

# ---------------------------------------------------------------- 00:31
@beat s_unknown
@when at("00:31")
unknown> O teu irmão ainda está acordado.
wait 6
unknown> Pergunta-lhe porquê.
@end

@beat s_unknown_reply
@when beat("s_unknown") and read("unknown")
wait 1
choice unknown c1s_unknown
  > Quem fala? | set s_asked_who=true
  > [Não responder]
end
if flag("s_asked_who")
  wait 30
  unknown> Alguém que também não dorme.
endif
coopset co_sofia_got_unknown true
@end
