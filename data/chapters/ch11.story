# =====================================================================
# CAPÍTULO 11 — A CLÍNICA
# terça-feira, 13 de outubro de 2026, 14:00 → 19:00
# Vai à consulta das 14h para tirar a própria ficha. A Helena: "já
# falámos disto na terça"; diz que ele confessou sedado (P-I, sem
# gravação). Um quarto já preparado com o nome dele. A clínica fecha às
# sete com ele lá dentro: as luzes apagam-se por zonas, as portas
# fecham-se sozinhas (a coisa: "ser fechado"). Exceção ao R6: pode matar.
# Ficar = final B. Fugir pela escada de serviço = segue.
# =====================================================================
@chapter ch11
@title A Clínica
@start 2026-10-13 14:00

@beat setup
set chapter_n=11
rate 2
ambient hum
location clinica
battery 63
wait 2
world spawn consulta
world lights on
world presence calm
wait 2
world think Vim às duas, como ela pediu. Não vim para ficar. Vim buscar o que ela escreveu sobre mim.
wait 6
world say Dra. Helena «Sente-se, Daniel. Obrigada por ter vindo. Já falámos disto na terça.»
wait 6
world think Terça é hoje.
wait 5
world say Dra. Helena «Na consulta de novembro estava muito agitado. Dei-lhe uma coisa para dormir. Antes de adormecer, disse-me uma frase.»
wait 7
world say Dra. Helena «Disse: "eu empurrei-a". Eu escrevi-o. Não gravei. Não se grava um doente naquele estado.»
clue helena_says_confessed
wait 8
world say Dra. Helena «Vou buscar os papéis do internamento. Fique aqui. Não mexa no computador, por favor.»
wait 4
world door consultorio open
set helena_out=true
@end

# ---------------------------------------------------------------- a chave do arquivo
@beat archive_locked
@when beat("setup")
world door arquivo lock
@end

@beat key_hint
@when at("14:40") and not flag("w_chaves")
unknown> O arquivo está fechado.
wait 3
unknown> A chave está no posto das enfermeiras. Agora não está lá ninguém.
@end

@beat took_key
@when flag("w_chaves") and not flag("has_archive_key")
set has_archive_key=true
world door arquivo unlock
wait 2
world think Tirei a chave com a etiqueta «Arquivo». O gancho ficou a abanar.
@end

# ---------------------------------------------------------------- a ficha
@beat found_file
@when flag("w_ficha")
wait 2
file ficha_daniel silent
notify files "Fotografias" "ficha_DReis.jpg"
clue ficha_found
wait 6
unknown> «Eu empurrei-a.»
wait 3
unknown> Sublinhado duas vezes. Com a caneta dela.
wait 4
unknown> Repara que não há data na frase.
@end

@beat computer
@when flag("w_computador") and not flag("eco_frag_3")
set eco_frag_3=true
wait 2
clue folder_047
if not clue("eco_fragment_3")
  wait 4
  toast "Na pasta 047, um ficheiro de texto com uma só linha."
  clue eco_fragment_3
endif
wait 5
unknown> 047 és tu.
wait 3
unknown> As outras quarenta e seis pastas foram apagadas.
@end

@beat room_card
@when flag("w_cartao_quarto")
wait 4
unknown> Escreveu o teu nome ontem à noite.
wait 2
unknown> Eu vi-a escrever.
clue room_ready
@end

# ---------------------------------------------------------------- a Helena volta
@beat helena_back
@when flag("helena_out") and (at("15:40") or (flag("w_ficha") and since("found_file", 60)))
world presence calm
unknown> Ela está a voltar pelo corredor.
wait 3
choice unknown c11c_stay
  > [Esperar por ela e dizer-lhe que fico] | set stayed_clinic=true
  > [Esperar por ela e perguntar quem lhe paga] | set confronted_helena=true inc trust_helena -1
  > [Esconder-me até ela passar] | set hid_from_helena=true
end
wait 2
if flag("stayed_clinic")
  world say Dra. Helena «Fez bem, Daniel. Fez muito bem.»
  wait 5
  world say Dra. Helena «Deixe-me o telemóvel. Aqui não precisa dele.»
  wait 5
  world think Dei-lho. Ela segurou-o com as duas mãos, como se pesasse.
  set final=B trust_vasco=3
  wait 6
  ending B
