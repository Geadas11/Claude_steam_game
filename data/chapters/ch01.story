# =====================================================================
# CAPÍTULO 1 — VIDA NORMAL
# quinta-feira, 8 de outubro de 2026, 21:30 → 00:40
# Objetivo: o telemóvel é só um telemóvel. Rotina, humor, cansaço.
# Plantar sementes: o dia 14, as insónias, o Saramago, o Vasco, as 03:17.
# Termina com a primeira mensagem e a fotografia tirada há três minutos.
# =====================================================================
@chapter ch01
@title Vida Normal
@start 2026-10-08 21:30

@beat setup
world phone on
ambient room
location casa
battery 64
set chapter_n=1
grupo:marta> {instant} amanhã há quiz no Farol!!! quem alinha
grupo:pedro> {instant} eu vou se o tema não for outra vez anos 80
sofia> {instant} Já jantaste?
email newsletter_bertrand
@end

# ---------------------------------------------------------------- Sofia
@beat sofia_talk
@when read("sofia") and not coop()
wait 1.5
sofia> E não me digas que comeste bolachas outra vez
choice sofia c1_sofia_dinner
  > Comi. Massa com atum, chef. | set dinner=massa
  > Ainda não tive fome | set dinner=nao
  > Bolachas são um jantar válido | set dinner=bolachas
end
wait 2
if vs("dinner") == "nao"
  sofia> Daniel.
  sofia> Vai comer qualquer coisa. Agora. Eu espero.
elif vs("dinner") == "bolachas"
  sofia> Não são nada
  sofia> Vou contar à mãe
  sofia> Brincadeira. Mais ou menos.
else
  sofia> Uau. Um adulto funcional
  sofia> Estou orgulhosa
endif
wait 3
sofia> Ouve, uma coisa
sofia> Para a semana é dia 14
typing sofia sofia 3
wait 1.5
sofia> Eu sei que não gostas de falar disso. Mas faz um ano. Posso ir aí no fim de semana se quiseres
choice sofia c1_sofia_visit
  > Não precisas. Estou bem, a sério | set sofia_visit=false
  > Se quiseres vir, vem | set sofia_visit=true
  > Mal a conhecia, Sofia. Não é preciso tanto drama | set sofia_visit=false said_barely_knew=true
end
wait 2.5
if flag("said_barely_knew")
  sofia> Ok.
  sofia> Não é drama, mano. Tu estiveste três semanas sem sair de casa.
  sofia> Mas pronto. Se mudares de ideias diz.
elif flag("sofia_visit")
  sofia> Ok!! Vou ver os turnos e digo-te. Sábado talvez
  sofia> Faço aquele arroz de pato que tu fingias não gostar
else
  sofia> Hmm. "Estou bem, a sério" é exatamente o que tu dizes quando não estás
  sofia> Mas ok. Não insisto. Hoje.
endif
wait 3
sofia> E estás a dormir? A Dra. Helena ainda te dá aquilo?
choice sofia c1_sofia_sleep
  > Durmo. Mais ou menos | set sleep_answer=meh
  > Durmo bem | set sleep_answer=lie
  > Acordo sempre à mesma hora. 3 e tal | set sleep_answer=317
end
wait 2
if vs("sleep_answer") == "317"
  sofia> Sempre à mesma hora?
  sofia> Isso é o corpo a habituar-se. Acontece muito nos doentes do turno da noite. Tenta não olhar para o relógio quando acordas
  sofia> Não olhes para o relógio. Promete
  set told_sofia_317=true
elif vs("sleep_answer") == "lie"
  sofia> Mentiroso
  sofia> Visto às 3h40 da manhã ontem. A app diz-me tudo
else
  sofia> Mais ou menos já é melhor que no ano passado
endif
wait 2
sofia> Tenho de ir, entro às 23h. Turno da noite, viva a saúde pública
sofia> Come. Dorme. Responde à mãe que ela já me ligou duas vezes a perguntar se estás vivo
sofia> Gosto de ti, parvalhão
set sofia_done=true
@end

@beat sofia_nudge
@when since("setup", 70) and not read("sofia") and not started("sofia_talk") and not coop()
sofia> Daniel?
wait 25
if not read("sofia")
  sofia> Visto às 21h31. Eu vejo, sabes
