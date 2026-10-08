# =====================================================================
# CAPÍTULO 4 — INVESTIGAÇÃO
# sábado, 10 de outubro de 2026, 10:15 → 19:00
# O mundo abre-se. Notícias, fórum, blogue trancado, a jornalista,
# o pescador que a encontrou. Pistas verdadeiras, falsas e contraditórias.
# =====================================================================
@chapter ch04
@title Investigação
@start 2026-10-10 10:15

@beat setup
set chapter_n=4
rate 2
ambient room
location livraria
battery 77
carla> {instant} Bom dia! Hoje fecho eu às 14h, podes ir mais cedo se quiseres. Estás com cara de quem não dormiu (vi-te pela montra)
@end

@beat carla_reply4
@when read("carla") and since("setup", 2)
choice carla c4_carla
  > Não dormi muito. Obrigado Carla | set carla4=tired
  > Estou bem! Só cansado | set carla4=fine
end
wait 3
carla> Toma um café. Do horrível. Faz milagres
wait 6
carla> Daniel, uma pergunta estranha
carla> Tu conhecias aquela rapariga da Lumen que morreu no cais? A Inês?
carla> Ela vinha cá à loja às vezes. Ficava horas na estante da literatura portuguesa. Lembrei-me dela hoje não sei porquê
clue ines_visited_shop
choice carla c4_carla_ines
  > Conhecia. Trabalhávamos juntos | set told_carla=true
  > Mal | set told_carla=false
end
wait 3
if flag("told_carla")
  carla> Lamento muito, querido. Não sabia. Ela tinha um riso muito bonito
else
  carla> Ah. Pensei que eram amigos. Uma vez vieram cá os dois, lembro-me tão bem. Ela tirou-te o livro da mão e disse que tu lias devagar demais
  clue carla_saw_them_together
endif
@end

# ---------------------------------------------------------------- o desconhecido orienta
@beat unknown_read
@when at("10:40")
if not visited("forum_rapariga")
  unknown> [link:forum_rapariga] Lê.
else
  unknown> Já leste o que o Armando escreveu. Agora liga-lhe.
endif
@end

@beat unknown_warn
@when at("12:00")
unknown> Não acredites em tudo o que lês.
wait 2
unknown> Sobretudo no que a Lumen escreve.
@end

@beat unknown_armando
@when at("15:00") and phone("armando_known") and called("armando") == 0
unknown> O Armando é boa pessoa. Liga-lhe.
wait 2
unknown> Ele viu-te.
@end

@beat unknown_blog
@when at("13:10") and visited("ines_profile") and not flag("unlocked_page_ines_blog")
unknown> O Tejo gostava de ti. Dormia-te sempre no colo.
clue tejo_hint
@end

@beat home
@when at("14:20")
location casa
@end

# ---------------------------------------------------------------- Clara
@beat clara_open
@when phone("clara_known") and app() == "messages:clara"
choice clara c4_clara
  > Boa tarde. Sou o Daniel Reis. Conhecia a Inês Matos. | set clara_intro=ines
  > Tenho informações sobre a morte no Cais Velho. | set clara_intro=info
  > [Fechar a conversa] | set clara_intro=none
end
if vs("clara_intro") != "none"
  wait 40
  clara> Quem lhe deu este número?
  choice clara c4_clara2
    > Está no site do jornal. | set clara_c=site
    > Ninguém. Encontrei-o. | set clara_c=found
  end
  wait 20
  clara> Sei quem é. Trabalhava com ela. Estava com ela nessa noite, segundo algumas pessoas.
  clara> Porque é que me escreve agora, um ano depois?
  choice clara c4_clara3
    > Estou a receber mensagens do número dela. | set clara_told_msgs=true
    > Porque não me lembro dessa noite e preciso de saber. | set clara_told_memory=true inc trust_clara 1
    > Acho que a Lumen esconde alguma coisa. | set clara_told_lumen=true inc trust_clara 1
  end
  wait 30
  clara> A Inês marcou uma reunião comigo para 14 de outubro, às 10h. Nunca apareceu.
  clara> Disse que ia trazer "tudo". Nunca soube o que era "tudo".
  clue clara_meeting
  wait 6
  clara> Não publico rumores. Se encontrar o que ela tinha, fale comigo. Só comigo. E não use este telemóvel para isso, se puder.
  set clara_talked=true
  inc trust_clara 1
