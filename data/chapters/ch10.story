# =====================================================================
# CAPÍTULO 10 — CONSEQUÊNCIAS
# terça-feira, 13 de outubro de 2026, 10:00 → 22:30
# As escolhas pagam-se. Quem confiou em quem. A Helena liga à Sofia.
# O João saiu do grupo — ou ficou. O cartão está dentro do livro.
# O que fazer com ele.
# =====================================================================
@chapter ch10
@title Consequências
@start 2026-10-13 10:00

@beat setup
set chapter_n=10
rate 2
ambient room
location livraria
battery 80
carla> {instant} Bom dia querido! Hoje estou cá a tarde toda, se quiseres sair mais cedo
@end

# ---------------------------------------------------------------- João: ficou ou foi
@beat joao_status
@when since("setup", 20)
if v("trust_joao") >= 2 or flag("joao_ally")
  joao> bom dia. dormiste?
  joao> se precisares q va contigo a algum lado hoje, eu vou. o bar abre so as 6
  set joao_available=true
elif flag("joao_drifting") or flag("promised_helena") or v("trust_joao") < 0
  grupo:marta> joão? saíste do grupo?
  grupo:pedro> deve ter sido sem querer
  hidethread joao
  set joao_gone=true
  clue joao_left
else
  joao> dani. tou aqui se precisares
  set joao_available=true
endif
@end

@beat joao_help
@when flag("joao_available") and app() == "messages:joao"
choice joao c10_joao
  > Preciso que venhas comigo ao cais esta noite. | set joao_coming=true inc trust_joao 1
  > Obrigado. Fica perto do telemóvel. | set joao_standby=true
end
wait 8
if flag("joao_coming")
  joao> as 3?
  joao> eu sei q é as 3 dani. toda a gente na salgueira sabe a hora
  joao> la estarei
else
  joao> sempre
endif
@end

# ---------------------------------------------------------------- o livro
@beat book_prompt
@when at("11:00") and (clue("saramago_spine") or clue("night_bookshop") or clue("daniel_hides_in_books") or clue("ines_card_hint") or clue("secret_note_book") or clue("carla_photo_in_book") or v("deduction_score") >= 4)
unknown> Estás à frente da estante.
wait 3
unknown> Já sabes qual é.
set book_prompted=true
@end

@beat book_carla
@when at("13:00") and not flag("found_card")
carla> Daniel, o meu Ricardo Reis está esquisito. A capa de trás está inchada, parece que tem alguma coisa lá dentro
carla> Vê lá isso, que eu não tenho jeito para estas coisas e tenho medo de o estragar
set book_prompted=true book_via_carla=true
@end

@beat book_choice
@when flag("book_prompted") and (read("unknown") or read("carla"))
wait 2
if flag("book_via_carla")
  choice carla c10_book_carla
    > [Abrir "O Ano da Morte de Ricardo Reis"] | set open_book=true
    > [Deixar o livro onde está] | set open_book=false
  end
else
  choice unknown c10_book
    > [Abrir "O Ano da Morte de Ricardo Reis"] | set open_book=true
    > [Deixar o livro onde está] | set open_book=false
  end
endif
if flag("open_book")
  sound click_far
  wait 2
  toast "Dentro da capa: um cartão microSD, colado com fita-cola."
  wait 2
  file mare_leiame silent
  file mare_contrato silent
  file mare_emails silent
  file mare_utentes silent
  notify files "Cartão SD" "MARÉ (cartão) · 4 ficheiros"
  set found_card=true
  achieve found_card
  clue card_found
  wait 10
  unknown> Estava onde a maré não chega.
  wait 3
  unknown> Tu escondeste-o às 04:12. Nunca o tiraste de lá.
else
  wait 8
  unknown> Está bem.
  wait 3
  unknown> Está lá há um ano. Pode esperar mais umas horas.
  set book_left=true
endif
@end

@beat book_second_chance
@when flag("book_left") and at("17:30") and not flag("found_card")
unknown> Vais fechar a loja.
unknown> Última vez que te peço.
choice unknown c10_book2
  > [Abrir o livro] | set found_card=true
  > [Fechar a loja e ir para casa] | set card_abandoned=true
end
if flag("found_card")
  toast "Dentro da capa: um cartão microSD, colado com fita-cola."
  file mare_leiame silent
  file mare_contrato silent
  file mare_emails silent
  file mare_utentes silent
  notify files "Cartão SD" "MARÉ (cartão) · 4 ficheiros"
  achieve found_card
  clue card_found
endif
@end

@beat letter_read
@when file_open("mare_leiame")
wait 15
unknown> Não leias outra vez.
wait 4
unknown> Eu sei que vais ler outra vez.
@end

# ---------------------------------------------------------------- Helena e Sofia
@beat helena_bed
@when at("10:40")
helena> A sua cama está pronta às 14h, Daniel. Venha, por favor. É para seu bem.
@end

