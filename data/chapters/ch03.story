# =====================================================================
# CAPÍTULO 3 — A PESSOA QUE MORREU
# sexta 9 → sábado 10 de outubro, 23:40 → 03:40
# O número pertence a Inês Matos, que morreu há quase um ano no Cais Velho.
# O jogador descobre-o sozinho (pesquisa), com empurrões se precisar.
# Termina com a chamada das 03:17.
# =====================================================================
@chapter ch03
@title A Pessoa Que Morreu
@start 2026-10-09 23:40

@beat setup
set chapter_n=3
rate 1
ambient night
location casa
battery 58
if flag("joao_slept_over")
  joao> {instant} vou dormir no sofa. se precisares grita
  joao> {instant} ou manda mensagem q é mais civilizado
endif
@end

# ---------------------------------------------------------------- empurrões
@beat nudge_1
@when at("00:05") and not clue("ines_number")
vibrate
unknown> Procura-me.
@end

@beat nudge_2
@when at("00:40") and not clue("ines_number")
unknown> 912 403 317.
unknown> Escreve-o. Ou tens medo do que vais encontrar?
@end

@beat nudge_3
@when at("01:30") and not clue("ines_number")
unknown> [link:vendeja_bike] Lembras-te disto? Querias comprá-la para ires para o trabalho de bicicleta. Nunca foste.
@end

# ---------------------------------------------------------------- descoberta
@beat found_number
@when clue("ines_number")
wait 2
set knows_ines_number=true
wait 20
notify contacts "Contactos" "1 contacto restaurado a partir da nuvem: Inês Matos"
contact ines
clue contact_restored
@end

@beat found_death
@when clue("news_death") or visited("memorial") or visited("jornal_morte")
set knows_ines_dead=true
@end

@beat confront_dead
@when flag("knows_ines_dead") and flag("knows_ines_number") and read("unknown")
wait 2
choice unknown c3_dead
  > A Inês Matos morreu há um ano. | set c3_said=dead
  > És a Inês? | set c3_said=ines
  > Quem quer que sejas, isto é doentio. | set c3_said=sick
end
wait 5
if vs("c3_said") == "ines"
  typing unknown unknown 6
  wait 2
  unknown> Faz quatro dias que me perguntas isso.
  set loop_hint_1=true
  clue loop_hint_days
elif vs("c3_said") == "dead"
  unknown> Eu sei.
else
  unknown> Doentio é não te lembrares.
endif
wait 6
unknown> Tu estavas lá.
set unknown_said_there=true
choice unknown c3_there
  > Eu estava em casa. A dormir. | set c3_there=denial
  > Não me lembro dessa noite. | set c3_there=honest
  > [Não responder]
end
wait 6
if vs("c3_there") == "denial"
  unknown> Foi isso que te disseram.
elif vs("c3_there") == "honest"
  unknown> Eu sei. Eu também não me lembro de tudo.
  wait 3
  unknown> Lembro-me do frio.
endif
clue unknown_says_there
@end

# ---------------------------------------------------------------- Rui
@beat rui_open
@when phone("rui_known") and app() == "messages:rui"
choice rui c3_rui
  > Olá Rui. Sou o Daniel Reis. Trabalhava com a tua irmã. | set rui_intro=work
  > Rui, estou a receber mensagens do número da Inês. | set rui_intro=messages
  > [Fechar a conversa] | set rui_intro=none
end
if vs("rui_intro") != "none"
  wait 25
  rui> Como é que tens o meu número
  wait 4
  rui> Daniel Reis.
  rui> Eu sei quem tu és. Eras o rapaz dela.
  wait 3
  if vs("rui_intro") == "messages"
    rui> O telemóvel dela nunca apareceu. A polícia disse que caiu ao mar com ela.
    clue phone_missing
    wait 3
    rui> Se isto é alguma brincadeira eu parto-te a cara. Ouviste?
  else
    rui> Não me escrevas.
  endif
  choice rui c3_rui2
    > Não é brincadeira. Também quero saber o que aconteceu. | set rui_c3=sincere inc trust_rui 1
    > Desculpa. Não volto a incomodar. | set rui_c3=retreat
  end
  wait 12
  if vs("rui_c3") == "sincere"
    rui> Tu sabes o que aconteceu. Tu estavas com ela nessa noite.
    rui> Toda a gente sabe.
    clue rui_accuses
    wait 4
    rui> Não me escrevas mais.
  endif
  set talked_rui3=true