endif
@end

# ---------------------------------------------------------------- Armando
@call armando c4_call_armando
@when v("chapter_n") >= 4
armando: Está? | 1.5
armando: Sim, sou o Armando. Da associação. | 2.5
- (ele ouve-te a explicar quem és)
armando: Ah. A menina do cais. | 2.5
wait 1.5
armando: Fui eu que a encontrei, sim. Às seis e quarenta. Estava de costas, na água. Com o casaco vermelho. | 5
armando: Havia marcas de pneus na terra, no caminho. De carro grande. Disse-o à Guarda. Escreveram num papel e mais nada. | 5.5
wait 2
armando: Espere lá. | 1.5
armando: Diga-me outra vez o seu nome. | 2
- (dizes-lhe)
wait 2
armando: O senhor é o rapaz que andava com ela. | 3
armando: Eu vi-o lá nessa noite. Eu saí de casa mais cedo para ver o barco por causa das marés. Às duas e meia, por aí. Estavam os dois no fim do cais. A discutir. | 7
armando: O senhor ia-se embora a pé. Ela chamava por si. | 4
wait 2
armando: Eu não disse isto à Guarda. Ninguém me perguntou pelo senhor. | 4
armando: Boa tarde. | 1.5
set armando_saw=true
clue armando_saw
achieve armando
@end

@beat armando_followup
@when flag("armando_saw")
wait 8
unknown> Agora já sabes que ele te viu.
wait 3
unknown> Não fiques zangado com ele. Ele também não dorme.
@end

# ---------------------------------------------------------------- Sofia não vem
@beat sofia_cancel
@when at("16:05")
sofia> Mano, má notícia
sofia> A Rute ficou doente e não consigo trocar o turno. Não posso ir hoje
sofia> Vou para a semana, prometo. Desculpa!!
@end

@beat sofia_cancel_reply
@when beat("sofia_cancel") and read("sofia")
wait 1
choice sofia c4_sofia
  > Não faz mal. A sério | set sofia4=ok
  > Precisava que viesses, Sofia. | set sofia4=needed
  > Sofia, encontrei uma coisa sobre a Inês | set sofia4=ines
end
wait 3
if vs("sofia4") == "needed"
  sofia> Ai Daniel. Vou ver se arranjo outra pessoa. Não prometo
  sofia> Liga ao João. Por favor
elif vs("sofia4") == "ines"
  sofia> O quê?
  choice sofia c4_sofia_ines
    > O número que me escreve era dela. E um pescador diz que me viu no cais nessa noite. | set told_sofia_ines=true
    > Esquece. Depois falamos. | set told_sofia_ines=false
  end
  wait 4
  if flag("told_sofia_ines")
    sofia> Daniel tu estavas em casa nessa noite. Eu liguei-te às 7 da manhã e tu estavas em casa
    sofia> Estavas... estavas esquisito. Com areia nos pés. Disseste que tinhas ido correr
    sofia> Eu achei estranho porque tu nunca corres
    clue sofia_sand
  endif
else
  sofia> És o melhor irmão do mundo. Para a semana faço o arroz de pato
endif
@end

# ---------------------------------------------------------------- Vasco
@beat vasco_invite
@when at("17:30")
email vasco_coffee
wait 20
vasco> Daniel, enviei-lhe um email. Não quero ser intrusivo. Mas soube que tem andado a fazer perguntas sobre a Inês.
vasco> Acho que lhe devo uma conversa honesta. Amanhã, 11h, Café Central?
@end

@beat vasco_invite_reply
@when beat("vasco_invite") and read("vasco")
wait 1
choice vasco c4_vasco
  > Combinado. Lá estarei. | set meet_vasco=true inc trust_vasco 1
  > Como é que sabe que ando a fazer perguntas? | set asked_vasco_know=true inc trust_vasco -1
  > Não, obrigado. | set meet_vasco=false