@beat helena_calls_sofia
@when at("14:30")
helena> Não apareceu. Vou ter de falar com a sua família. Lamento.
wait 60
sofia> Daniel
sofia> A tua médica acabou de me ligar. Disse que estás "em risco" e que eu devia convencer-te a seres internado HOJE
sofia> Ela sabia o meu número. Eu nunca lhe dei o meu número
sofia> O que se passa??
clue helena_called_sofia
@end

@beat sofia_truth
@when beat("helena_calls_sofia") and read("sofia")
wait 1
choice sofia c10_sofia
  > Sofia, eu vou contar-te tudo. Mas tens de acreditar em mim. | set told_sofia_all=true
  > Estou bem. Ela exagera. | set told_sofia_all=false
end
wait 6
if flag("told_sofia_all")
  sofia> Conta
  wait 30
  sofia> ...
  wait 8
  sofia> Ok. Ok ok ok
  sofia> Eu acredito em ti. Acho que sempre soube que havia mais alguma coisa
  sofia> Não vás sozinho a lado nenhum esta noite. Prometes?
  set sofia_knows=true
else
  sofia> "Estou bem" outra vez. Tu e o teu "estou bem"
  sofia> Liga-me esta noite. Por favor
endif
@end

# ---------------------------------------------------------------- o que fazer com o cartão
@beat vasco_offer
@when at("15:30")
vasco> Daniel, sei que encontrou uma coisa hoje.
vasco> Não lhe vou perguntar como sei. Vou-lhe só fazer uma proposta honesta.
vasco> Entregue-ma. Em troca: a sua vida de volta. O emprego na Lumen, se quiser. A Dra. Helena deixa de o incomodar. A Sofia deixa de se preocupar. Tudo como antes.
@end

@beat vasco_offer_reply
@when beat("vasco_offer") and read("vasco")
wait 1
choice vasco c10_vasco
  > {if flag("found_card")} Está bem. Encontramo-nos no cais esta noite. Às 3. | set plan_give_vasco=true inc trust_vasco 2
  > Nunca. | set refused_vasco_card=true inc trust_vasco -1
  > O senhor matou-a. | set accused_vasco=true inc trust_vasco -2
  > [Não responder]
end
wait 10
if flag("plan_give_vasco")
  vasco> Fez a escolha certa. Às 3, então. Leve um casaco, vai estar nevoeiro.
elif flag("accused_vasco")
  typing vasco vasco 10
  wait 4
  vasco> A Inês caiu, Daniel. Eu tentei agarrá-la.
  wait 4
  vasco> Ninguém vai acreditar num homem que não se lembra de onde esteve às 11h de domingo.
  set vasco_admitted_presence=true
  clue vasco_tried_to_grab
elif flag("refused_vasco_card")
  vasco> Lamento ouvir isso. Lamento mesmo.
endif
@end

@beat send_clara
@when flag("found_card") and phone("clara_known") and app() == "messages:clara"
choice clara c10_clara
  > [Enviar os ficheiros do cartão à Clara] | set sent_clara=true
  > [Ainda não]
end
if flag("sent_clara")
  wait 20
  clara> Recebi.
  wait 30
  clara> Meu Deus.
  wait 10
  clara> A lista de utentes... Daniel, a linha 2208. Idade 29. Stress pós-traumático. Vendido à Meridiano.
  clara> Acho que é você.
  clue daniel_in_list
  wait 8
  clara> Preciso de uma coisa: a gravação do cais. Sem ela é a palavra da Lumen contra um documento. Com ela, é um homicídio.
  set clara_has_card=true
endif
@end

@beat send_clara_rec
@when flag("clara_has_card") and flag("heard_recording") and app() == "messages:clara"
choice clara c10_clara_rec
  > [Enviar a gravação "cais_0309.m4a"] | set sent_recording=true
  > [Ainda não]
end
if flag("sent_recording")
  wait 30
  clara> Ouvi.
  wait 15
  clara> Publicamos amanhã às 7h. A PJ vai ter tudo às 6h.
  clara> Não esteja sozinho esta noite.
  set evidence_sent=true
endif
@end

@beat send_rui
@when flag("found_card") and phone("rui_known") and app() == "messages:rui"
choice rui c10_rui
  > [Enviar a gravação e os ficheiros ao Rui] | set sent_rui=true inc trust_rui 1
  > [Ainda não]
end
if flag("sent_rui")
  wait 60
  rui> ...
  wait 30
  rui> Ouvi a voz dela.
  wait 10
  rui> Vou ao cais esta noite. Às 3. Não é preciso vires. Mas se vieres, eu não te bato.
  set rui_coming=true
endif
@end

# ---------------------------------------------------------------- noite
@beat sim_notice10
@when at("18:30")
notify settings "Lumen OS" "eco.sim 047 · 1 dia restante"
location casa
@end

