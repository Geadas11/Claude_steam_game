# =====================================================================
# CAPÍTULO 9 — A VERDADE
# segunda 12 → terça 13 de outubro, 22:00 → 03:30
# A cópia do telemóvel antigo (PIN da Sofia). A gravação da Inês,
# sincronizada pela conta dela. As imagens das bombas. A reconstrução.
# Nada é explicado: o jogador monta a noite com o que encontrou.
# =====================================================================
@chapter ch09
@title A Verdade
@start 2026-10-12 22:00

@beat setup
set chapter_n=9
rate 1
ambient night
location casa
battery 61
@end

# ---------------------------------------------------------------- a cópia
@beat backup_arrives
@when at("22:12")
email sofia_backup
wait 10
sofia> Mandei-te por email! O João explicou-me tudo ao telefone, demorou 40 minutos e chamou-me "tia" duas vezes
sofia> A palavra-passe é o PIN do teu telemóvel antigo. Se não te lembras, és pior irmão do que eu pensava
set backup_sent=true
@end

@beat backup_hint
@when since("backup_arrives", 150) and not flag("extracted_backup_pixel7")
sofia> Já conseguiste abrir? Dica: o dia mais importante do ano. Para mim, claro
@end

@beat backup_opened
@when flag("extracted_backup_pixel7")
wait 6
unknown> Lá não mando eu.
wait 3
unknown> O que vires aí, é teu.
@end

@beat backup_messages_read
@when file_open("pixel7_mensagens")
wait 8
unknown> "Não lhe digas que fui eu."
wait 5
unknown> Ele disse-me. Às 03:09. Foi a primeira coisa que me disse.
set confirmed_told=true
@end

# ---------------------------------------------------------------- a gravação
@beat ines_sync
@when at("22:50") or flag("old_backup")
wait 20
file ines_cais_rec silent
file ines_notas silent
notify files "Sincronização" "ines.matos@lumen.pt · 2 ficheiros sincronizados"
set ines_files_synced=true
@end

@beat sync_hint
@when beat("ines_sync") and since("ines_sync", 120) and not file_open("ines_cais_rec")
unknown> Há uma pasta com o meu nome nos teus ficheiros.
unknown> Ouve-a. Eu não consigo.
@end

@beat recording_heard
@when flag("heard_ines_cais_rec")
stopsounds
wait 12
unknown> Agora sabes.
wait 6
unknown> Eu não sabia que tinha gravado até ao fim.
wait 4
ambient night
set heard_recording=true
wait 25
camera behind
unknown> Daniel.
unknown> Abre a câmara da frente. Quero ver-te a cara.
@end

@beat behind_seen
@when flag("cam_behind_seen")
wait 4
unknown> Desculpa.
wait 3
unknown> Às vezes não consigo controlar onde apareço.
clue front_camera_figure
@end

# ---------------------------------------------------------------- câmara das bombas
@beat cctv
@when at("23:30")
if flag("clara_ally") or v("trust_clara") >= 2
  email clara_cctv
  set cctv_from=clara
elif flag("rui_ally") or v("trust_rui") >= 2
  email rui_cctv
  set cctv_from=rui
else
  unknown> [photo:IMG_5530] O Armando não foi o único a ver.
  clue gas_station_camera
  set cctv_from=voice
endif
@end

@beat cctv_seen
@when viewed("IMG_5530")
wait 10
if clue("vasco_audi")
  unknown> Um Audi cinzento que ocupa sempre dois lugares.
else
  unknown> AX-31-PL. Procura quem conduz um carro assim.
endif
@end

# ---------------------------------------------------------------- reconstrução
@beat deduction_open
@when (flag("old_backup") and flag("heard_recording")) or at("01:40")
wait 6
set deduction_unlocked=true
unknown> Monta a noite. Peça a peça.
unknown> Não te vou dizer se acertas.
wait 4
deduction
@end

@beat deduction_reaction
@when flag("deduction_done")
wait 6
if v("deduction_score") >= 5
  unknown> ...
  wait 4
  unknown> Sim.
  wait 3
  unknown> Foi assim.
  set truth_known=true
elif v("deduction_score") >= 3
  unknown> Quase.
  wait 3
  unknown> Há uma peça que ainda não queres pôr no sítio.
else
  unknown> Não.
  wait 3
  unknown> Ainda não.
endif
checkpoint
@end

# ---------------------------------------------------------------- o Vasco sabe
@beat vasco_threat
@when at("02:40")
vasco> Daniel. Sei que esteve a ouvir coisas que não devia.
wait 5
vasco> Não sei o que pensa que ouviu. Mas sei que não está bem. A Dra. Helena tem uma cama para si amanhã às 14h. Seria melhor para todos que aceitasse.
clue vasco_knows_recording
@end