endif
@end

# ---------------------------------------------------------------- Grupo
@beat grupo_talk
@when read("grupo")
wait 1
grupo:joao> o tema é "cultura geral" o que significa que o pedro vai perder outra vez
grupo:pedro> eu ganhei em março
grupo:joao> ganhaste porque a pergunta era sobre bitcoin
grupo:marta> não acredito que estamos a ter esta conversa outra vez
grupo:marta> Daniel vens? precisamos de alguém que saiba coisas de livros
choice grupo c1_quiz
  > Vou. Alguém tem de salvar a equipa | set quiz=yes
  > Talvez. Depende do turno da livraria | set quiz=maybe
  > Estou muito cansado esta semana | set quiz=no
end
wait 2
if vs("quiz") == "yes"
  grupo:marta> ISSO
  grupo:joao> o homem voltou
  grupo:pedro> vou fazer reserva para 4 então
elif vs("quiz") == "maybe"
  grupo:joao> "talvez" do daniel = não
  grupo:marta> joão!!
  grupo:joao> que foi é verdade. mas eu guardo-te um lugar ao balcão
else
  grupo:marta> ok querido, descansa
  grupo:joao> fica a oferta. primeira cerveja é minha. segunda também se tiveres mau aspeto
endif
wait 4
grupo:pedro> já agora alguém viu o que estão a dizer da Lumen no jornal? vão abrir mais um edifício em Faro
grupo:pedro> as ações subiram 12%
grupo:marta> Pedro.
grupo:pedro> que foi
grupo:joao> pedro lê o grupo
grupo:pedro> ah
grupo:pedro> desculpa Daniel
choice grupo c1_lumen
  > Está tudo bem. Já não trabalho lá há quase um ano | set lumen_reply=calm
  > [Não responder] | set lumen_reply=silent
end
set grupo_done=true
@end

# ---------------------------------------------------------------- Carla
@beat carla_msg
@when since("setup", 40)
carla> Boa noite Daniel! Desculpa a hora
carla> Amanhã consegues abrir tu? Tenho dentista às 10h (que horror)
carla> E chegou finalmente a caixa da Caminho! Os Saramagos estão na arrecadação, se puderes arrumar na estante da literatura portuguesa
@end

@beat carla_reply
@when started("carla_msg") and read("carla")
wait 1
choice carla c1_carla
  > Claro, eu abro. Boa sorte no dentista | set carla_ok=true
  > Abro eu. Arrumo os Saramagos ao lado do outro | set carla_ok=true mentioned_other_book=true
end
wait 2
carla> És um anjo
if flag("mentioned_other_book")
  carla> Qual outro?
  carla> Ah, aquele "Ano da Morte de Ricardo Reis" que ninguém compra! Está lá desde que abri a loja, juro que já faz parte da mobília
  carla> Deixa-o estar, dá-me sorte
else
  carla> Não mexas no "Ano da Morte de Ricardo Reis" velho, é o meu amuleto. Está lá há séculos
endif
carla> Boa noite querido
set carla_done=true
@end

# ---------------------------------------------------------------- Mãe
@beat mae_msg
@when since("setup", 100)
mae> DANIEL JA JANTASTE
mae> desculpa estava em maiusculas
mae> a tua irma diz que nao respondes. estas bem filho
@end

@beat mae_reply
@when started("mae_msg") and read("mae")
wait 1
choice mae c1_mae
  > Estou bem mãe. Já jantei. Beijinhos | set mae_ok=true
  > Mãe, são quase 11 da noite, vai dormir :) | set mae_ok=true
end
wait 3
mae> ainda bem. domingo ligas
mae> e nao te esqueças que na quarta é aquilo. eu rezo por ela na missa
mae> :)
set mae_done=true
@end

# ---------------------------------------------------------------- Vasco
@beat vasco_msg
@when at("22:25") and beat("setup")
vasco> Boa noite, Daniel. Desculpe a hora.
vasco> Esta semana deve ser difícil para si. Para todos nós, na verdade.
vasco> Só queria que soubesse que a Lumen — e eu, pessoalmente — continuamos aqui. Se precisar de alguma coisa, qualquer coisa, ligue-me.
@end

