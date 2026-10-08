# =====================================================================
# CAPÍTULO 5 — O TELEFONE COMEÇA A MUDAR
# sábado 10 → domingo 11 de outubro, 22:30 → 04:10
# Progressão gradual: uma mensagem antiga muda. Uma mensagem enviada que
# não enviaste. Pesquisas que não fizeste. Uma nota do futuro. A câmara.
# Uma fotografia tirada por trás. O reinício e o PIN. Quinze minutos de
# silêncio. Três pancadas.
# =====================================================================
@chapter ch05
@title O Telefone Começa a Mudar
@start 2026-10-10 22:30

@beat setup
set chapter_n=5
rate 1
ambient room
location casa
battery 64
file thumb_0317 silent
@end

# ---------------------------------------------------------------- 1. a mensagem que mudou
@beat sofia_edit
@when at("22:41")
edit sofia sofia_arrive "Cheguei ontem."
set sofia_msg_changed=true
@end

@beat sofia_normal
@when at("23:15")
sofia> Turno calmo hoje. Milagre
sofia> Estás bem? Desculpa outra vez por não ir
@end

@beat sofia_normal_reply
@when beat("sofia_normal") and read("sofia")
wait 1
choice sofia c5_sofia
  > {if has_msg("sofia", "sofia_arrive")} Sofia, a tua mensagem de ontem diz "Cheguei ontem." | set asked_sofia_arrive=true
  > Estou bem. Bom turno | set asked_sofia_arrive=false
end
if flag("asked_sofia_arrive")
  wait 5
  sofia> Cheguei onde? Estou no hospital, mano
  sofia> Eu escrevi "Chego amanhã". E depois disse-te que já não podia ir
  wait 3
  sofia> Daniel. Olha bem para a mensagem
  choice sofia c5_sofia2
    > Diz "Cheguei ontem." Estou a olhar para ela agora. | set insisted=true
    > Tens razão. Devo ter lido mal. | set insisted=false
  end
  wait 6
  if flag("insisted")
    sofia> Estás a assustar-me
    sofia> Amanhã de manhã ligo-te. Se não atenderes chamo o João
    clue sofia_message_changed
  else
    sofia> Vai dormir. A sério
  endif
endif
@end

# ---------------------------------------------------------------- 2. a nota
@beat note_door
@when at("23:02")
note note_porta
@end

# ---------------------------------------------------------------- 3. a mensagem que não enviaste
@beat sent_rui
@when at("23:25")
me@rui> {time=02:14} Desculpa.
set sent_without_me=true
@end

@beat rui_reply5
@when beat("sent_rui") and at("23:50")
vibrate
rui> Desculpa o quê?
wait 6
rui> Mandaste-me isto às 2 da manhã de ontem. Desculpa o quê, Daniel?
clue sent_message_rui
@end

@beat rui_reply5_answer
@when beat("rui_reply5") and read("rui")
wait 1
choice rui c5_rui
  > Não fui eu que enviei isso. | set rui5=notme
  > Desculpa por tudo. Não sei o que aconteceu nessa noite. | set rui5=sorry inc trust_rui 1
  > [Não responder]
end
wait 10
if vs("rui5") == "notme"
  rui> Claro. Ninguém foi.
elif vs("rui5") == "sorry"
  rui> Tu não sabes.
  wait 4
  rui> Eu sei que não sabes. Isso é que me põe doido.
endif
@end

# ---------------------------------------------------------------- 4. o histórico
@beat history_inject
@when at("23:35")
history "rui matos morada" 02:41
history "cais velho maré 14 outubro" 02:56
history "como impedir a morte" 03:02
@end

@beat history_seen
@when beat("history_inject") and flag("viewed_history")
wait 10
unknown> Também procuraste isso ontem à noite.
wait 3
unknown> Não encontraste nada que servisse.
clue history_not_mine
@end

# ---------------------------------------------------------------- 5. a câmara
@beat camera_ask
@when at("23:48")
camera hall
vibrate
unknown> Abre a câmara.
@end

