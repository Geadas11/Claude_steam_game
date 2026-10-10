# =====================================================================
# SOFIA — CAPÍTULO 3 · sex 9 → sáb 10, 23:40 → 03:40 · Lisboa, em casa
# Folga. Não consegue dormir. O irmão descobre de quem era o número.
# Às 03:17, em casa, um clique na gaveta.
# =====================================================================
@chapter ch03
@title A Pessoa Que Morreu
@start 2026-10-09 23:40

@beat setup
set chapter_n=3
ambient night
location sofia_casa
battery 57
wait 2
world spawn sofa
@end

@beat news
@when at("00:40")
world think Pesquisei o nome. Inês Matos. A fotografia do jornal tem um casaco vermelho. Eu conheço esse casaco. Não sei de onde.
@end

@beat drawer_click
@when at("03:17")
world change gaveta
wait 6
world think Um clique no quarto. Seco. Como uma gaveta mal fechada.
@end
