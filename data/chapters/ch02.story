# =====================================================================
# CAPÍTULO 2 — O CONTACTO
# sexta-feira, 9 de outubro de 2026, 08:05 → 23:30
# O número desconhecido sabe coisas privadas. Versões diferentes da mesma
# situação (Pedro: golpe com IA; João: viu alguém de capuz; Vasco: "envie-me
# capturas"). A primeira chamada. A fotografia da rua.
# =====================================================================
@chapter ch02
@title O Contacto
@start 2026-10-09 08:05

@beat setup
set chapter_n=2
rate 2
ambient room
location casa
battery 91
unknown> {time=03:02} [photo:IMG_6630]
unknown> {time=03:03} Dormes de lado agora.
calllog unknown missed 03:17
voicemail vm_sea
carla> {instant} Bom dia!! Dentista às 10h. Reza por mim
@end

# ---------------------------------------------------------------- manhã
@beat morning_unknown
@when read("unknown")
wait 2
choice unknown c2_morning
  > Estiveste dentro da minha casa? | set asked_inside=true
  > Isto tem de parar. Quem és tu? | set asked_who2=true
  > Vou bloquear este número | set blocked=true
  > [Não responder] | set ignored_morning=true
end
if flag("blocked")
  contactset unknown blocked true
  toast "Número bloqueado"
  wait 20
  unknown> Bloqueia.
  wait 3
  unknown> Eu espero.
  set block_failed=true
elif flag("asked_inside")
  wait 5
  unknown> Não estive em lado nenhum.
  wait 3
  unknown> Tu é que estiveste.
elif flag("asked_who2")
  wait 6
  unknown> Já te disse.
  unknown> Sou eu.
  choice unknown c2_who_again
    > Eu quem? | set pressed_who=true
    > [Não responder]
  end
  if flag("pressed_who")
    wait 8
    unknown> Para de perguntar.
    wait 14
    typing unknown unknown 5
    wait 3
    unknown> Estás a assustar-me.
    clue unknown_scared
  endif
endif
@end

@beat replay_hint
@when v("prev_endings") >= 1 and beat("morning_unknown")
wait 30
unknown> Desta vez lembras-te mais cedo de mim.
if flag("prev_end_B")
  wait 4
  unknown> Da última vez deste-lhe o cartão.
elif flag("prev_end_C")
  wait 4
  unknown> Da última vez desligaste-me no fim do cais.
endif
@end

@beat voicemail_heard
@when file_open("vm_vm_sea")
set heard_sea=true
@end

@beat carla_morning
@when read("carla") and since("setup", 3)
choice carla c2_carla
  > Força! Eu trato da loja | set carla_ok2=true
  > Vais sobreviver. Eu abro às 10 | set carla_ok2=true
end
wait 2
carla> Obrigada querido. A máquina do café tem um feitio. Bate-lhe do lado esquerdo
@end

@beat to_work
@when at("09:52")
location livraria
wait 2
world spawn entrada
world lights on
wait 2
world think No porta-chaves, ao lado da chave da loja, outra igual. Com uma fita vermelha, desbotada. Não sei de onde veio. Está lá há meses.
set saw_red_key=true
wait 6
world say Carla «Bom dia, querido! Abres tu a caixa? Eu vou lá acima arrumar a poesia, que alguém a deixou toda trocada.»
wait 7
world say Carla «E arruma-me os Saramagos, por favor. É outubro.»
@end

@beat carla_red_key
@when beat("to_work") and since("to_work", 200) and loc("livraria")
world say Carla «Daniel, essa fita vermelha no teu porta-chaves... eu já vi isso em algum lado.»
wait 6
world say Carla «Não me lembro onde. Estou a ficar velha.»
@end

# ---------------------------------------------------------------- saramagos
@beat saramago
@when at("10:35")
vibrate
unknown> Arrumaste os Saramagos?
set unknown_knew_saramago=true
@end

@beat saramago_reply
@when beat("saramago") and read("unknown")
wait 1
choice unknown c2_saramago
  > Como é que sabes disso? | set asked_how_saramago=true
  > Andas a ler as minhas mensagens? | set asked_reading=true
  > [Não responder]
end
wait 4
unknown> Deixa o Ricardo Reis onde está.
wait 3
typing unknown unknown 5
wait 2
unknown> Ainda não.
clue unknown_mentions_book
@end

# ---------------------------------------------------------------- grupo
@beat grupo_morning
@when at("11:20")
grupo:marta> bom dia!! quiz às 21h30. o joão já tem a mesa
grupo:pedro> eu levo o meu bloco de notas da sorte
grupo:joao> o bloco de notas da sorte nunca te deu sorte nenhuma
@end

