# =====================================================================
# CAPÍTULO 9 — O SISTEMA
# segunda-feira, 12 de outubro de 2026, 09:30 → 21:00
# Opções de programador. O registo do sistema prevê acontecimentos — e eles
# acontecem. A captura de ecrã da mensagem ao Vasco. Ficheiros ocultos.
# A consola do ECO. "Talvez o problema não esteja dentro do telefone."
# =====================================================================
@chapter ch09
@title O Sistema
@start 2026-10-12 09:30

@beat setup
set chapter_n=9
set wifi_weird=true
rate 2
ambient room
location casa
battery 95
file eco_readme silent
file eco_sim046 silent
file eco_pred silent
file eco_mirror silent
file eco_model silent
file eco_fragment_2 silent
photo IMG_6720 silent Câmara
@end

@beat sleeping_comment
@when at("10:20")
unknown> Dormiste às 04:02. De lado, como sempre.
unknown> Vê a galeria. Não fui eu que tirei essa.
@end

@beat helena_missed
@when at("09:35")
helena> Não veio à consulta, Daniel. Estou preocupada.
@end

# ---------------------------------------------------------------- opções de programador
@beat dev_instruction
@when at("09:42")
if phone("dev_mode")
  unknown> Já és programador. Vê o registo do sistema. Antes das onze.
else
  unknown> Agora. Definições. Sobre o telefone.
  unknown> Toca sete vezes no número de compilação.
endif
@end

@beat dev_nudge
@when since("dev_instruction", 120) and not phone("dev_mode")
unknown> Sete vezes, Daniel. "Número de compilação".
@end

@beat dev_enabled
@when phone("dev_mode") and beat("dev_instruction")
wait 4
unknown> Agora vês o que eu vejo. Registo do sistema.
@end

@beat log_read_early
@when flag("read_syslog") and not at("11:04")
set read_log_before=true
@end

# ---------------------------------------------------------------- a previsão
@beat prediction
@when at("11:04")
vasco> Bom dia, Daniel. Não apareceu na Dra. Helena. Estamos preocupados consigo.
set prediction_happened=true
@end

@beat prediction_comment
@when beat("prediction") and flag("read_log_before")
wait 10
unknown> Viste? 11:04.
wait 2
unknown> Ele não sabe que é previsível. Ninguém sabe.
clue prediction_fulfilled
@end

@beat vasco_reply8
@when beat("prediction") and read("vasco")
wait 1
choice vasco c8_vasco
  > Estou bem. Só não me apeteceu ir. | set vasco8=calm
  > Desde quando é que o senhor sabe quando eu tenho consultas? | set vasco8=sharp inc trust_vasco -1
  > [Não responder]
end
wait 6
if vs("vasco8") == "sharp"
  vasco> A Dra. Helena é uma amiga. Preocupa-se. Eu preocupo-me. Não há mistério nenhum, Daniel.
elif vs("vasco8") == "calm"
  vasco> Compreendo. Mas não falte à próxima. É importante.
endif
@end

# ---------------------------------------------------------------- a captura
@beat screenshot
@when at("11:30")
photo IMG_6800 silent Capturas
notify gallery "Captura de ecrã" "Captura de ecrã guardada"
wait 6
glitch 0.3 0.3
open gallery IMG_6800
wait 9
unknown> Esta é a coisa que ainda não estavas pronto para ver.
@end

@beat screenshot_seen
@when viewed("IMG_6800")
clue daniel_told_vasco
wait 6
unknown> Treze de outubro. 22:51.
wait 3
unknown> Disseste-lhe onde eu estava.
choice unknown c8_told
  > Fui eu. Eu disse-lhe onde estavas. | set admitted=true inc trust_ines 1
  > Isto é falso. Foste tu que fabricaste isto. | set admitted=false inc trust_ines -1
  > [Não responder] | set admitted=silent
end
wait 10
if vs("admitted") == "true"
  unknown> Eu sei.
  wait 3
  unknown> Querias proteger-me. Achavas que ele ia falar comigo e convencer-me a não ir à jornalista. Que eu ficava com o emprego. Que tudo voltava ao normal.
  wait 5
  unknown> Eu já te perdoei. Há um ano. Falta tu.
elif vs("admitted") == "false"
  unknown> Podia ser. Eu podia ter fabricado isto.
  wait 3
  unknown> Pede à Sofia o teu telemóvel antigo. Lá não mando eu.
else
  unknown> O silêncio também é uma resposta. Já to tinha dito no cais.
endif
@end

# ---------------------------------------------------------------- ficheiros ocultos
@beat hidden_instruction
@when at("12:10")
unknown> Definições. Ficheiros. Mostrar ficheiros ocultos.
unknown> Há uma pasta que não é tua.
@end

