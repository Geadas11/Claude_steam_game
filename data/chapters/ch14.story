# =====================================================================
# CAPÍTULO 14 — FINAL
# quarta-feira, 14 de outubro de 2026, 02:50 → 03:17
# O Cais Velho, um ano depois. Quem está com ele depende do que fez.
# Às 03:17, a decisão: enviar tudo, entregar ao Vasco, desligar,
# esperar, ou falar com o ECO. Cinco finais (A–E).
# =====================================================================
@chapter ch14
@title Final
@start 2026-10-14 02:50

@beat setup
set chapter_n=14
setting signal 1
rate 1
ambient sea
location cais
battery 9
wait 2
world spawn fim
world rain on
world presence off
wait 3
world think O fim do cais. As tábuas estão molhadas e cedem um bocadinho. O corrimão partido, as flores secas no poste. Daqui não se vê a vila.
if flag("joao_with")
  wait 4
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

@beat eco_report
@when flag("eco_talked") and at("03:00")
email eco_final
@end

@beat final_note
@when at("03:10")
note note_final
@end

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

@beat final_C
@when vs("final") == "C"
glitch 0.4 0.4
wait 1
screenoff 6
wait 2
ending C
@end

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

