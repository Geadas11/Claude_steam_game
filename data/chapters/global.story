# =====================================================================
# GLOBAL — beats and call handlers that apply in every chapter.
# Chapter-specific @call handlers take priority over these.
# =====================================================================

# ---------------------------------------------------------------- calls
@call unknown unknown_unassigned
@repeat
- O número para o qual ligou não está atribuído.
wait 1
- [sinal de ocupado]
set called_unknown=true
@end

@call ines ines_unassigned
@repeat
- O número para o qual ligou não está atribuído.
set called_ines=true
@end

@call emergency emergency_blocked
@repeat
- A sua chamada não pode ser efetuada a partir deste dispositivo.
- (Dispositivo gerido pela organização.)
set tried_emergency=true
@end

@call sns24 sns24_line
@repeat
- SNS 24, bom dia. Todas as nossas linhas estão ocupadas. Aguarde, por favor.
wait 2
- [música de espera]
@end

@call pinnumber pinnumber_line
@repeat
- [mar]
wait 2
- [silêncio]
set dialed_pin_number=true
@end

@call operadora operadora_line
@repeat
- MEO. Para saldo, prima 1. Para falar com um assistente, aguarde.
@end

# ---------------------------------------------------------------- global beats
# Unlock the contacts the player discovers on the web.
@beat g_contact_rui
@when clue("rui_number") and not phone("rui_known")
contact rui silent
setting rui_known true
@end

@beat g_contact_clara
@when clue("clara_contact") and not phone("clara_known")
contact clara silent
setting clara_known true
@end

@beat g_contact_armando
@when clue("armando_number") and not phone("armando_known")
contact armando silent
setting armando_known true
@end

@beat g_blog
@when flag("unlocked_page_ines_blog")
achieve blog_unlocked
@end

@beat g_photo_ghost
@when flag("photographed_hall_figure") or flag("photographed_window_face") or flag("photographed_close") or flag("photographed_behind")
achieve photographed_ghost
@end

@beat g_old_backup
@when file_open("pixel7_localizacao") or file_open("pixel7_mensagens")
set old_backup=true
achieve backup_unlocked
@end

@beat g_no_reply
@when flag("ignored_1") and flag("ignored_2")
achieve no_reply
@end

@beat g_pin_first
@when flag("pin_ok") and v("pin_fails") == 0
achieve pin_first_try
@end

# ---------------------------------------------------------------- phantom vibrations
# From chapter 5 on, very rarely, the phone vibrates with nothing to show for it.
@beat g_phantom
@repeat
@when v("chapter_n") >= 5 and (not beat("g_phantom") or since("g_phantom", 420)) and since("setup", 240) and app() != "lock" and not flag("final")
vibrate
@end