end
wait 4
if flag("asked_vasco_know")
  vasco> Salgueira é uma terra pequena, meu caro. E a Dra. Helena preocupa-se consigo.
  vasco> Ela não me contou nada de clínico, descanse. Só que andava mais agitado.
  clue vasco_helena_talk
  wait 3
  vasco> O convite mantém-se.
elif flag("meet_vasco")
  vasco> Excelente. Vai ver que lhe vai fazer bem.
else
  vasco> Compreendo. Fica o convite.
endif
@end

# ---------------------------------------------------------------- fim
@beat dont_trust
@when beat("vasco_invite_reply") and at("18:35")
wait 3
unknown> Não confies nele.
choice unknown c4_trust
  > Porque é que eu havia de confiar em ti? | set asked_why_trust_unknown=true
  > Em quem devo confiar, então? | set asked_whom=true
  > [Não responder]
end
wait 6
if flag("asked_why_trust_unknown")
  unknown> Não deves.
  wait 2
  unknown> Mas eu nunca te menti.
elif flag("asked_whom")
  unknown> Em quem te viu ir embora.
endif
wait 6
@end

@beat end_ch4
@when beat("dont_trust")
wait 4
lock
wait 2
endchapter
@end

# ---------------------------------------------------------------- chamadas
@call vasco c4_call_vasco
vasco: Daniel! Recebeu o meu email? | 2
vasco: Ouça, sei que o fórum da Salgueira diz muita coisa. Não leia aquilo. São pessoas com tempo a mais e dor a menos. | 5
vasco: A Inês estava a passar um mau bocado. Todos sabíamos. A Dra. Helena tentou ajudá-la. | 4.5
- (ele faz uma pausa)
vasco: O Daniel não podia ter feito nada. Lembre-se disso. | 3
inc trust_vasco 1
@end

@call rui c4_call_rui
- (a chamada é recusada)
@end

@call clara c4_call_clara
clara: Clara Neves. | 1.5
clara: Prefiro mensagens escritas. Desculpe. Escreva-me. | 3
@end

# ---------------------------------------------------------------- normalidade: o ECO 2 no grupo
@beat grupo_eco2
@when at("12:30")
grupo:pedro> viram? o ECO 2 vai "reconhecer emoções pela voz". vai saber quando estamos tristes
grupo:marta> que horror. eu não quero que o meu telemóvel saiba quando estou triste
grupo:joao> o meu telemovel é um nokia de 2009 e tenho muito orgulho disso
@end

@beat grupo_eco2_reply
@when beat("grupo_eco2") and read("grupo")
wait 1
choice grupo c4_grupo
  > Eu testei o primeiro ECO na Lumen. Não comprem isso. | set told_group_eco=true
  > O João é o único sensato neste grupo. | set told_group_eco=false
  > [Não responder]
end
wait 4
if flag("told_group_eco")
  grupo:pedro> espera. tu trabalhaste no ECO?
  grupo:pedro> isso explica porque é que nunca respondes a mensagens. é trauma
  grupo:marta> Pedro.
  grupo:pedro> desculpa
  wait 3
  grupo:joao> dani fala comigo depois. a serio
elif vs("told_group_eco") == "false"
  grupo:joao> finalmente alguem reconhece
  grupo:pedro> o nokia nem tem whatsapp. como é que estás a escrever isto
  grupo:joao> magia
endif
@end

@beat mae_sunday
@when at("17:10")
mae> amanhã é domingo. vens almoçar? fiz bacalhau
@end

@beat mae_sunday_reply
@when beat("mae_sunday") and read("mae")
wait 1
choice mae c4_mae
  > Este domingo não consigo, mãe. Desculpa. | set mae4=no
  > Vou tentar. Beijinho. | set mae4=maybe
end
wait 4
mae> esta bem filho. eu guardo-te um bocadinho
mae> e liga-me amanha. a tua irma diz que estas mais magro
@end
