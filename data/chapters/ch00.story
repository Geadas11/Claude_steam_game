# =====================================================================
# PRÓLOGO — A NOITE
# 13 → 14 de outubro de 2025, 02:30 → 03:17
# A versão que o Daniel guarda daquela noite (memória pouco fiável).
# O caminho à chuva, a Inês de casaco vermelho no fim do cais, a
# mensagem do Vasco que lhe acende o ecrã na mão, o cartão e a chave.
# Vai-se embora. Atrás, passos mais pesados do que os dela. «Vou já»
# fica por enviar. 03:17: um grito, longe. Negro.
# Sem a coisa (R1): só o mar, o vento, a chuva. Ensina a ouvir.
# O telemóvel do jogo não está aqui: o antigo acende-se no HUD.
# =====================================================================
@chapter ch00
@title A Noite
@start 2025-10-14 02:30

@beat setup
set chapter_n=0
rate 1
ambient sea
location caminho
battery 61
world phone off
wait 2
world spawn largo
world rain on
world presence off
world figure 227.6 100.8 ines
wait 3
world think Chove pouco. O telemóvel antigo, na mão, ainda com a capa rachada no canto.
wait 5
world screen Inês «estás a chegar»
wait 3
world screen Inês «não venhas se for para me dizer outra vez que é perigoso»
wait 2
choice aqui p_reply
  > [Escrever: «Estou a chegar.»] | set p_replied=true
  > [Não responder] | set p_replied=false
end
if flag("p_replied")
  world screen Eu «Estou a chegar.»
endif
@end

@beat car_one
@when since("setup", 45)
world think Na estrada de cima, um carro passa devagar, de luzes apagadas. Não se ouve o motor. Só os pneus na água.
@end

@beat way_nudge
@when since("setup", 100) and not flag("w_zone_cais")
world think O cais é ao fundo do largo, depois dos barcos. Ela está na ponta.
@end

@beat way_late
@when at("02:52") and not flag("w_zone_fim")
world think Não me lembro de ter atravessado o cais. Lembro-me das tábuas molhadas e do casaco dela.
world spawn fim
set w_zone_fim=true
@end

# ---------------------------------------------------------------- o cais
@beat meet
@when flag("w_zone_fim")
world hold 600
world say Inês «ouve. não tenho muito tempo»
wait 5
world say Inês «se vieste para me dizer que é perigoso, já sei. às dez falo com a Clara e acabou»
wait 3
choice aqui p_tone
  > Só quero que tenhas cuidado. | set p_tone=care
  > Isto vai destruir-te. Há outras maneiras. | set p_tone=fear
  > [Ficar calado] | set p_tone=silent
end
wait 3
if vs("p_tone") == "care"
  world say Inês «cuidado é o que eles contam que eu tenha»
elif vs("p_tone") == "fear"
  world say Inês «dizes isso como se já soubesses qual»
else
  world say Inês «pois. é isso que tu fazes»
endif
wait 6
world screen Vasco Pimentel «Obrigado, meu caro. Eu trato disto. Fica tranquilo.»
wait 3
world think O ecrã acendeu-se na minha mão. Ela olhou para baixo antes de eu o conseguir esconder.
wait 6
world say Inês «eu trato disto»
wait 4
world say Inês «foste tu»
wait 2
choice aqui p_admit
  > Eu só queria que ele falasse contigo antes. | set p_admit=excuse
  > Desculpa. | set p_admit=sorry
  > [Não dizer nada] | set p_admit=silent
end
wait 3
if vs("p_admit") == "excuse"
  world say Inês «claro. antes. tu fazes sempre tudo antes, para não teres de estar lá depois»
elif vs("p_admit") == "sorry"
  world say Inês «não peças desculpa. ainda não»
else
  world say Inês «nem isso, daniel»
endif
wait 7
world think Tirou do bolso do casaco um cartão de memória e uma chave com um porta-chaves de madeira gasto. Estendeu a mão e ficou à espera.
wait 2
choice aqui p_take
  > [Aceitar o cartão e a chave] | set p_took=true
end
wait 2
world say Inês «o cartão tem tudo. a chave é da livraria, a carla deu-ma para eu ir ler de manhã»
wait 6
world say Inês «se me acontecer alguma coisa, já sabes»
wait 5
if flag("p_replied")
  world say Daniel «Vim porque disse que vinha.»
else
  world say Daniel «Eu vim.»
endif
wait 4
world say Inês «vai-te embora, daniel. vai para casa»
wait 5
world hold 0
world think Virei costas.
set p_left=true
@end

# ---------------------------------------------------------------- a estrada
@beat leaving
@when flag("p_left")
time 03:06
wait 6
world sound step 223.5 103.5 -2 0.78
wait 0.8
world sound step 223.0 102.8 -2 0.8
wait 0.8
world sound step 222.6 102.1 -3 0.76
wait 3
world think Passos na madeira, atrás de mim. Mais pesados do que os dela.
@end

@beat come_back
@when flag("p_left") and at("03:12")
world screen Inês «daniel volta»
wait 3
world hold 22
world screen A escrever… «Vou já»
wait 2
world think O dedo em cima do botão de enviar. Não carrego. Não sei porque não carrego.
@end

@beat he_is_here
@when flag("p_left") and at("03:15")
world screen Inês «ele está aqui»
wait 4
world think Um carro sem luzes passa por mim, a descer para o cais. Outro. Ou o mesmo.
@end

@beat scream
@when flag("p_left") and at("03:17")
sound scream
world hold 0
world shake 0.6
wait 1
world think Corri.
wait 7
ambient off
world fade out 2.5
world figure off
wait 4
world title É isto que tu lembras.
wait 7
endchapter
@end