@beat card_nudge
@when at("19:30") and flag("found_card") and not flag("sent_clara") and not flag("sent_rui") and not flag("plan_give_vasco")
unknown> Tens o cartão. Tens a gravação. Tens a noite.
unknown> A Clara. O Rui. Ou ninguém. Mas decide.
@end

@beat last_ask
@when at("22:10")
unknown> Amanhã faz um ano.
wait 4
unknown> Vem ter comigo ao cais.
wait 3
unknown> 03:17.
choice unknown c10_last
  > Vou. | set will_go=true
  > Não vou. | set will_go=false
  > Porquê? | set asked_why_pier=true
end
wait 8
if flag("asked_why_pier")
  unknown> Porque é a última vez que me consegues responder.
  set will_go=true
elif vs("will_go") == "false"
  unknown> Vais.
  wait 2
  unknown> Em 46 vezes foste sempre.
else
  unknown> Leva um casaco. Vai estar nevoeiro.
  set vasco_echo=true
endif
checkpoint
wait 6
@end

@beat end_ch10
@when beat("last_ask")
wait 6
lock
wait 2
endchapter
@end

@call joao c10_call_joao
@when flag("joao_gone")
- O número que marcou não está disponível de momento.
@end

@call helena c10_call_helena
helena: Daniel. Ainda vai a tempo. | 2
helena: Venha. Não tem de fazer isto sozinho. | 3
@end

# ---------------------------------------------------------------- o grupo repara
@beat grupo_worried
@when at("12:15")
if flag("joao_gone")
  grupo:marta> o João saiu do grupo e não atende ninguém. Daniel aconteceu alguma coisa entre vocês?
  grupo:pedro> ele nunca sai do grupo. nem quando eu mandei aquele vídeo de 40 minutos
else
  grupo:marta> Daniel, o João diz que andas esquisito. estamos aqui, ok?
  grupo:pedro> eu também estou aqui. tecnicamente
endif
@end

@beat grupo_worried_reply
@when beat("grupo_worried") and read("grupo")
wait 1
choice grupo c10_grupo
  > Obrigado. Amanhã explico tudo. Prometo. | set grupo10=promise
  > Estou bem. Não se preocupem. | set grupo10=fine
end
wait 4
if vs("grupo10") == "promise"
  grupo:marta> vamos cobrar
  grupo:pedro> com juros
else
  grupo:marta> "estou bem". claro
  grupo:marta> ok. estamos aqui na mesma
endif
@end

@beat meridiano_exclusao_mail
@when at("16:20")
email meridiano_exclusao
@end

# ---------------------------------------------------------------- Rita
@beat rita_count
@when flag("rita_keep") and (flag("sent_clara") or flag("sent_rui")) and at("19:10")
rita> a jornalista falou comigo. a clara
rita> somos quarenta e um. quarenta e um telemóveis oferecidos pela clínica
rita> quarenta e um mortos a escrever às 3:17
clue forty_one
@end

# ---------------------------------------------------------------- a porta destrancada
@beat carla_door
@when flag("found_card") and at("13:40")
carla> Encontraste alguma coisa no meu Ricardo Reis? Passei aí e estavas pálido
@end

@beat carla_door_reply
@when beat("carla_door") and read("carla")
wait 1
choice carla c10_carla
  > Encontrei. Uma coisa que eu lá escondi há um ano e não me lembrava. | set told_carla_card=true
  > Não. Só pó. | set told_carla_card=false
end
wait 10
if flag("told_carla_card")
  carla> Há um ano...
  carla> Daniel, nunca disse isto a ninguém. Na manhã de 14 de outubro do ano passado, quando cheguei, a porta da loja estava destrancada
  carla> Pensei que me tinha esquecido. Passei o dia a achar que estava a ficar velha
  wait 4
  carla> Mas tu ainda não trabalhavas cá. Como é que tinhas a chave?
  wait 6
  carla> Ah. A Inês. A Inês tinha uma chave. Eu dei-lha porque ela vinha ler de manhã cedo. Ela deu-ta?
  clue shop_unlocked
else
  carla> Só pó. Ok. Esse livro tem mais pó do que histórias
endif
@end

# ---------------------------------------------------------------- o Vasco envia a primeira fotografia
@beat vasco_photo
@when flag("refused_vasco_card") or flag("accused_vasco")
wait 90
vasco> [photo:IMG_6612] Descanse, Daniel.
set vasco_sent_window=true
wait 15
unknown> Foi ele que te mandou essa fotografia agora.
wait 3
unknown> Não fui eu que a tirei há cinco dias. Mas também não foi ele.
clue vasco_sent_window
@end


# ---------------------------------------------------------------- uma mensagem de voz
@beat voice_note
@when at("10:25") and not flag("found_card")
unknown> [audio:vm_audio_ines]
@end
