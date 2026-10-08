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
