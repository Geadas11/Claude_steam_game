# =====================================================================
# CAPÍTULO 8 — A LIVRARIA
# segunda-feira, 12 de outubro de 2026, 03:00 → 05:00
# A chave com a fita vermelha abre a Livraria Maré às escuras. Na estante
# de cima, dentro da capa de "O Ano da Morte de Ricardo Reis", o cartão —
# e um papel com a letra dele: "Não confies em ti."
# A coisa: ouvir-se a si próprio (passos iguais aos dele quando pára).
# Luz: afasta a coisa, mas da rua vê-se tudo (alguém vai saber).
# =====================================================================
@chapter ch08
@title A Livraria
@start 2026-10-12 03:00

@beat setup
set chapter_n=8
rate 1
ambient night
location livraria
battery 41
wait 2
world spawn noite
world lights off
world presence calm
wait 2
world think Duas chaves iguais no porta-chaves. A minha, e uma com uma fita vermelha. Experimentei a da fita. Rodou à primeira.
wait 8
unknown> Não acendas as luzes.
wait 2
unknown> Da rua vê-se tudo.
if v("deaths_ch08") >= 1
  wait 6
  world think Um livro no chão, aberto na página 317. Não fui eu que o deixei aí.
endif
@end

# ---------------------------------------------------------------- onde
@beat where_1
@when since("setup", 50) and not flag("w_ricardo_reis") and not flag("w_saramago")
unknown> Lá em cima.
wait 3
if clue("postit_p317")
  unknown> D. — p. 317. A de cima.
else
  unknown> A de cima.
endif
@end

@beat saramago_seen
@when flag("w_saramago") and not flag("w_ricardo_reis")
wait 4
unknown> Esses são os da Carla.
wait 2
unknown> O teu está mais acima.
@end

@beat steps_echo
@when at("03:14") and not flag("found_card")
world presence near 30
wait 6
unknown> Ouviste?
wait 3
unknown> Também anda à procura do livro.
@end

@beat where_2
@when at("03:35") and not flag("w_ricardo_reis")
unknown> Galeria. Estante do fundo. Prateleira de cima.
wait 4
unknown> Sobe devagar. A madeira das escadas fala.
@end

@beat book_falls
@when at("04:05") and not flag("w_ricardo_reis")
sound drop
wait 2
world think Caiu um livro lá em cima. Ninguém lhe tocou.
@end

# ---------------------------------------------------------------- o livro
@beat found_book
@when flag("w_ricardo_reis") and not flag("found_card")
wait 1
sound click_far
world think A capa de trás está descolada por dentro. Preso com fita-cola, um cartão de memória. E um papel dobrado em quatro.
wait 3
toast "Dentro da capa: um cartão microSD e um papel dobrado."
file mare_leiame silent
file mare_contrato silent
file mare_emails silent
file mare_utentes silent
notify files "Cartão SD" "MARÉ (cartão) · 4 ficheiros"
set found_card=true card_night=true
achieve found_card
clue card_found
wait 6
unknown> Estava onde a maré não chega.
wait 4
choice unknown c8l_note
  > [Desdobrar o papel] | set read_note=true
  > [Guardar o papel sem o ler] | set read_note=false
end
wait 2
if flag("read_note")
  world think A minha letra. Inclinada para a esquerda, como quando escrevo depressa. «Não confies em ti.»
  clue note_dont_trust
  wait 6
  unknown> Escreveste isso às 04:12.
  wait 3
  unknown> Já não estavas molhado.
else
  wait 4
  unknown> Fazes bem.
  wait 2
  unknown> Já sabes o que diz.
  set note_unread=true
endif
@end

@beat second_copy
@when beat("found_book") and since("found_book", 20)
unknown> Há outro exemplar, na estante de baixo. O da Carla.
choice unknown c8l_copies
  > [Levar também o de baixo] | set took_both=true
  > [Deixá-lo onde está] | set took_both=false
end
if flag("took_both")
  wait 3
  world think Na folha de rosto do segundo, a lápis: «Para o D., quando precisar disto. — I.» A Carla nunca escreve nos livros.
  clue ines_dedication
endif
wait 6
unknown> Agora vai-te embora.
wait 2
unknown> Não corras.
world presence hunt 50
@end

# ---------------------------------------------------------------- luz: da rua vê-se tudo
@beat lights_seen
@when flag("w_lit_livraria") and not flag("bookshop_seen")
set bookshop_seen=true
wait 40
if v("trust_joao") >= 1 and not flag("joao_gone")
  joao> vi luz na livraria. és tu?
  joao> a esta hora dani?
  choice joao c8l_joao
    > Sou eu. Não digas a ninguém. | set joao_knows_bookshop=true inc trust_joao 1
    > Não sou eu. | inc trust_joao -1
  end
  wait 6
  if flag("joao_knows_bookshop")
    joao> nao digo
    joao> mas apaga isso. a rua do cais tem olhos
  else
    joao> ok
    joao> entao ha alguem na tua livraria
  endif
endif
@end

# ---------------------------------------------------------------- sair
@beat leave
@when flag("found_card") and flag("w_saiu_livraria")
world presence calm
wait 2
world think A rua cheira a mar. A porta fecha-se atrás de mim com o sino da Carla.
wait 4
unknown> Agora tens o que eu te dei.
wait 3
unknown> Lê quando for de dia.
wait 4
lock
wait 2
endchapter
@end

@beat dawn_nudge
@when at("04:40") and flag("found_card") and not flag("w_saiu_livraria")
world think Está a clarear por trás da montra. Tenho de sair antes que alguém passe.
@end

@beat dawn_end
@when at("05:00") and not beat("leave")
if not flag("found_card")
  unknown> Amanhece às 07:41.
  wait 2
  unknown> Eu espero. Estou habituada.
  set card_missed_night=true
else
  world think Saí pela porta das traseiras. Não me lembro de a abrir.
endif
wait 4
lock
wait 2
endchapter
@end