elif flag("confronted_helena")
  world say Dra. Helena «A Lumen paga a investigação. Não paga a minha opinião.»
  wait 6
  world say Dra. Helena «A minha opinião é que o senhor está doente e que o telemóvel o está a pôr pior.»
  wait 6
  world say Dra. Helena «A clínica fecha às sete. Se ainda cá estiver, fica. Pense nisso.»
  clue lumen_pays_helena
  set helena_confronted_clinic=true
else
  world think Os passos dela passaram a porta. Pararam. Voltaram a andar.
  wait 4
  world say Dra. Helena «Daniel? ... Daniel, está na casa de banho?»
  set helena_searching=true
endif
@end

# ---------------------------------------------------------------- lá fora a tarde continua
@beat sofia_afternoon
@when at("16:30") and not flag("stayed_clinic")
sofia> Então? Já saíste da consulta?
sofia> Não te esqueças de comer. Eu sei que não comeste
@end

@beat sofia_afternoon_reply
@when beat("sofia_afternoon") and read("sofia")
wait 1
choice sofia c11c_sofia
  > Ainda estou na clínica. Querem que eu fique. | set told_sofia_clinic=true
  > Já saí. Está tudo bem. | set told_sofia_clinic=false
end
wait 10
if flag("told_sofia_clinic")
  sofia> Ficar?? Ficar como??
  sofia> Daniel tu não assinas NADA ouviste. Nada
  sofia> Eu sou enfermeira. Ninguém fica internado assim de um dia para o outro
else
  sofia> Ok
  wait 4
  sofia> A tua localização diz Faro. Clínica Atlântico
  sofia> Desculpa. Ativámos isso no Natal, lembras-te?
endif
@end

@beat vasco_afternoon
@when at("17:30") and not flag("stayed_clinic")
vasco> A Dra. Helena diz que está a ser difícil.
vasco> Não torne isto mais difícil do que tem de ser, Daniel. Ninguém lhe quer mal.
@end

# ---------------------------------------------------------------- fecho
@beat closing_soon
@when at("18:30")
rate 1
world say Altifalante «A Clínica Atlântico encerra às dezanove horas. Agradecemos a sua visita.»
@end

@beat closing
@when at("18:45")
set clinic_closed=true
world lights off rececao
sound switch
wait 6
world lights off corredor_c
sound switch
wait 6
world lights off corredor_b
wait 4
world think As luzes estão a apagar-se de trás para a frente. Como se alguém andasse a fechar a clínica comigo lá dentro.
wait 4
world door escada close
world door consultorio close
world presence stalk 60
wait 6
unknown> Não é a Helena que está a apagar as luzes.
@end

@beat closing_dark
@when beat("closing") and since("closing", 60)
world lights off
world flicker corredor_a 2
world say Altifalante «... Daniel. ... Daniel, volte para o seu quarto.»
@end

@beat key_nudge
@when at("19:05") and flag("clinic_closed") and not flag("has_stairs_key")
unknown> O quarto que ela preparou para ti.
wait 3
unknown> Vê o que está em cima da cama.
@end

@beat stairs_nudge
@when flag("has_stairs_key") and not flag("clinic_escaped") and since("closing", 20)
unknown> A escada de serviço. Ao fundo, à direita.
wait 3
unknown> Não acendas nada. Ela está entre ti e a porta.
@end

# ---------------------------------------------------------------- sair
@beat escaped
@when flag("clinic_escaped")
world presence calm
wait 2
world think O cadeado abriu à primeira. Lá em baixo, a porta de emergência dá para o parque de estacionamento. Ainda é dia. Está a acabar.
wait 5
if flag("w_ficha")
  unknown> Tens a ficha. Ela vai dizer que a roubaste.
  wait 2
  unknown> E roubaste.
else
  unknown> Saíste sem a ficha.
  wait 2
  unknown> Ela vai dizer que fugiste. E fugiste.
endif
wait 5
lock
wait 2
endchapter
@end

@beat late_escape
@when at("19:50") and not beat("escaped") and not flag("stayed_clinic")
world think Alguém deixou a porta de emergência entreaberta. Não fui eu. Não me lembro de descer as escadas.
set clinic_escaped=true
@end

@call helena c11c_call_helena
@when not flag("stayed_clinic")
helena: Daniel, onde está? | 2
helena: Volte para o gabinete. Não faça isto mais difícil. | 3
@end
