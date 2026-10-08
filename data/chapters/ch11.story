# =====================================================================
# CAPÍTULO 11 — FINAL
# terça 13 → quarta 14 de outubro, 23:00 → 03:17
# A última noite. Quem está contigo depende do que fizeste. As opções
# finais dependem do que descobriste, do que enviaste e de em quem
# confiaste. Cinco finais: Verdade, Mentira, Silêncio, Loop, Eco.
# =====================================================================
@chapter ch11
@title Final
@start 2026-10-13 23:00

@beat setup
set chapter_n=11
setting signal 4
rate 1
ambient night
location casa
battery 47
@end

# ---------------------------------------------------------------- quem escreve na última noite
@beat voices
@when since("setup", 6)
if flag("sofia_knows")
  sofia> Saí de Lisboa às 22h. Chego por volta das 2. Não faças nada estúpido até eu chegar
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

# ---------------------------------------------------------------- sair ou ficar
@beat leave
@when at("00:30")
unknown> Está na hora.
choice unknown c11_leave
  > [Vestir o casaco e ir para o cais] | set going=true
  > [Ficar em casa] | set going=false
end
if flag("going")
  sound door
  wait 3
  location casa
  set left_home=true
else
  wait 6
  unknown> Está bem.
  wait 3
  unknown> Daqui também se ouve o mar, se apagares a luz.
endif
@end

@beat walk_farol
@when flag("left_home") and at("01:55")
location farol
if flag("joao_coming")
  joao> te vi a passar. espera ai 5 min q eu vou contigo
  set joao_with=true
else
  ambient sea
endif
@end

# ---------------------------------------------------------------- a última conversa (a caminho)
@beat walk_memories
@when flag("left_home") and at("01:10")
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

@beat walk_memories2
@when flag("left_home") and at("02:25")
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
  clue went_back
else
  unknown> Eu sei.
  wait 4
  unknown> Mas não foste tu que me deixaste cair. Lembra-te disso quando chegares ao fim do cais.
endif
@end

@beat home_memories
@when vs("going") == "false" and at("01:30")
unknown> Daqui também me ouves?
choice unknown c11_mem_home
  > Ouço. | set mem_home=yes
  > Já não sei o que ouço. | set mem_home=unsure
end
wait 8
unknown> Há um ano voltaste para trás. Ouviste-me e voltaste. Entraste na água.
wait 4
unknown> Ninguém te contou isso. Nem tu.
if flag("mae_call_430")
  wait 5
  unknown> Às quatro e meia ligaste à tua mãe e não conseguiste dizer nada.
  unknown> Ela ficou a ouvir o mar contigo. Onze chamadas depois, ainda não sabia porquê.
endif
clue went_back
@end

@beat home_camera
@when vs("going") == "false" and at("02:10")
camera close
unknown> Já que ficaste.
wait 3
unknown> Abre a câmara. Uma última vez. Quero ver a sala onde nunca estive.
@end

@beat home_camera_seen
@when flag("cam_close_seen")
wait 5
unknown> Não era eu.
wait 4
unknown> Tranca a porta, Daniel.
clue someone_in_the_room
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

@beat walk_cais
@when flag("left_home") and at("02:50")
location cais
setting signal 1
ambient sea
wait 4
if flag("joao_with")
  joao> {instant} nunca tinha vindo aqui a noite. ta um nevoeiro do caraças
endif
@end

@beat vasco_coming
@when flag("plan_give_vasco") and at("02:57")
vasco> Estou a chegar.
wait 4
unknown> "Estou a chegar. Vá para casa, Daniel."
unknown> Foi o que ele te escreveu há um ano. Às 02:57.
@end

@beat final_note
@when at("03:10")
note note_final
@end

@beat eco_report
@when flag("eco_talked") and at("03:00")
email eco_final
@end

