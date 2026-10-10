# =====================================================================
# SOFIA — PRÓLOGO (modo cooperativo)
# 14 de outubro de 2025, 02:30 → 03:17 · Lisboa, Santa Maria, piso 6
# Há um ano. Turno da noite. Enquanto o Daniel está no cais, a Sofia
# está no posto de enfermagem. Às 03:17 o telefone do serviço toca: mar.
# =====================================================================
@chapter ch00
@title A Noite
@start 2025-10-14 02:30

@beat setup
set chapter_n=0
ambient hum
location hospital
battery 44
wait 2
world spawn posto
world lights on
world presence off
wait 3
world think Há um ano. Eu estava aqui. A chefe dormia na sala de pausa e eu tinha seis doentes e um bolo de laranja.
@end

@beat patricia_now
@when at("02:45")
patricia> {time=02:45} Vou ao 603 ver a D. Lurdes. Se tocar o telefone atende tu
@end

@beat bed_round
@when since("setup", 60) and not flag("w_cama_603")
world think A cama 3 da 603 está vazia. Devia ir fazer a ronda.
@end

@beat ward_phone
@when at("03:17")
set s_ward_phone=true
world change telefone
wait 4
world think O telefone do serviço. Às três e dezassete. A urgência nunca liga a esta hora.
wait 8
world think Atendi. Vento. E o mar. No sexto piso de Santa Maria não se ouve o mar.
@end
