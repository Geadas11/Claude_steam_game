# =====================================================================
# CAPÍTULO 8 — O SISTEMA
# segunda-feira, 12 de outubro de 2026, 09:30 → 21:00
# Opções de programador. O registo do sistema prevê acontecimentos — e eles
# acontecem. A captura de ecrã da mensagem ao Vasco. Ficheiros ocultos.
# A consola do ECO. "Talvez o problema não esteja dentro do telefone."
# =====================================================================
@chapter ch08
@title O Sistema
@start 2026-10-12 09:30

@beat setup
set chapter_n=8
set wifi_weird=true
rate 2
ambient room
location casa
battery 95
variant IMG_0317 closer
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
