# =====================================================================
# SOFIA — CAPÍTULO 13 · ter 13 → qua 14, 23:00 → 02:50 · Santa Maria
# A última noite. O irmão vai a pé para o cais. Ela está no piso 6:
# o elevador abre sozinho com o chão molhado, a 603 tem sal nos lençóis.
# =====================================================================
@chapter ch13
@title O Cais Velho
@start 2026-10-13 23:00

@beat setup
set chapter_n=13
ambient hum
location hospital
battery 52
wait 2
world spawn posto
world lights on
@end

@beat lift
@when at("01:40")
world sound beep 29.0 5.0 -6 1.2
wait 3
world think O elevador chegou ao piso. Ninguém o chamou. As portas abriram e o chão lá dentro está molhado.
world presence near 60
@end

@beat lights_out
@when at("02:20")
world lights off corredor_c
world lights off corredor_b
world presence stalk 60
wait 6
world think O corredor do fundo às escuras. A luz verde da saída. Passos molhados no linóleo, a vir para o posto.
@end