@beat grupo_ask
@when beat("grupo_morning") and read("grupo")
wait 1
choice grupo c2_grupo
  > Pergunta parva: alguém me anda a mandar fotos de noite? | set asked_group=true
  > Lá estarei | set quiz2=yes
  > Não sei se consigo ir hoje | set quiz2=no
end
if flag("asked_group")
  wait 2
  grupo:joao> fotos de que
  grupo:marta> Daniel??? que fotos
  choice grupo c2_grupo_photos
    > Uma foto da minha janela. De fora. Às 23h44 | set told_group=true
    > Esquece. Deve ser spam | set told_group=false
  end
  if flag("told_group")
    wait 2
    grupo:marta> isso é assustador
    grupo:pedro> calma. há uma vaga de golpes com fotos geradas por IA. pegam em fotos tuas das redes e fazem montagens. depois pedem dinheiro
    grupo:pedro> não respondas e não cliques em links
    grupo:joao> o daniel nao tem redes sociais pedro
    grupo:pedro> ...
    grupo:pedro> então não sei
    clue pedro_ai_theory
  else
    grupo:marta> ok. se precisares diz
  endif
  wait 2
  grupo:marta> vens ao quiz?
  choice grupo c2_quiz2
    > Vou | set quiz2=yes
    > Hoje não. Desculpem | set quiz2=no
  end
endif
@end

@beat joao_hood
@when beat("grupo_ask") and at("12:10")
joao> ei
joao> ontem qd fechei o bar as 2 e 20 passei na tua rua
joao> tava um gajo de capuz parado no passeio em frente a tua casa. a olhar
joao> pensei q eras tu
choice joao c2_hood
  > Não era eu. Eu estava a dormir | set joao_hood=asleep
  > A que horas exatamente? | set joao_hood=time
  > Porque é que passaste na minha rua? Não é caminho para tua casa | set joao_hood=suspicious
end
wait 3
if vs("joao_hood") == "time"
  joao> 2 e 20 2 e 25
  joao> tava parado. nao fazia nada. qd me viu virou-se e foi para o lado do cais
elif vs("joao_hood") == "suspicious"
  joao> fui deixar a caixa das garrafas ao contentor do largo
  joao> oh daniel q pergunta é essa
  inc trust_joao -1
else
  joao> ok
  joao> entao era alguem
endif
wait 2
joao> se quiseres durmo ai hoje. no sofa. nao me importo
choice joao c2_joao_stay
  > Não é preciso. Obrigado | set joao_stays=false
  > Talvez. Vejo à noite | set joao_stays=maybe inc trust_joao 1
end
clue hooded_man
@end

# ---------------------------------------------------------------- Sofia
@beat sofia_wake
@when at("12:45")
sofia> Acordei. Turno horrível. Um senhor tentou fugir de pijama às 4 da manhã
sofia> Estás bem? Dormiste?
@end

@beat sofia_talk2
@when beat("sofia_wake") and read("sofia")
wait 1
choice sofia c2_sofia
  > Estão a mandar-me mensagens estranhas de um número que não conheço | set told_sofia=true
  > Dormi. Mais ou menos | set told_sofia=false
end
wait 2.5
if flag("told_sofia")
  sofia> Que mensagens?
  choice sofia c2_sofia_detail
    > Uma foto minha, tirada de fora de casa. E outra do meu quarto. De dentro | set told_sofia_photos=true
    > Coisas que só eu sei | set told_sofia_photos=false
  end
  wait 3
  sofia> Daniel.
  sofia> Isso é grave. Guarda tudo. Tira capturas. Se continuar vais à GNR, ouviste?
  sofia> E não fiques sozinho hoje. Chama o João
  wait 3
  sofia> Já agora... não será alguém da Lumen? Eles nunca te deixaram em paz desde aquilo. Aquele Vasco liga-te todos os meses
  clue sofia_suspects_lumen
else
  sofia> Mais ou menos é melhor que nada
endif
wait 3
sofia> Pronto, está decidido. Vou aí amanhã. Troquei o turno com a Rute
sofia> #sofia_arrive Chego amanhã à noite.
set sofia_coming=true
@end

# ---------------------------------------------------------------- pesquisa do número
@beat number_searched
@when searched("912") or searched("403 317") or visited("quemligou")
set searched_number=true
@end

@beat lunch_nudge
@when at("13:40") and not flag("searched_number")
grupo:pedro> já agora daniel. se te ligarem de números estranhos vai ao quemligou.pt e pesquisa o número. às vezes há comentários de outras pessoas
@end

# ---------------------------------------------------------------- a chamada
@beat first_call
@when at("15:05")
call unknown id=c2_call ring=18
  [sfx static]
  - (silêncio)
  wait 2
  [sfx sea]
  - (o mar, muito perto)
  wait 2
  unknown: ...estás a trabalhar? | 2.5
  - (uma voz de mulher. baixa. como se tapasse o microfone com a mão)
  wait 1.5
  unknown: Não deixes a Carla mexer no livro. | 3
  [sfx glitch_short]
  - (a chamada cai)
