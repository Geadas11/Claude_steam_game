# =====================================================================
# SOFIA — CAPÍTULO 8 · seg 12 out, 03:00 → 05:00 · Lisboa, em casa
# Enquanto o irmão está na livraria, a Sofia encontra a gaveta aberta e
# o telemóvel antigo virado ao contrário. Decide mandá-lo ao irmão.
# =====================================================================
@chapter ch08
@title A Livraria
@start 2026-10-12 03:00

@beat setup
set chapter_n=8
ambient night
location sofia_casa
battery 48
wait 2
world spawn cama
world change gaveta
wait 4
world think Acordei com o clique. A gaveta outra vez.
@end

@beat drawer_seen
@when flag("w_gaveta")
wait 3
choice aqui c8s_phone
  > [Guardar outra vez a gaveta e não pensar nisso] | set s8_closed=true
  > [Tirar o telemóvel do saco para o mandar ao Daniel] | set sofia_has_old_phone=true
end
if flag("sofia_has_old_phone")
  world think Ainda tem areia nos cantos. Está pesado como se ainda tivesse água lá dentro. Amanhã mando-o. Ou a cópia. O João sabe como.
  coopset sofia_has_old_phone true
endif
@end

@beat drawer_nudge
@when at("03:40") and not flag("w_gaveta")
world think A gaveta continua aberta. Daqui vejo o saco.
@end