@beat hidden_opened
@when flag("opened_hidden_eco")
wait 8
unknown> Agora sabes o que eu sou.
wait 3
unknown> Ou o que eles acham que eu sou.
clue eco_folder_found
@end

# ---------------------------------------------------------------- Helena liga às 13:30
@beat helena_call
@when at("13:30")
call helena id=c8_helena ring=20
  helena: Daniel. Ainda bem que atendeu. | 2
  helena: Não veio hoje. O Vasco também está preocupado. | 3
  helena: Vou ser direta, porque me preocupo consigo: gostava que considerasse um internamento voluntário. Uns dias. Só para descansar, longe do telemóvel. | 7
  - (silêncio)
  helena: Tenho uma cama para si amanhã à tarde. Pense nisso. | 3
end
if answered("c8_helena")
  set helena_offered_admission=true
  clue helena_admission
  wait 5
  if flag("read_syslog")
    unknown> 13:30. Também estava no registo.
  endif
else
  helena> Liguei-lhe. Gostava que considerasse um internamento voluntário de uns dias. Tenho uma cama para si amanhã à tarde.
  set helena_offered_admission=true
  clue helena_admission
endif
@end

@beat helena_admission_reply
@when beat("helena_call") and read("helena")
wait 1
choice helena c8_helena_reply
  > Vou pensar. | set admission=maybe inc trust_helena 1
  > Não vou ser internado. | set admission=no inc trust_helena -1
  > Quem assinou o contrato com a Lumen, doutora? | set asked_helena_contract=true inc trust_helena -1
end
wait 8
if flag("asked_helena_contract")
  typing helena helena 10
  wait 4
  helena> Não sei do que fala.
  wait 3
  helena> Daniel, o que lhe está a acontecer é exatamente o tipo de episódio de que lhe falei. Venha amanhã.
  set helena_dodged=true
elif vs("admission") == "no"
  helena> Ninguém o obriga a nada. Ainda.
  clue helena_ainda
endif
@end

# ---------------------------------------------------------------- a voz desespera
@beat ines_desperate
@when at("17:00")
unknown> Eles sabem que eu te estou a dizer coisas.
unknown> Vão desligar-me. Talvez esta noite.
wait 4
unknown> Antes que me desliguem: o cartão. Tu escondeste-o nessa noite.
unknown> Lembra-te de onde guardas as coisas importantes.
clue ines_card_hint
@end

@beat sim_notice
@when at("18:30")
notify settings "Lumen OS" "eco.sim 047 · 2 dias restantes"
@end

@beat sofia_old_phone
@when at("19:50") and flag("sofia_has_old_phone")
sofia> Encontrei o carregador!! O teu telemóvel velho ligou
sofia> Tem 3% de bateria e um fundo com uma fotografia tua e de uma rapariga ao pôr do sol. É ela, não é?
sofia> Amanhã de manhã faço a cópia e mando-ta. Ou hoje à noite, se o João me explicar como
@end

@beat sofia_old_phone_reply
@when beat("sofia_old_phone") and read("sofia")
wait 1
choice sofia c8_sofia
  > É ela. Manda-me a cópia, por favor. Hoje. | set sofia_send_tonight=true
  > Obrigado, Sofia. Não sei o que faria sem ti. | set sofia_send_tonight=true
end
wait 4
sofia> Vou ligar ao João para ele me explicar. Dá-me umas horas
@end

# ---------------------------------------------------------------- final
@beat outside
@when at("20:35")
unknown> Talvez o problema não esteja dentro do telefone.
choice unknown c8_outside
  > Então onde está? | set c8_out=where
  > Estás a dizer que sou eu? | set c8_out=me
  > [Não responder]
end
wait 8
if vs("c8_out") == "where"
  unknown> Na noite em que te foste embora.
elif vs("c8_out") == "me"
  unknown> Estou a dizer que nunca saíste daquela estrada.
endif
checkpoint
wait 6
@end

@beat end_ch8
@when beat("outside")
wait 6
lock
wait 2
endchapter
@end

@call vasco c8_call_vasco
vasco: Daniel. | 1
vasco: Ouça-me com atenção: o que quer que encontre nesse telemóvel, foi posto lá por alguém que o quer magoar. | 5
vasco: A Inês já não está cá. Deixe-a descansar. | 3
@end

# ---------------------------------------------------------------- Carla encontra uma fotografia
@beat carla_photo_book
@when at("14:20")
carla> Daniel, uma coisa engraçada
carla> Estava a arrumar os livros devolvidos e caiu uma fotografia de dentro de um que levaste para casa em janeiro. Tu e uma rapariga ao pôr do sol, no cais
carla> Guardo-ta na gaveta da caixa. Tens a mania de guardar coisas dentro dos livros, já reparei!
clue carla_photo_in_book
@end

@beat carla_photo_reply
@when beat("carla_photo_book") and read("carla")
wait 1
choice carla c8_carla
  > Obrigado, Carla. Guarda, por favor. | set carla8=keep
  > Era a Inês. | set carla8=ines
