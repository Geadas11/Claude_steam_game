# =====================================================================
# SOFIA — CAPÍTULO 9 · seg 12 out, 09:30 → 21:00 · Lisboa
# Dia. O João explica-lhe ao telefone como tirar a cópia do telemóvel
# antigo. A palavra-passe é o aniversário dela (0202).
# =====================================================================
@chapter ch09
@title O Sistema
@start 2026-10-12 09:30

@beat setup
set chapter_n=9
rate 2
ambient room
location sofia_casa
battery 90
wait 2
world spawn sofa
@end

@beat joao_help
@when at("13:00")
joao> sofia? é o joão. o daniel deu-me o teu numero
joao> se quiseres tirar a copia do telemovel velho eu explico. demora 40 min e precisas de paciencia
@end

@beat joao_help_reply
@when beat("joao_help") and read("joao")
wait 1
choice joao c9s_joao
  > Explica. Tenho a tarde toda. | set s9_backup=true
  > Ainda não consigo, João. | set s9_backup=false
end
wait 10
if flag("s9_backup")
  joao> ok. primeiro: NAO o ligues à rede. so ao computador
  joao> e a palavra passe da copia mete o teu aniversario. ele nao se vai esquecer disso
  coopset co_sofia_backup true
else
  joao> ok. quando conseguires
endif
@end