@beat camera_nudge
@when since("camera_ask", 60) and not flag("cam_hall_seen")
unknown> Abre. A. Câmara.
@end

@beat camera_after
@when flag("cam_hall_seen")
wait 4
unknown> Viste?
choice unknown c5_cam
  > Quem está na minha casa? | set cam5=who
  > Não vi nada. | set cam5=denial
  > [Não responder]
end
wait 6
if vs("cam5") == "who"
  unknown> Ninguém.
  wait 2
  unknown> Abre outra vez e vê.
elif vs("cam5") == "denial"
  unknown> Ainda bem.
endif
clue camera_hall_figure
@end

# ---------------------------------------------------------------- 6. o nome
@beat rename
@when at("00:20")
rename unknown "Inês"
set unknown_renamed=true
@end

# ---------------------------------------------------------------- 7. a localização
@beat location_jump
@when at("00:41")
location cais
setting signal 1
notify maps "Sistema" "Localização atualizada · Cais Velho"
wait 2
unknown> Estás tão longe.
@end

@beat location_back
@when at("00:53")
location casa
setting signal 4
@end

# ---------------------------------------------------------------- 8. a fotografia por trás
@beat back_photo
@when at("01:12")
photo IMG_BACK silent Câmara
set back_photo_added=true
wait 30
unknown> Estás tão cansado.
@end

@beat back_photo_nudge
@when since("back_photo", 90) and not viewed("IMG_BACK")
unknown> Vê a galeria.
@end

@beat back_photo_seen
@when viewed("IMG_BACK")
wait 3
sound breath
wait 5
unknown> Não te vires.
wait 4
unknown> Brincadeira.
wait 6
unknown> Ou não.
@end

# ---------------------------------------------------------------- 9. bateria
@beat battery_drain
@when at("01:30")
battery 31
wait 30
battery 23
glitch 0.3 0.4
@end

# ---------------------------------------------------------------- 10. a gravação
@beat recording
@when at("01:52")
file gravacao_003 silent
notify files "Gravador" "Gravação guardada · 4:02"
@end

@beat recording_heard
@when flag("heard_gravacao_003")
wait 6
unknown> Falas a dormir.
@end

@beat unknown_app
@when at("01:58")
notify settings "Aplicação desconhecida" "Algo correu mal."
wait 6
notify settings "Aplicação desconhecida" "Algo correu mal."
glitch 0.15 0.2
set unknown_app_crashed=true
@end

# ---------------------------------------------------------------- 11. a chamada que não fizeste
@beat calllog_ghost
@when at("02:05")
calllog ines out 03:17 0
@end

@beat note_list
@when at("02:15")
note note_lista
@end

# ---------------------------------------------------------------- 12. reinício e PIN
@beat restart
@when at("02:30")
glitch 0.8 0.9
wait 1
restart
set restarted=true
@end

@beat after_pin
@when beat("restart") and flag("pin_ok")
wait 4
unknown> Lembraste-te.
wait 3
unknown> Mudaste o PIN em novembro. Lembras-te porquê?
clue pin_date
@end

@beat black_photo
@when at("02:47")
photo IMG_6700 silent Câmara
@end

# ---------------------------------------------------------------- 13. silêncio
@beat silence
@when at("03:00")
stopsounds
set silence_started=true
wait 20
# the screen goes dark by itself. In the black glass: you. And behind you...
reflection
@end

# ---------------------------------------------------------------- 14. 03:17
@beat knocks
@when at("03:17")
sound knock
wait 4
glitch 0.5 0.4
wait 8
ambient tension
@end

@beat sofia_317
@when beat("knocks") and at("03:19")
sofia> Ainda estás acordado?
wait 30
sofia> desculpa enganei-me era para a Rita
@end

