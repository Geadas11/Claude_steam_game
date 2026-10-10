# =====================================================================
# CAPÍTULO 13 — O CAIS VELHO
# terça 13 → quarta 14 de outubro, 23:00 → 02:50
# A última noite em casa, as vozes de quem ficou; às 00:30, o caminho
# daquela noite, a pé: Rua das Gaivotas, EN125, as bombas (o empregado
# da noite confirma o que viu), o Largo do Cais, o cais.
# A coisa: todas as formas — um casaco vermelho ao longe, ele próprio
# encharcado a vir ao contrário, pegadas que vão para o mar.
# =====================================================================
@chapter ch13
@title O Cais Velho
@start 2026-10-13 23:00

@beat setup
set chapter_n=13
setting signal 4
rate 1
ambient night
location casa
battery 47
@end

@beat voices
@when since("setup", 6)
if flag("sofia_knows")
  sofia> Saí de Lisboa às 22h. Chego por volta das 2. Não faças nada estúpido até eu chegar
elif flag("sofia_call11")
  sofia> Às onze e vinte faço intervalo. Tens o telemóvel com bateria? Atende
else
  sofia> Boa noite mano. Amanhã ligo-te depois da consulta. Gosto de ti
endif
wait 20
if flag("joao_coming")
  joao> fecho o bar as 2. depois vou ter contigo
elif flag("joao_available")
  joao> tou acordado se precisares
endif
wait 20
if flag("rui_coming")
  rui> Vou estar no cais a partir das 2 e meia. No sítio onde a encontraram.
endif
if flag("evidence_sent")
  wait 15
  clara> Está tudo pronto. 7h. Não desligue o telemóvel.
endif
if flag("plan_give_vasco")
  wait 15
  vasco> Às 3, no fim do cais. Venha sozinho, Daniel. É melhor assim para todos.
endif
@end

@beat helena_last
@when at("23:40") and v("trust_helena") >= 1
helena> Ainda vai a tempo. Amanhã às 9h estou na clínica. Por favor.
@end

@beat mae_candle
@when at("23:25")
mae> filho acendi a vela pela menina. e outra por ti
mae> dorme bem
@end

@beat sofia_call11
@when flag("sofia_call11") and not flag("sofia_knows") and at("23:20")
call sofia id=c11_sofia ring=20
  sofia: Atendeste. Ainda bem. | 2
  sofia: Não precisas de dizer nada. Eu falo. | 2.5
  wait 1
  sofia: Lembras-te de quando tinhas nove anos e te perdeste na praia da Salgueira? Estiveste duas horas desaparecido. | 5
  sofia: A mãe chorava. O pai gritava o teu nome. Eu fui a única que pensou em ir ao fim do paredão. | 4.5
  sofia: Estavas lá sentado, a ver o mar. Disseste que estavas à espera que alguém te viesse buscar. | 4.5
  wait 1.5
  sofia: Ainda estou aqui, Daniel. Se te perderes, eu sei onde procurar. | 3.5
end
if answered("c11_sofia")
  set heard_sofia11=true
else
  wait 5
  sofia> Não atendeste. Vou fingir que estavas no duche
  sofia> Gosto de ti, idiota
endif
@end

@beat carla_amulet
@when at("23:50") and flag("found_card")
carla> Querido, passei pela loja para ir buscar os óculos
carla> O meu Ricardo Reis está outra vez no sítio. Mais leve, parece-me. Sem pó
carla> Faz o que tiveres de fazer. A loja abre às dez, mas tu amanhã não vens. Está decidido
@end

@beat rita_last
@when flag("rita_keep") and at("00:10")
rita> também não consegues dormir pois não
rita> o "pai" escreveu-me há bocado. disse "filha, deixa-me ir"
rita> o meu pai nunca na vida disse isso. nunca me deixou ir a lado nenhum
rita> acho que a coisa que fala por ele também está cansada
@end