@beat vasco_reply
@when started("vasco_msg") and read("vasco")
wait 1.5
choice vasco c1_vasco
  > Obrigado, Vasco. Agradeço tudo o que fez | inc trust_vasco 1
  > Estou bem. Obrigado. | set vasco_neutral=true
  > [Não responder] | set vasco_ignored=true
end
if not flag("vasco_ignored")
  wait 4
  vasco> Fico contente. Está a usar bem o telemóvel novo? Alguma coisa estranha, diga-me — ainda tenho contactos no suporte.
  set vasco_asked_phone=true
endif
@end

# ---------------------------------------------------------------- Helena (SMS)
@beat helena_sms
@when at("22:40")
helena> Clínica Atlântico: lembramos a sua consulta com Dra. Helena Sousa na quarta-feira, 14/10, às 17h00. Para desmarcar responda NÃO.
@end

# ---------------------------------------------------------------- João (privado)
@beat joao_check
@when at("23:05") and beat("setup")
joao> ei
joao> a tua irma mandou-me mensagem a perguntar se tu tas bem
joao> tas?
choice joao c1_joao
  > Estou. A Sofia exagera | set joao_ok=calm
  > Mais ou menos. Esta semana custa | set joao_ok=honest inc trust_joao 1
  > Diz-lhe para parar de pedir às pessoas para me vigiarem | set joao_ok=angry
end
wait 2.5
if vs("joao_ok") == "honest"
  joao> pois
  joao> eu sei
  joao> se quiseres aparecer no farol depois do fecho eu fico ate tarde. nao tens de falar de nada
elif vs("joao_ok") == "angry"
  joao> ela preocupa-se oh
  joao> ok ok. nao vigio nada. so pergunto
else
  joao> ok
  joao> se precisares de alguma coisa tou no bar ate as 2
endif
wait 3
joao> e nao te esqueças q me deves uma ida a pesca desde agosto
set joao_done=true
@end

# ---------------------------------------------------------------- explorar
@beat note_dream
@when viewed("IMG_1433") or opened("notes")
set explored=true
@end

@beat late_quiet
@when at("23:35")
# a casa fica mais silenciosa. o frigorífico deixa de zumbir.
ambient hum
@end

# ---------------------------------------------------------------- A PRIMEIRA MENSAGEM
@beat first_message
@when at("23:47") and (beat("sofia_talk") or beat("co_done") or at("00:10"))
ambient off
wait 2
vibrate
unknown> {instant} Ainda estás acordado?
set first_msg=true
if flag("prev_end_D")
  wait 5
  unknown> Outra vez.
endif
@end

@beat first_nudge
@when since("first_message", 45) and not read("unknown")
vibrate
unknown> {instant} ?
@end

@beat first_reply
@when beat("first_message") and read("unknown")
wait 1
choice unknown c1_who
  > Quem é? | set reply_who=true
  > Sim. Quem fala? | set reply_who=true
  > [Ignorar] | set ignored_1=true
end
if flag("ignored_1")
  wait 30
  unknown> Eu sei que estás.
  wait 4
  unknown> Estás no sofá.
  choice unknown c1_who2
    > Quem é? | set reply_who=true
    > [Ignorar outra vez] | set ignored_2=true
  end
endif
if flag("reply_who")
  achieve first_message
  typing unknown unknown 4
  wait 2
  typing unknown unknown 2
  unknown> Sou eu.
  choice unknown c1_me
    > Eu quem? | set asked_eu_quem=true
    > Não tenho este número guardado | set said_not_saved=true
    > [Não responder]
  end
  wait 3
endif
typing unknown unknown 6
wait 3
unknown> {instant} [photo:IMG_6612]
set got_window_photo=true
@end

@beat after_photo
@when beat("first_reply")
wait 6
if not viewed("IMG_6612")
  unknown> Abre.
  wait 12
endif
unknown> Não te levantes.
choice unknown c1_photo
  > Quem tirou esta fotografia? | set asked_photographer=true
  > Isto não tem piada nenhuma | set said_not_funny=true
  > [Ir à janela] | set went_window=true
end
if flag("went_window")
  screenoff 4
  sound door
  wait 3
  unknown> Não está ninguém, pois não?
  wait 3
  unknown> Nunca está.