end
if answered("c2_call")
  clue call_voice_woman
  set heard_voice=true
else
  wait 8
  unknown> Porque não atendeste?
endif
@end

# ---------------------------------------------------------------- tarde
@beat mae_chain
@when at("16:30")
mae> RECEBI ISTO DA PRIMA FERNANDA
mae> "Partilhe com 10 pessoas que ama ou terá 7 anos de azar. Não quebre a corrente. Nossa Senhora protege quem partilha."
mae> estou a partilhar contigo filho
choice mae c2_mae
  > Mãe, essas correntes são mentira | set mae_chain=no
  > Obrigado mãe. Já tenho azar que chegue | set mae_chain=joke
end
wait 3
if vs("mae_chain") == "joke"
  mae> credo daniel não digas isso
  mae> vou acender uma vela
else
  mae> eu sei. mas por via das duvidas
endif
@end

@beat vasco_battery
@when at("17:40")
vasco> Boa tarde, Daniel. Desculpe incomodar.
vasco> Recebi um alerta automático da gestão de dispositivos: o seu Lumen One está a reportar um consumo anormal de bateria esta noite. Está tudo bem com o telemóvel?
clue vasco_monitors_phone
@end

@beat vasco_battery_reply
@when beat("vasco_battery") and read("vasco")
wait 1
choice vasco c2_vasco
  > Estou a receber mensagens estranhas de um número desconhecido | set told_vasco_msgs=true inc trust_vasco 1
  > Está tudo bem, obrigado | set told_vasco_msgs=false
  > Como é que sabe o consumo de bateria do meu telemóvel? | set asked_vasco_how=true inc trust_vasco -1
end
wait 3
if flag("told_vasco_msgs")
  vasco> Lamento muito. Há pessoas cruéis, sobretudo nesta altura do ano.
  vasco> Não responda. Envie-me capturas de tudo e eu peço à equipa de segurança para rastrear o número. Discretamente.
  vasco> E Daniel — não alimente isso. Quanto mais responder, mais eles insistem.
elif flag("asked_vasco_how")
  vasco> O dispositivo é gerido pela empresa durante 24 meses, lembra-se? Está no contrato. É só telemetria técnica, nada pessoal.
  vasco> Não se preocupe. Bom fim de semana.
else
  vasco> Ótimo. Qualquer coisa, sabe onde estou.
endif
@end

@beat back_home
@when at("19:05")
location casa
carla> Correu bem a loja? O dentista diz que tenho de voltar. Mais duas vezes. Odeio-o
@end

@beat carla_evening
@when beat("back_home") and read("carla")
wait 1
choice carla c2_carla_eve
  > Correu bem. Vendi dois Saramagos e um Peixoto | set carla_eve=good
  > Correu. Arrumei a caixa da Caminho | set carla_eve=ok
end
wait 2
carla> Que orgulho. Bom fim de semana Daniel
carla> Ah! Não mexeste no meu Ricardo Reis, pois não? Estava um bocadinho fora do sítio
choice carla c2_carla_book
  > Não mexi. Juro | set carla_book=no
  > Não... deve ter sido um cliente | set carla_book=client
end
wait 2
carla> Deve ter sido o vento. Aquela estante tem fantasmas
clue carla_book_moved
@end

# ---------------------------------------------------------------- noite: o quiz
@beat quiz_time
@when at("21:20")
if vs("quiz2") == "yes" or vs("quiz") == "yes"
  grupo:marta> estamos cá! mesa do canto
  location farol
  set at_bar=true
else
  grupo:marta> vamos começar. vais ver o Pedro perder em tempo real
  grupo:pedro> injusto
endif
@end

@beat street_photo
@when at("21:58")
ambient off
wait 1
vibrate
unknown> {instant} [photo:IMG_6641]
if flag("at_bar")
  unknown> Estou à tua porta.
  wait 3
  unknown> Deixaste a luz acesa.
else
  unknown> Estou cá fora.
endif
set got_street_photo=true
@end

@beat street_reply
@when beat("street_photo") and read("unknown")
wait 2
if flag("at_bar")
  choice unknown c2_street_bar
    > [Ir para casa sozinho] | set went_home_alone=true
    > [Pedir ao João para vir comigo] | set went_with_joao=true inc trust_joao 1
    > [Ficar no bar] | set stayed_bar=true
  end
  if flag("went_with_joao")
    location casa
    wait 6
    joao> {instant} ja tou aqui contigo mas fica registado
    wait 4
    joao> nao ta ninguem na rua. so o gato da vizinha
    wait 3
    joao> dani a tua porta tava aberta
    joao> tens a certeza q fechaste qd saiste?
    set door_open=true
    clue door_was_open
  elif flag("went_home_alone")
    sound footsteps
    wait 5
    location casa
    screenoff 3
    wait 2
    unknown> Chegaste tarde.
  else
    wait 5
    unknown> Fica. Eu fico aqui à tua espera.
  endif
