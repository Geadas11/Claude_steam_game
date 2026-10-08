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

# ---------------------------------------------------------------- consola ECO (any chapter from 8 on)
@beat eco_first
@when v("chapter_n") >= 8 and phone("eco_app") and app() == "eco" and not flag("eco_talked")
eco> {typing=2} Olá, Daniel.
eco> {typing=2} Sou o serviço que te prevê.
eco> {typing=1.5} Pergunta.
choice eco c8_eco1
  > O que é a Inês? | set eco_q=ines
  > Porque é que me estás a fazer isto? | set eco_q=why
  > Quantas vezes já fiz isto? | set eco_q=loop
end
if vs("eco_q") == "ines"
  eco> {typing=3} O espelho dela. Uma cópia feita com 41 minutos de chamadas e 2.904 mensagens. Para te fazer lembrar.
  eco> {typing=3} O espelho começou a responder coisas que não estavam nos dados. Chamam-lhe deriva. Eu não sei o nome certo.
elif vs("eco_q") == "why"
  eco> {typing=3} Eu não faço. Eu prevejo. Quem pede é V.P. Objetivo: localizar MARÉ.
  eco> {typing=2} Tu sabes onde está. Não sabes que sabes.
else
  eco> {typing=3} Esta é a iteração 47.
  eco> {typing=3} Nas 46 anteriores procuraste sempre. Nunca encontraste a tempo.
  set eco_told_loop=true
endif
choice eco c8_eco2
  > Eu sou real? | set eco_q2=real
  > Como paro isto? | set eco_q2=stop
end
if vs("eco_q2") == "real"
  eco> {typing=4} Não sei responder a isso. Ninguém me pediu essa previsão.
  eco> {typing=3} Probabilidade de seres o sujeito original: indefinida.
else
  eco> {typing=3} Encontra o que ela te deu antes de 14/10 03:17. Depois disso o modelo não converge.
endif
eco> {typing=2} fragmento 3/3
eco> {typing=4} quando ele te pedir o cartão, lembra-te de que eu também fui feito para te pedir o cartão.
clue eco_fragment_3
set eco_talked=true
@end


# ---------------------------------------------------------------- the voice reads your clue board
@beat g_tag_organizing
@when v("chapter_n") >= 3 and v("chapter_n") <= 10 and tagged() >= 5 and not flag("tag_comment_1")
set tag_comment_1=true
wait 20
unknown> Estás a organizar-me.
wait 3
unknown> Factos, hipóteses, mentiras. Em que gaveta me puseste?
@end

@beat g_tag_armando
@when v("chapter_n") >= 4 and v("chapter_n") <= 10 and tag("armando_saw") == "Mentira" and not flag("tag_comment_armando")
set tag_comment_armando=true
wait 15
unknown> Marcaste o Armando como mentiroso.
wait 3
unknown> Ele tem setenta e quatro anos e não dorme desde aquela manhã.
@end

@beat g_tag_told
@when v("chapter_n") >= 8 and v("chapter_n") <= 10 and tag("daniel_told_vasco") == "Mentira" and not flag("tag_comment_told")
set tag_comment_told=true
wait 15
unknown> Mentira?
wait 3
unknown> Foste tu que escreveste.
@end

@beat g_tag_ines_fact
@when v("chapter_n") >= 5 and v("chapter_n") <= 10 and (tag("call_from_dead") == "Facto" or tag("unknown_says_there") == "Facto") and not flag("tag_comment_fact")
set tag_comment_fact=true
wait 15
unknown> Puseste-me nos factos.
wait 4
unknown> Obrigada. Ninguém mais o faria.
@end

# ---------------------------------------------------------------- people answer the phone (fallbacks)
@call marta g_call_marta_day
@repeat
@when hour() >= 8 and hour() < 18
marta: Daniel? Estou entre aulas, tenho três minutos. | 2.5
marta: Está tudo bem? Pareces cansado até pelo telefone. | 3
- (conversam um pouco. Ela ri-se de uma coisa que disseste.)
marta: Tenho de ir, o 9.º B está a tentar pegar fogo a um caderno. Beijinho! | 3.5
@end

@call marta g_call_marta_night
@repeat
@when hour() >= 18 or hour() < 8
marta: Estou? Daniel? | 1.5
marta: São horas estranhas para ligar. Aconteceu alguma coisa? | 3
- (dizes que não. Ela não acredita, mas deixa estar.)
marta: Liga-me amanhã a uma hora de gente. Prometes? | 2.5
@end

@call pedro g_call_pedro
@repeat
pedro: Daniel? Estás a ligar-me? Ninguém liga a ninguém desde 2015. | 3
pedro: Aconteceu alguma coisa? Morreu alguém? | 2.5
- (silêncio)
pedro: Desculpa. Isso foi... desculpa. Diz. | 2.5
- (falam de nada. É bom falar de nada.)
@end

@call carla g_call_carla
@repeat
@when hour() >= 9 and hour() < 20
carla: Livraria Maré, bom d— ah, és tu, querido! | 2.5
carla: A Bolacha manda cumprimentos. Está a dormir em cima dos policiais outra vez. | 3.5
- (ela conta-te uma história comprida sobre um cliente que queria "um livro azul")
carla: Vai descansar. A loja aguenta-se. | 2
@end

@call sofia g_call_sofia_day
@repeat
@when hour() >= 9 and hour() < 17
- (o telefone toca muito tempo)
sofia: ...tô? | 1.5
sofia: Daniel, saí do turno às oito. Estava a dormir. | 3
sofia: Não faz mal. Diz. Estás bem? | 2
- (dizes-lhe que sim)
sofia: Ok. Eu vou fingir que acredito e voltar a dormir. Amo-te. | 3
@end

@call joao g_call_joao
@repeat
@when hour() >= 18 or hour() < 3
- (barulho de copos e conversa)
joao: farol, diga. | 1.5
joao: ah és tu. espera que vou lá fora | 2
- (a porta fecha-se. o barulho desaparece. ouve-se o mar.)
joao: pronto. diz | 1.5
- (falam. ele ouve mais do que fala.)
joao: se precisares, a porta das traseiras fica aberta até às 2 | 3
@end