elif flag("asked_photographer")
  wait 3
  unknown> Ainda não sabes.
  wait 2
  unknown> Mas já soubeste.
else
  wait 4
  unknown> Não é para ter.
endif
wait 6
unknown> Dorme, Daniel.
set unknown_knows_name=true
wait 2.5
unknown> Amanhã falamos.
checkpoint
wait 8
notify gallery "Fotografias" "IMG_6612.jpg guardada automaticamente"
wait 10
@end

@beat end_ch1
@when beat("after_photo")
wait 6
ambient room
wait 3
lock
wait 2
endchapter
@end

# ---------------------------------------------------------------- Marta e Pedro (normalidade)
@beat marta_private
@when since("setup", 160)
marta> Daniel, pergunta de professora desesperada
marta> Tenho um 9.º ano que odeia ler. Preciso de um livro que não os mate de tédio. Tu és o homem dos livros
@end

@beat marta_reply
@when beat("marta_private") and read("marta")
wait 1
choice marta c1_marta
  > "Os da Minha Rua", do Ondjaki. Curto, engraçado, e acaba por doer. | set marta_book=ondjaki
  > "O Principezinho". Eles acham que é infantil até à página 20. | set marta_book=principe
  > Dá-lhes o manual de instruções do telemóvel. Assusta mais. | set marta_book=manual
end
wait 3
if vs("marta_book") == "manual"
  marta> ahahah
  marta> não me dês ideias. eles leem os termos e condições do tiktok com mais atenção do que o Camões
else
  marta> Anotado! Vou encomendar na Maré. Fazes-me desconto de amiga?
  marta> (a resposta é sim)
endif
wait 3
marta> Obrigada querido. Amanhã no quiz pago-te um gin
@end

@beat pedro_pitch
@when at("22:55")
pedro> Daniel, pergunta séria
pedro> Tu percebes disto. Achas que devo comprar ações da Lumen? Com o ECO 2 vão disparar
@end

@beat pedro_reply
@when beat("pedro_pitch") and read("pedro")
wait 1
choice pedro c1_pedro
  > Não sei, Pedro. Eu só testava aquilo. | set pedro_eco=neutral
  > Eu não punha lá um cêntimo. | set pedro_eco=against
  > Compra. Assim quando correr mal tens alguém a quem culpar. | set pedro_eco=joke
end
wait 3
if vs("pedro_eco") == "against"
  pedro> uau. tu sabes alguma coisa que eu não sei
  pedro> ok ok. não insisto. mas se dispararem não te dou nada
elif vs("pedro_eco") == "joke"
  pedro> isso é um sim
  pedro> vou comprar 3 ações. as minhas economias todas
else
  pedro> ok. vou perguntar ao chatbot do banco
endif
@end


# =====================================================================
# MODO COOPERATIVO — a Sofia é outra pessoa a jogar (data/sofia/chapters/ch01.story).
# As linhas dela chegam pela rede; aqui o Daniel só responde.
# =====================================================================
@beat co_dinner
@when coop() and read("sofia")
wait 1
choice sofia c1_sofia_dinner
  > Comi. Massa com atum, chef. | set dinner=massa
  > Ainda não tive fome | set dinner=nao
  > Bolachas são um jantar válido | set dinner=bolachas
end
@end

@beat co_visit
@when coop() and beat("co_dinner") and v("net_in") >= 2
wait 1
choice sofia c1_sofia_visit
  > Não precisas. Estou bem, a sério | set sofia_visit=false
  > Se quiseres vir, vem | set sofia_visit=true
  > Mal a conhecia, Sofia. Não é preciso tanto drama | set sofia_visit=false said_barely_knew=true
end
@end

@beat co_sleep
@when coop() and beat("co_visit") and v("net_in") >= 4
wait 1
choice sofia c1_sofia_sleep
  > Durmo. Mais ou menos | set sleep_answer=meh
  > Durmo bem | set sleep_answer=lie
  > Acordo sempre à mesma hora. 3 e tal | set sleep_answer=317 told_sofia_317=true
end
@end

@beat co_done
@when coop() and beat("co_sleep") and (v("net_in") >= 5 or at("23:10"))
set sofia_done=true
@end