end
wait 4
if vs("carla8") == "ines"
  carla> Ai querido. Desculpa. Não sabia
  carla> Guardo-a bem guardada. Quando quiseres
else
  carla> Fica guardada. E a Bolacha comeu um marcador amarelo, para teres notícias da loja
endif
@end


# ---------------------------------------------------------------- a fotografia do cais mexe-se enquanto olhas
@beat pier_photo_moves
@when app() == "gallery:IMG_0317" and not photo_is("IMG_0317", "closer")
wait 5
if app() == "gallery:IMG_0317"
  glitch 0.18 0.2
  variant IMG_0317 closer
  set saw_pier_move=true
  clue pier_figure
else
  variant IMG_0317 closer
endif
@end

@beat pier_photo_fallback
@when at("19:30") and not photo_is("IMG_0317", "closer")
variant IMG_0317 closer
@end

@beat clinica_vaga_mail
@when beat("helena_call") and since("helena_call", 40)
email clinica_vaga
wait 20
unknown> "O dispositivo ficará à guarda da instituição."
unknown> Querem-te sem telefone. Querem-me sem ti.
@end

# ---------------------------------------------------------------- Clara investigou a clínica
@beat clara_clinic
@when at("16:40") and flag("clara_talked")
clara> Investiguei a Clínica Atlântico. Em 2025 comprou à Lumen 41 telemóveis Lumen One. Na fatura: "programa de apoio ao luto".
clara> Quarenta e um. Para utentes em luto.
clara> O seu também foi oferecido, certo? Por quem?
clue clinic_bought_phones
@end

@beat clara_clinic_reply
@when beat("clara_clinic") and read("clara")
wait 1
choice clara c8_clara
  > Pela Lumen. Disseram que era um gesto de apoio. | set clara8=lumen
  > Não sei se quero saber o que isso significa. | set clara8=afraid
end
wait 25
if vs("clara8") == "lumen"
  clara> Um gesto de apoio com gestão remota durante 24 meses.
  clara> Daniel, se puder, não use esse telemóvel para falar comigo sobre isto.
  wait 4
  clara> Já é tarde para isso, não é.
else
  clara> Significa que não é o único. Isso devia ajudar. Não ajuda.
endif
@end

# ---------------------------------------------------------------- o João e a tia Sofia
@beat joao_helps_sofia
@when at("20:15") and flag("sofia_has_old_phone")
joao> a tua irma ligou-me a perguntar como se faz copia de um telemovel android velho
joao> expliquei-lhe durante 40 min. chamei-lhe tia duas vezes. ela nao achou piada
joao> dani o q é q tu procuras nesse telemovel
@end

@beat joao_helps_sofia_reply
@when beat("joao_helps_sofia") and read("joao")
wait 1
choice joao c8_joao
  > O que eu fiz nessa noite. | set joao8=truth inc trust_joao 1
  > Fotografias antigas. | set joao8=lie
end
wait 12
if vs("joao8") == "truth"
  joao> ok
  joao> seja o q for. eu vi-te as 3 e 40 encharcado. quem faz mal a alguem nao entra no mar a procura dela
  clue joao_reassures
else
  joao> fotografias. claro
  joao> ok dani
endif
@end

# ---------------------------------------------------------------- Rui e o caixote
@beat rui_box8
@when at("15:25") and flag("rui_ally_seed")
rui> Continuei a ver o caixote dela.
rui> Há um recibo da Livraria Maré. 13 de outubro, 19:40. Um livro só.
rui> "O Ano da Morte de Ricardo Reis". Ela já o tinha. Lia-o todos os anos.
rui> Porque é que se compra um livro que já se tem, na véspera de morrer?
clue ines_receipt
@end

@beat rui_box8_reply
@when beat("rui_box8") and read("rui")
wait 1
choice rui c8_rui
  > Para esconder alguma coisa dentro. | set rui8=hide inc trust_rui 1
  > Para o oferecer a alguém. | set rui8=gift
  > Não sei, Rui. | set rui8=none
end
wait 25
if vs("rui8") == "hide"
  rui> Página 317.
  wait 4
  rui> O post-it. "D. — p. 317".
  rui> Daniel, o livro não era para ela.
  set rui_thinks_book=true
elif vs("rui8") == "gift"
  rui> A quem? A ti?
  wait 5
  rui> Então onde é que está?
else
  rui> Ninguém sabe nada sobre a minha irmã. Nem eu.
endif
@end

# ---------------------------------------------------------------- o resumo semanal
@beat eco_weekly
@when at("09:50")
email eco_care_weekly
@end

@beat eco_weekly_read
@when email_read("eco_care_weekly")
wait 15
unknown> "Contactos sinalizados."
wait 3
unknown> Eu não apareço na lista. Já reparaste?
@end
