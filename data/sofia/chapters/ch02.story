# =====================================================================
# SOFIA — CAPÍTULO 2 · sexta 9 out, 08:05 → 23:30 · Lisboa
# Sai do turno, dorme mal. O irmão fala de um número que sabe coisas.
# A última vez que o grupo dele se ri todo junto; a mãe aflita.
# =====================================================================
@chapter ch02
@title O Contacto
@start 2026-10-09 08:05

@beat setup
set chapter_n=2
ambient room
location sofia_casa
battery 23
wait 2
world spawn entrada
world think Doze horas de turno. A escada do prédio tem noventa e dois degraus. Contei-os outra vez.
@end

@beat mae2
@when at("12:30")
mae> sofia o teu irmao respondeu-te
mae> a mim diz sempre "estou bem mãe"
@end

@beat mae2_reply
@when beat("mae2") and read("mae")
wait 1
choice mae c2s_mae
  > Respondeu. Anda com uma mensagem estranha de um número desconhecido. | set s2_told_mae=number
  > Respondeu. Está igual. | set s2_told_mae=same
end
wait 20
if vs("s2_told_mae") == "number"
  mae> número desconhecido??
  mae> diz-lhe para não responder. o primo Zé respondeu a um desses e ficou sem 300 euros
else
  mae> igual é bom. igual não é pior
endif
@end

@beat patricia2
@when at("19:40")
patricia> Hoje folgas e eu estou sozinha com o Sr. Joaquim a cantar fado às três da manhã
patricia> Vai dormir. Tens cara de quem não dorme desde o ano passado
@end

@beat drawer_glance
@when at("22:30")
world think A gaveta da mesa de cabeceira. Não a abro há um ano. Hoje passei três vezes à frente dela.
@end