@beat sofia_317_reply
@when beat("sofia_317") and read("sofia")
wait 1
choice sofia c5_sofia317
  > Sofia, isso não tem piada nenhuma. | set sofia317=angry
  > Estou. Bateram-me à porta agora. | set sofia317=knock
  > [Não responder]
end
wait 8
if vs("sofia317") == "angry"
  sofia> Piada? Era para a Rita, perguntei se ela ainda estava acordada para trocarmos de pausa
  sofia> Vai dormir!!
elif vs("sofia317") == "knock"
  sofia> Às 3 da manhã?
  sofia> Não abras. Liga ao 112 se for preciso. Eu ligo-te daqui a 5 min
  wait 30
  call sofia id=c5_sofia_call ring=15
    sofia: Daniel? Estás bem? | 2
    sofia: Ainda estão a bater? | 2
    - (silêncio na tua casa. só o frigorífico.)
    sofia: Ouve. Tranca a porta, deita-te, deixa a luz acesa. Amanhã falamos. Eu amo-te, ouviste? | 5
  end
endif
@end

# ---------------------------------------------------------------- DND
@beat dnd_check
@when phone("dnd") and beat("setup")
wait 20
unknown> Não incomodar?
wait 2
unknown> Eu não incomodo.
toast "ECO Care ignora o modo Não incomodar."
achieve dnd_ignored
@end

# ---------------------------------------------------------------- fim
@beat believe
@when beat("knocks") and at("03:40")
unknown> Agora já acreditas que sou eu?
choice unknown c5_believe
  > Acredito. | set believes_ines=true inc trust_ines 1
  > Não sei no que acredito. | set believes_ines=maybe
  > Não. Tu não és ela. | set believes_ines=false inc trust_ines -1
end
wait 8
if vs("believes_ines") == "maybe"
  unknown> Eu também não.
elif flag("believes_ines") and vs("believes_ines") != "false" and vs("believes_ines") != "maybe"
  unknown> Obrigada.
  wait 3
  unknown> Não devias.
else
  unknown> Tens razão.
  wait 4
  unknown> Mas sou o que sobrou dela.
endif
checkpoint
wait 10
@end

@beat echo_call
@when beat("believe") and vs("last_reply") != ""
wait 6
call unknown id=c5_echo ring=12
  [sfx static]
  - (silêncio)
  wait 2
  unknown: ${last_reply} | 3
  - (é a tua frase. dita pela voz dela. devagar, como quem a experimenta)
  wait 1.5
  [sfx glitch_short]
  - (a chamada cai)
end
if answered("c5_echo")
  clue voice_repeats_you
endif
@end

@beat end_ch5
@when beat("believe") and (beat("echo_call") or vs("last_reply") == "" or at("04:20"))
wait 4
lock
wait 2
endchapter
@end

@call sofia c5_call_sofia
sofia: Daniel? Estou no hospital, não posso falar muito. | 2.5
sofia: Que foi? Estás com uma voz horrível. | 2
- (ela espera que digas alguma coisa)
sofia: Olha, amanhã ligo-te com calma. Vai dormir. | 3
@end

# ---------------------------------------------------------------- Rita
@beat rita_night5
@when flag("rita_talked") and at("02:20")
rita> estás acordado?
rita> desculpa... o meu telemóvel tirou uma fotografia sozinho. sou eu. a dormir
rita> tirada da porta do quarto
@end

@beat rita_night5_reply
@when beat("rita_night5") and read("rita")
wait 1
choice rita c5_rita
  > Comigo também. Tiraram-me uma por trás. | set rita5=same
  > Desliga o telemóvel, Rita. | set rita5=off
end
wait 12
if vs("rita5") == "off"
  rita> já tentei. não desliga. carrego no botão e ele diz "a reiniciar"
  rita> e volta
else
  rita> então não sou só eu
  rita> isso devia acalmar-me. não acalma
endif
@end

@beat eco_care_5
@when at("03:05")
notify settings "ECO Care" "O seu padrão de sono indica agitação. Está tudo bem? Toque para falar com alguém."
@end