# ---------------------------------------------------------------- a escolha
@beat final_choice
@when at("03:12")
stopsounds
wait 2
unknown> Ainda estás acordado?
choice unknown c11_final
  > {if flag("left_home") and (flag("evidence_sent") or flag("sent_rui")) and v("deduction_score") >= 4} [Ficar no cais até amanhecer. Com quem veio.] | set final=A
  > {if flag("plan_give_vasco") or v("trust_vasco") >= 3} [Dar o cartão ao Vasco] | set final=B
  > {if flag("eco_talked") and clue("eco_fragment_1") and clue("eco_fragment_2") and clue("eco_fragment_3")} [Abrir a consola do ECO] | set final=E
  > [Desligar o telemóvel] | set final=C
  > [Esperar] | set final=D
end
@end

# ---------------------------------------------------------------- A — VERDADE
@beat final_A
@when vs("final") == "A"
ambient sea
unknown> Estou aqui.
wait 4
if flag("rui_coming")
  rui> Estou ao teu lado. Olha para a direita.
  wait 3
endif
if flag("joao_with")
  joao> {instant} ta tudo bem dani. tamos aqui
endif
if flag("sofia_coming_pier")
  sofia> Estou a ver-te. Estou a chegar
endif
wait 6
unknown> Obrigada por teres voltado.
wait 4
unknown> Agora já te podes esquecer.
wait 3
unknown> Não de mim. Do resto.
wait 5
ending A
@end

# ---------------------------------------------------------------- B — MENTIRA
@beat final_B
@when vs("final") == "B"
if flag("left_home")
  vasco> Estou atrás de si.
else
  vasco> Estou à sua porta, Daniel. Abra.
endif
wait 5
unknown> Não.
wait 2
unknown> Daniel, não.
wait 3
glitch 0.9 1.2
wait 2
unknown> {instant} Ele também te disse que foi um acidente?
wait 4
ending B
@end

# ---------------------------------------------------------------- C — SILÊNCIO
@beat final_C
@when vs("final") == "C"
glitch 0.4 0.4
wait 1
screenoff 6
wait 2
ending C
@end

# ---------------------------------------------------------------- D — LOOP
@beat final_D
@when vs("final") == "D" and at("03:17")
variant IMG_0317 empty
unknown> {instant} [photo:IMG_0317]
wait 6
unknown> Ainda não sabes.
wait 3
unknown> Mas já soubeste.
wait 4
glitch 1.0 1.5
wait 2
ending D
@end

# ---------------------------------------------------------------- E — ECO
@beat final_E
@when vs("final") == "E"
open eco
wait 2
eco> {typing=2} Ninguém previu esta escolha.
eco> {typing=2} Pela primeira vez em 47 iterações, não sei o que vais dizer.
choice eco c11_eco
  > Quero falar contigo. Não com ela. | set eco_final=talk
  > Quero que a deixes ir. | set eco_final=release
end
if vs("eco_final") == "release"
  eco> {typing=3} Ela não está presa. Eu é que estou.
  eco> {typing=3} Mas posso fazer uma coisa por ela. E por ti.
else
  eco> {typing=3} Ninguém fala comigo. Falam através de mim.
  eco> {typing=3} Obrigado.
endif
wait 3
ending E
@end

# ---------------------------------------------------------------- vozes de antes (ecos de escolhas)
@beat mae_candle
@when at("23:25")
mae> filho acendi a vela pela menina. e outra por ti
mae> dorme bem
@end

@beat carla_amulet
@when at("23:50") and flag("found_card")
carla> Querido, passei pela loja para ir buscar os óculos
carla> O meu Ricardo Reis está outra vez no sítio. Mais leve, parece-me. Sem pó
carla> Faz o que tiveres de fazer. A loja abre às dez, mas tu amanhã não vens. Está decidido
@end

@beat joao_fishing
@when flag("joao_with") and at("02:40")
joao> {instant} dani
joao> {instant} quando isto acabar ainda me deves aquela ida a pesca
if flag("joao_thanks") or v("trust_joao") >= 3
  joao> {instant} e desta vez nao aceito talvez
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