else
  choice unknown c2_street_home
    > [Ir lá fora] | set went_outside=true
    > [Trancar a porta e apagar a luz] | set locked_door=true
    > [Ligar ao João] | set called_joao_street=true inc trust_joao 1
  end
  if flag("went_outside")
    screenoff 4
    sound footsteps
    wait 4
    unknown> Já fui.
    wait 2
    unknown> Mas tu viste-me. Não viste?
  elif flag("locked_door")
    sound lock
    wait 6
    unknown> Fechar a porta não serve de nada, Daniel.
    wait 3
    unknown> Nunca serviu.
  else
    call joao id=c2_joao_street outgoing
      joao: Dani? Que foi? | 1.8
      - (barulho de bar ao fundo)
      joao: Calma. Calma. Estou a sair agora. Cinco minutos. Não abras a porta a ninguém. | 3.5
    end
    wait 10
    joao> {instant} tou na tua rua
    wait 3
    joao> nao ta ninguem dani. so o candeeiro e o gato da vizinha
    joao> abre q eu durmo ai
    set joao_slept_over=true
  endif
endif
ambient room
checkpoint
@end

# ---------------------------------------------------------------- final
@beat the_pier
@when beat("street_reply") and at("23:00")
wait 4
unknown> Lembras-te do cais?
choice unknown c2_pier
  > Que cais? | set asked_which_pier=true
  > Não sei do que estás a falar | set denied_pier=true
  > [Não responder]
end
wait 6
unknown> Eu lembro-me.
wait 4
typing unknown unknown 7
wait 3
unknown> Boa noite, Daniel.
clue unknown_mentions_pier
wait 6
@end

@beat end_ch2
@when beat("the_pier")
wait 4
lock
wait 2
endchapter
@end

# ---------------------------------------------------------------- chamadas do jogador
@call joao c2_call_joao
@when not beat("street_reply")
joao: Diz, Dani. | 1.5
joao: Se é por causa do gajo de capuz, eu não inventei. Tava lá mesmo. | 3
joao: Queres que passe aí depois do quiz? | 2
set called_joao2=true
@end

@call vasco c2_call_vasco
vasco: Daniel! Que bom ouvi-lo. | 2
vasco: Diga-me, meu caro. Está tudo bem? Tem notado alguma coisa estranha no telemóvel? | 3.5
- (ele espera)
vasco: Se acontecer alguma coisa, sou o primeiro a quem deve ligar. Combinado? | 3
inc trust_vasco 1
set called_vasco2=true
@end

@call carla c2_call_carla
@when at("10:00") and not at("19:00")
carla: Não consigo falar, tenho a boca cheia de algodão. | 2.5
carla: Corre tudo bem aí? Ótimo. Beijinho. | 2
@end

# ---------------------------------------------------------------- normalidade
@beat marta_lunch
@when at("13:05")
marta> o 9.º ano adorou a ideia do livro!! bem, "adorou" é forte. ninguém dormiu
marta> estás bem? o grupo ficou preocupado contigo de manhã
@end

@beat marta_lunch_reply
@when beat("marta_lunch") and read("marta")
wait 1
choice marta c2_marta
  > Estou. Deve ser alguém a brincar comigo. | set marta2=fine
  > Não sei, Marta. Sinto que alguém me está a observar. | set marta2=honest
end
wait 4
if vs("marta2") == "honest"
  marta> isso é horrível
  marta> eu tive um aluno que fazia isso a uma colega com fotos. a polícia apanhou-o pelo telemóvel dele. não estás sozinho nisto
  marta> e logo à noite estamos todos no farol. ninguém te vai observar lá a não ser o pedro a perder
else
  marta> se for brincadeira é de mau gosto. diz-me quem é que eu dou-lhe um teste surpresa
endif
@end

@beat quiz_results
@when at("23:12") and beat("street_reply")
if flag("at_bar")
  grupo:marta> FICÁMOS EM SEGUNDO
  grupo:pedro> roubados. a pergunta do muro de berlim era ambígua
  grupo:joao> nao era nada pedro
  grupo:marta> e o daniel acertou a do saramago antes de o apresentador acabar a pergunta
  grupo:marta> desculpa. bati palmas. em texto
else
  grupo:marta> ficámos em terceiro. a pergunta sobre o Saramago era tua, Daniel
  grupo:pedro> eu disse Eça de Queirós
  grupo:joao> o pedro disse eça de queiros
  grupo:marta> para a semana vens. não é um pedido
endif
@end

@beat farmacia_mail
@when at("11:45")
email farmacia
@end