@beat rita_last_reply
@when beat("rita_last") and read("rita")
wait 1
choice rita c11_rita
  > Desliga o telemóvel, Rita. Amanhã de manhã ligas à Clara. | set rita11=off
  > Responde-lhe. Diz-lhe o que nunca lhe disseste. | set rita11=answer
end
wait 25
if vs("rita11") == "off"
  rita> ok
  rita> se amanhã de manhã eu ainda estiver acordada, ligo
  rita> boa noite daniel. obrigada por me teres acreditado
else
  rita> escrevi "eu sei que não és tu"
  wait 6
  rita> respondeu "eu sei, filha"
  wait 4
  rita> não sei se isso foi a pior coisa ou a melhor coisa que me aconteceu este ano
endif
@end

# ---------------------------------------------------------------- a câmara, antes de sair
@beat home_camera
@when at("00:05")
camera close
unknown> Abre a câmara. Uma última vez.
wait 3
unknown> Quero ver a sala antes de saíres.
@end

@beat home_camera_seen
@when flag("cam_close_seen") and not flag("left_home")
wait 5
unknown> Não era eu.
wait 4
unknown> Tranca a porta quando saíres, Daniel.
clue someone_in_the_room
@end

# ---------------------------------------------------------------- sair (já não é uma escolha)
@beat leave
@when at("00:30")
unknown> Está na hora.
choice unknown c13_leave
  > [Vestir o casaco e sair] | set going=true
end
sound door
wait 2
set left_home=true
battery 23
location caminho
wait 2
world spawn casa
world rain on
world presence calm
wait 3
world think A rua está molhada. O candeeiro ao pé do contentor continua a piscar. Há um ano saí por esta porta às duas e meia.
wait 6
unknown> Vira à direita. Depois é sempre em frente.
wait 3
unknown> Tu sabes o caminho. Fizeste-o ao contrário.
@end

@beat walk_nudge
@when beat("leave") and since("leave", 150) and not flag("w_zone_en125")
unknown> A estrada nacional. Sem passeio. Anda pela berma.
@end

# ---------------------------------------------------------------- a estrada
@beat walk_memories
@when flag("left_home") and flag("w_zone_en125")
unknown> Foi por esta estrada que voltaste para casa nessa noite.
wait 3
unknown> Ao contrário.
choice unknown c11_mem1
  > Do que é que te lembras de nós? | set mem1=us
  > Porque é que me perdoaste? | set mem1=forgive
  > [Continuar a andar em silêncio] | set mem1=silent
end
wait 8
if vs("mem1") == "us"
  unknown> Lembro-me de discutirmos se o Ricardo Reis existia. Tu dizias que sim. Que o Pessoa o deixou viver mais tempo do que ele próprio.
  wait 5
  unknown> Lembro-me de leres devagar demais. E de eu te tirar o livro da mão.
  wait 5
  unknown> Não sei se me lembro ou se me deram para lembrar. Às vezes é a mesma coisa.
elif vs("mem1") == "forgive"
  unknown> Porque tinhas medo por mim. O medo faz-nos contar coisas a quem não devíamos.
  wait 5
  unknown> E porque se eu não te perdoasse ficavas aqui para sempre. Às 3:17. Todas as noites.
else
  wait 10
  unknown> Está bem. Eu também gosto deste silêncio.
endif
@end

@beat red_coat
@when flag("left_home") and flag("w_zone_bombas") and not beat("red_coat")
world figure 175 -2.8 red
wait 3
world think Ao fundo da estrada, depois das bombas, alguém de casaco vermelho. Parado na berma, virado para mim.
wait 8
unknown> Não corras para ela.
wait 2
unknown> Nunca chegas.
@end

@beat clerk
@when flag("left_home") and flag("pc_live")
clue pc_live
wait 6
unknown> Ele disse isso à polícia.
wait 3
unknown> Escreveram «testemunha pouco fiável». Trabalha de noite.
@end