endif
@end

@beat rui_voicemail
@when beat("rui_open") and flag("talked_rui3") and at("02:40")
calllog rui missed 02:39
voicemail vm_rui_angry
@end

# ---------------------------------------------------------------- João no sofá
@beat joao_sofa
@when flag("joao_slept_over") and at("01:30")
joao> tas acordado? ouvi o teu telemovel a vibrar
@end

@beat joao_sofa_talk
@when beat("joao_sofa") and read("joao")
wait 1
choice joao c3_joao
  > Conheceste uma rapariga chamada Inês Matos? | set asked_joao_ines=true
  > Não consigo dormir | set asked_joao_ines=false
end
wait 4
if flag("asked_joao_ines")
  joao> a rapariga do cais?
  wait 5
  joao> de vista. ia ao bar as vezes
  joao> porque
  set joao_lied_ines=true
  choice joao c3_joao2
    > O número que me manda mensagens era dela | set told_joao_number=true
    > Por nada | set told_joao_number=false
  end
  wait 5
  if flag("told_joao_number")
    joao> dani
    joao> isso nao pode ser
    joao> vou ai ao quarto
    wait 6
    joao> {instant} esquece. ouvi-te a ressonar. tas a dormir. entao quem é que ta a escrever do teu telemovel
    set joao_heard_snoring=true
    clue joao_heard_snoring
  endif
else
  joao> eu tb nao. o teu sofa tem uma mola assassina
endif
@end

# ---------------------------------------------------------------- silêncio
@beat silence
@when at("02:58")
ambient off
wait 1
ambient hum
@end

@beat dread
@when at("03:10")
ambient dread
@end

# ---------------------------------------------------------------- 03:17
@beat the_call
@when at("03:17")
if phone("ines_contact") or clue("contact_restored")
  call ines id=c3_ines ring=22
    [sfx sea]
    - (o mar)
    wait 2.5
    ines: Daniel? | 1.8
    wait 2
    ines: ...Daniel, estás aí? | 2.2
    [sfx breath]
    wait 2
    ines: Eu não consigo ver nada. | 2.4
    wait 1.5
    ines: Está tão frio. | 2.5
    [sfx glitch]
    - (a chamada cai)
  end
else
  call unknown id=c3_ines ring=22
    [sfx sea]
    - (o mar)
    wait 2.5
    unknown: Daniel? | 1.8
    wait 2
    unknown: ...Daniel, estás aí? | 2.2
    [sfx breath]
    wait 2
    unknown: Eu não consigo ver nada. | 2.4
    wait 1.5
    unknown: Está tão frio. | 2.5
    [sfx glitch]
    - (a chamada cai)
  end
endif
if answered("c3_ines")
  achieve answered_dead
  clue call_from_dead
else
  wait 4
  voicemail vm_ines_317
endif
ambient night
@end

@beat after_call
@when beat("the_call")
wait 12
unknown> Desculpa.
wait 3
unknown> Não era para ser assim.
wait 8
unknown> Dorme. Amanhã procuras melhor.
checkpoint
wait 10
@end

@beat end_ch3
@when beat("after_call") and (beat("confront_dead") or at("03:35"))
wait 4
lock
wait 2
endchapter
@end

@call joao c3_call_joao
@when flag("joao_slept_over")
- (ouves o telemóvel dele tocar na sala. Ele atende a bocejar.)
joao: tas a ligar-me de dentro de casa? | 2
joao: vou ai. | 1.5
@end