@beat vasco_threat_reply
@when beat("vasco_threat") and read("vasco")
wait 1
choice vasco c9_vasco
  > Porque é que levou o telemóvel dela, Vasco? | set confronted_vasco=true inc trust_vasco -2
  > Talvez tenha razão. Talvez eu precise de descansar. | set yielded_vasco=true inc trust_vasco 1
  > [Não responder] | set ignored_vasco=true
end
wait 15
if flag("confronted_vasco")
  typing vasco vasco 12
  wait 6
  vasco> Cuidado com o que diz por escrito, Daniel.
  wait 3
  vasco> Este telemóvel é da empresa.
  set vasco_mask_off=true
elif flag("yielded_vasco")
  vasco> É o mais sensato. Traga o telemóvel. E, se a Inês lhe deu alguma coisa — qualquer coisa — traga também. Vamos resolver isto juntos.
  set vasco_wants_card=true
endif
@end

# ---------------------------------------------------------------- 03:17
@beat photo_two
@when at("03:17")
variant IMG_0317 two
note note_eco_1
sound knock_one
wait 6
unknown> Amanhã à noite.
wait 2
unknown> Último dia.
@end

@beat end_ch9
@when beat("photo_two") and (flag("deduction_done") or at("03:28"))
wait 6
lock
wait 2
endchapter
@end

@call sofia c9_call_sofia
sofia: Daniel? Conseguiste abrir? | 2
sofia: O PIN. Era o meu aniversário, tonto. Dois do dois. | 3
@end

@call rui c9_call_rui
@when flag("rui_ally")
rui: Diz. | 1
rui: Se tens alguma coisa, eu também tenho. Desde o ano passado. Vê o teu email. | 4
@end

# ---------------------------------------------------------------- Sofia
@beat sofia_after_backup
@when flag("extracted_backup_pixel7") and since("backup_opened", 60)
sofia> Abriste?
sofia> Não te vou perguntar o que lá está. Só uma coisa
sofia> O que quer que encontres, tu és meu irmão. Isso não muda. Ok?
@end

@beat sofia_after_backup_reply
@when beat("sofia_after_backup") and read("sofia")
wait 1
choice sofia c9_sofia
  > Fiz uma coisa horrível, Sofia. Disse a alguém onde ela estava. | set confessed_sofia=true
  > Ok. Obrigado. | set confessed_sofia=false
end
wait 8
if flag("confessed_sofia")
  sofia> ...
  wait 5
  sofia> Tu disseste a alguém onde ela estava. Não a empurraste. Não a deixaste cair
  sofia> Isso é uma coisa horrível que tens de carregar. Não é a coisa que tu achas que fizeste
  wait 3
  sofia> E agora vais fazer o quê com isso?
  set sofia_knows_told=true
else
  sofia> Ok. Estou aqui
endif
@end

# ---------------------------------------------------------------- Rita
@beat rita_proof
@when flag("rita_talked") and at("00:30")
if flag("rita_keep")
  rita> fiz o que disseste. pus "mostrar ficheiros ocultos"
  rita> olha isto
  rita> [photo:IMG_RITA]
  wait 5
  rita> sim 112. sujeita r.santos. espelho: "pai"
  rita> daniel quantas pessoas há nesta lista
  clue other_simulations
else
  rita> {typing=6} A Rita está bem. Obrigado pela preocupação.
  wait 8
  rita> {instant} Este número será desativado.
  clue rita_silenced
endif
@end

# ---------------------------------------------------------------- Rui não dorme nesta semana
@beat rui_night9
@when at("01:55") and phone("rui_known")
rui> Não consigo dormir. Nesta semana nunca consigo.
rui> Sabes uma coisa que ninguém sabe? Ela tinha medo do mar. Desde miúda. Nunca ia ao fim do cais sozinha. Nunca.
rui> Disseram que se atirou. A minha irmã não chegava ao fim do cais sem me dar a mão.
clue ines_feared_sea
@end

@beat rui_night9_reply
@when beat("rui_night9") and read("rui")
wait 1
choice rui c9_rui
  > Ela não se atirou, Rui. Eu tenho uma gravação. | set told_rui_recording=true inc trust_rui 1
  > Lamento muito. | set told_rui_recording=false
end
wait 20
if flag("told_rui_recording")
  rui> O quê?
  rui> Que gravação
  wait 10
  rui> Não me mandes por aqui. Amanhã. Em pessoa. Ou por quem tu confiares
  rui> Daniel... obrigado
  set rui_ally=true
else
  rui> Eu também.
endif
@end

@beat eco_care_9
@when flag("heard_recording") and since("recording_heard", 60)
notify settings "ECO Care" "Detetámos sinais de risco elevado. Para sua segurança, a sua médica foi notificada."
clue eco_care_reported
@end