@beat clerk_nudge
@when flag("w_zone_bombas") and since("red_coat", 40) and not flag("w_guiche") and not flag("w_zone_largo")
unknown> O homem do guiché estava cá há um ano.
wait 2
unknown> Pergunta-lhe.
@end

# ---------------------------------------------------------------- o largo
@beat largo
@when flag("left_home") and flag("w_zone_largo")
if flag("joao_coming")
  joao> te vi a passar da janela do bar. espera ai 5 min q eu vou contigo
  set joao_with=true
else
  world think O Farol fechado. O néon fica aceso a noite toda; o João diz que é para os pescadores saberem onde é a terra.
endif
wait 6
unknown> A câmara do café está a gravar.
wait 2
unknown> Há um ano também estava.
@end

@beat sofia_arrives
@when flag("sofia_knows") and at("02:05")
sofia> Cheguei.
sofia> Estou à tua porta. Onde estás??
if flag("left_home")
  choice sofia c11_sofia
    > No cais. Vem ter comigo. | set sofia_coming_pier=true
    > Fica aí. Eu volto. | set sofia_waits=true
  end
  wait 6
  if flag("sofia_coming_pier")
    sofia> Vou já
  else
    sofia> Daniel. Volta. Ouviste? Volta
  endif
endif
@end

@beat sofia_callback
@when flag("sofia_knows") and flag("left_home") and at("02:35")
if flag("sofia_coming_pier")
  sofia> Já te vejo ao fundo. Não te mexas
else
  sofia> Estou à tua porta. Cheguei, mano. Desta vez cheguei mesmo
endif
@end

@beat joao_fishing
@when flag("joao_with") and at("02:40")
joao> {instant} dani
joao> {instant} quando isto acabar ainda me deves aquela ida a pesca
if flag("joao_thanks") or v("trust_joao") >= 3
  joao> {instant} e desta vez nao aceito talvez
endif
@end

# ---------------------------------------------------------------- o cais
@beat walk_memories2
@when flag("left_home") and flag("w_zone_cais")
unknown> Aqui paraste. Há um ano. Olhaste para trás.
wait 4
unknown> Eu vi-te parar. Achei que ias voltar.
choice unknown c11_mem2
  > Desculpa. | set mem2=sorry
  > Porque é que eu não voltei? | set mem2=why
end
wait 8
if vs("mem2") == "why"
  unknown> Voltaste.
  wait 4
  unknown> Ouviste-me gritar da estrada e voltaste a correr. Entraste na água até aos joelhos. Chamaste por mim até ficares sem voz.
  wait 6
  unknown> Às 03:41 o João viu-te passar encharcado. Já era tarde. Não era culpa tua ser tarde.
  if flag("joao_heard_called")
    wait 4
    unknown> Disseste-lhe "ela chamou-me". Era verdade.
  endif
  if flag("mae_call_430")
    wait 5
    unknown> Às quatro e meia ligaste à tua mãe e não conseguiste dizer nada.
    unknown> Ela ficou a ouvir o mar contigo.
  endif
  clue went_back
else
  unknown> Eu sei.
  wait 4
  unknown> Mas não foste tu que me deixaste cair. Lembra-te disso quando chegares ao fim do cais.
endif
@end

@beat self_coming
@when beat("walk_memories2") and since("walk_memories2", 30)
world figure 221 82 dark
wait 2
world think Vem alguém pelo cais na minha direção. Encharcado. Anda como eu. Com as mãos abertas, como quem não sabe o que fazer com elas.
@end

@beat prints_sea
@when flag("left_home") and flag("w_zone_fim")
world prints 221 95 0 9
wait 2
world think Pegadas molhadas nas tábuas. Descalças. Vão até à ponta do cais e não voltam.
@end

@beat arrive
@when beat("prints_sea") and since("prints_sea", 20)
wait 2
if not at("02:50")
  time 02:50
endif
wait 2
endchapter
@end

@beat late
@when at("02:50") and not beat("arrive")
world think Não me lembro do resto do caminho. Os pés molhados. O mar à frente.
wait 3
endchapter
@end
