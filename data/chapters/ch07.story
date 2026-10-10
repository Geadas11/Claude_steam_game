# =====================================================================
# CAPÍTULO 7 — CONFIANÇA
# domingo 11 → segunda 12 de outubro, 21:30 → 02:30
# Toda a gente pede confiança. Helena: "não fale com o João". A voz:
# "o João é a única pessoa em quem podes confiar". Vasco quer o telemóvel.
# Rui recebeu uma mensagem. Clara precisa de uma prova. Uma mensagem do
# João que o João não escreveu.
# =====================================================================
@chapter ch07
@title Confiança
@start 2026-10-11 21:30

@beat setup
set chapter_n=7
rate 1
ambient night
location casa
battery 52
contact ines silent
@end

# ---------------------------------------------------------------- Helena vs. voz
@beat helena_warn
@when since("setup", 5)
helena> Daniel, desculpe a hora. Preciso de lhe pedir uma coisa como sua médica.
helena> Não fale com o João Cardoso nos próximos dias. Sei coisas do passado dele que não posso partilhar. 2017. Não é boa influência neste momento.
clue helena_warns_joao
@end

@beat voice_joao
@when beat("helena_warn") and since("helena_warn", 20)
unknown> O João é a única pessoa em quem podes confiar.
@end

@beat helena_reply
@when beat("helena_warn") and read("helena")
wait 1
choice helena c7_helena
  > Como é que conhece o João? | set asked_helena_joao=true
  > Está bem. Não falo com ele. | set promised_helena=true inc trust_helena 1
  > O João é meu amigo há vinte anos. | set defended_joao=true inc trust_joao 1
end
wait 6
if flag("asked_helena_joao")
  helena> Falou-me dele nas consultas, Daniel. Muitas vezes.
  helena> E tenho outras fontes. Confie em mim.
  choice helena c7_helena2
    > Que outras fontes? | set pressed_helena=true
    > Ok. Confio. | set promised_helena=true inc trust_helena 1
  end
  wait 6
  if flag("pressed_helena")
    helena> Amanhã falamos. Às 9h. Por favor.
    clue helena_other_sources
  endif
elif flag("promised_helena")
  helena> Obrigada. É o melhor para si. Amanhã às 9h, lembre-se.
else
  helena> Os amigos de vinte anos também se enganam, Daniel. Pense nisso.
endif
@end

# ---------------------------------------------------------------- João, 2017
@beat joao_2017
@when beat("helena_warn") and app() == "messages:joao" and not flag("promised_helena")
choice joao c7_joao
  > O que é que aconteceu em 2017? | set asked_2017=true
  > Preciso da tua ajuda. Confio em ti. | set joao_ally=true inc trust_joao 2
  > [Fechar a conversa]
end
if flag("asked_2017")
  wait 15
  joao> quem te falou disso
  choice joao c7_joao2
    > A minha psiquiatra. | set told_joao_helena=true
    > Não interessa. | set told_joao_helena=false
  end
  wait 10
  joao> 2017 parti a cara a um gajo que tava a bater na namorada a porta do bar
  joao> pena suspensa. pior e melhor coisa q fiz
  joao> nunca te contei pq tinha vergonha
  if flag("told_joao_helena")
    wait 4
    joao> e como e q a tua psiquiatra sabe disso? eu nunca a vi na vida
    clue helena_knows_joao_record
  endif
  wait 4
  joao> precisas de mim para alguma coisa?
  choice joao c7_joao3
    > Preciso. Confio em ti. | set joao_ally=true inc trust_joao 2
    > Agora não. Obrigado. | set joao_ally=false
  end
endif
if flag("joao_ally")
  wait 6
  joao> conta comigo. o q for
  joao> e dani: eu tava no farol ate as 2 nessa noite. a marta e o pedro tavam la. so pra saberes q eu nao tenho nada a ver com isto
  set joao_alibi_known=true
  clue joao_alibi
endif
@end

# ---------------------------------------------------------------- Vasco
@beat vasco_msg7
@when at("22:30")
if flag("meet_vasco")
  vasco> Daniel, obrigado pela conversa de hoje de manhã. Fiquei mais descansado.
  vasco> E obrigado por ter deixado a equipa olhar para o telemóvel. Disseram-me que está tudo normal.
  set vasco_claims_meeting=true
else
  vasco> Daniel, tive pena que não pudéssemos tomar o café.
endif
vasco> Ouça, uma sugestão: traga-me o telemóvel amanhã. Pode ser um defeito do ECO Care. Damos-lhe um novo, sem custos, com tudo migrado.
@end

@beat vasco_reply7
@when beat("vasco_msg7") and read("vasco")
wait 1
choice vasco c7_vasco
  > {if flag("vasco_claims_meeting")} Que conversa? Eu não saí de casa hoje. | set vasco_meeting_lie=true inc trust_vasco -1
  > Está bem. Levo-lho amanhã. | set agreed_phone_vasco=true inc trust_vasco 1
  > O que é o ECO Mirror? | set asked_mirror=true inc trust_vasco -1
  > Não, obrigado. O telemóvel fica comigo. | set refused_vasco=true
end
wait 8
if flag("vasco_meeting_lie")
  vasco> Às 11h, no Café Central. Esteve lá quase uma hora, Daniel. Pediu um galão.
  vasco> Está a sentir-se bem?
  clue vasco_meeting_claim
  wait 3
  unknown> Vê a tua cronologia. Diz-me onde estiveste às 11h.
elif flag("asked_mirror")
  typing vasco vasco 9
  wait 5
  vasco> Onde ouviu esse nome?
  wait 4
  vasco> É um produto empresarial. Nada que lhe diga respeito. Boa noite, Daniel.
  set vasco_rattled=true
  clue vasco_rattled_mirror
elif flag("agreed_phone_vasco")
  vasco> Excelente. Vai ver que fica tudo bem.
  wait 6
  unknown> Não lhe dês o telefone.
  unknown> Se lhe deres o telefone, eu deixo de existir. E tu deixas de saber.
else
  vasco> Como queira. A oferta fica.
endif
@end

# ---------------------------------------------------------------- Rui
@beat rui_message
@when at("23:15")
contact rui silent
setting rui_known true
rui> Recebi uma mensagem do número dela. Há uma hora.
rui> Dizia: "Diz ao Daniel que eu não caí."
clue rui_got_message
@end

@beat rui_reply7
@when beat("rui_message") and read("rui")
wait 1
choice rui c7_rui
  > Rui, há uma testemunha que me viu no cais com ela. E acho que alguém chegou depois de mim. | set told_rui_all=true inc trust_rui 2
  > Não sei quem escreve essas mensagens. | set told_rui_all=false
  > Não confies nessas mensagens. Nem em mim. | set rui_warned=true inc trust_rui 1
end
wait 25
if flag("told_rui_all")
  rui> Quem?
  rui> Quem é que chegou depois de ti?
  choice rui c7_rui2
    > Ainda não sei. Mas vou descobrir. | set promised_rui=true inc trust_rui 1
    > Acho que foi alguém da Lumen. | set suspect_lumen_rui=true inc trust_rui 1
  end
  wait 15
  rui> Quando souberes, dizes-me primeiro. Antes da polícia. Antes de toda a gente.
  rui> Eu tenho uma coisa que nunca serviu para nada. Talvez agora sirva.
  set rui_ally=true
elif flag("rui_warned")
  rui> Eu não confio em ninguém há um ano. Não vou começar por ti.
  wait 4
  rui> Mas obrigado por avisares.
else
  rui> Ok.
endif
@end

# ---------------------------------------------------------------- Clara
@beat clara_update
@when at("23:50") and flag("clara_talked")
clara> Fiz algumas perguntas. A Lumen tem um contrato com a Clínica Atlântico que não está publicado em lado nenhum.
clara> Preciso de uma prova. Uma só. Um documento, uma gravação. Com isso eu avanço.
@end

@beat clara_reply7
@when beat("clara_update") and read("clara")
wait 1
choice clara c7_clara
  > Vou arranjar-lhe essa prova. | set clara_ally=true inc trust_clara 1
  > Porque é que eu devia confiar numa jornalista? | set doubt_clara=true
end
wait 30
if flag("clara_ally")
  clara> Combinado. E Daniel: se a Inês lhe deu alguma coisa, não a entregue a ninguém da Lumen. Nem que lhe ofereçam o mundo.
else
  clara> Não devia. Devia confiar nos documentos. Arranje-os.
endif
@end

# ---------------------------------------------------------------- a mensagem falsa do João
@beat fake_joao
@when at("00:30")
joao> nao venhas ao bar hoje. nem amanha
joao> esquece-me dani. a serio
set fake_joao_sent=true
@end

@beat fake_joao_reply
@when beat("fake_joao") and read("joao")
wait 1
choice joao c7_fake
  > João? O que se passa? | set asked_fake=true
  > Está bem. | set accepted_fake=true inc trust_joao -1
  > [Não responder]
end
wait 12
if v("trust_joao") >= 2 or flag("asked_fake")
  joao> dani do q tas a falar
  joao> eu nao te mandei nada
  wait 5
  joao> tou a ver o meu telemovel. nao ta aqui nenhuma mensagem enviada
  joao> alguem ta a mexer nisto
  clue fake_joao_message
  set joao_denied_fake=true
else
  set joao_drifting=true
endif
@end

# ---------------------------------------------------------------- o telefone escreve sozinho
@beat self_typing
@when at("00:48")
open messages unknown
wait 2
autotype unknown "estou a ver-te" send
set phone_typed_alone=true
wait 6
unknown> Eu sei.
wait 2
unknown> Eu também te vejo.
clue phone_typed_alone
@end

# ---------------------------------------------------------------- a voz pede confiança
@beat trust_ines
@when at("01:05")
unknown> Confias em mim?
choice unknown c7_trust
  > Confio. | set trusts_voice=true inc trust_ines 1
  > Não sei o que és. | set trusts_voice=unsure
  > Não. | set trusts_voice=false inc trust_ines -1
end
wait 8
if vs("trusts_voice") == "unsure"
  unknown> Isso é a resposta mais honesta que me deste.
elif vs("trusts_voice") == "false"
  unknown> Fazes bem. Eu também não confiava em mim.
else
  unknown> Então amanhã faz o que eu te disser. Só amanhã.
endif
@end

# ---------------------------------------------------------------- a janela
@beat window
@when at("01:22")
camera window
unknown> Não te assustes.
wait 3
unknown> Abre a câmara e aponta para a janela da sala.
@end

@beat window_seen
@when flag("cam_window_seen")
wait 5
unknown> Eu disse para não te assustares.
wait 3
choice unknown c7_window
  > Eras tu? | set window_q=you
  > Há alguém lá fora? | set window_q=outside
  > [Não responder]
end
wait 6
if vs("window_q") == "you"
  unknown> Não sei. Às vezes vejo-me de fora.
elif vs("window_q") == "outside"
  unknown> Agora já não.
endif
clue window_face
@end

# ---------------------------------------------------------------- Helena sabe demais
# ---------------------------------------------------------------- a Sofia que não é a Sofia
@beat fake_sofia
@when at("01:30")
if v("deaths_ch07") >= 1
  rename sofia "Sofai"
endif
call sofia id=c7_fake_sofia ring=20
  [sfx static]
  wait 1.5
  sofia: Daniel? | 1.6
  wait 1
  sofia: Sou eu. Estás sozinho? | 2.2
  wait 1.5
  sofia: Apaga as luzes, Daniel. Quero ouvir-te melhor. | 3
  [sfx breath]
  wait 2
  sofia: Porque é que não dizes nada? | 2.4
  - (do outro lado, o mar)
end
if v("deaths_ch07") >= 1
  rename sofia "Sofia"
endif
if answered("c7_fake_sofia")
  clue fake_sofia_call
  world presence hunt 40
  wait 6
  unknown> Ela está de turno até às oito. Nunca te ligou a esta hora.
  wait 3
  unknown> E nunca te chamou Daniel.
else
  wait 4
  unknown> Fizeste bem.
endif
wait 40
sofia> Mano tudo bem? Tenho uma chamada tua perdida às 01:30. Eu estava a meio de uma algaliação
sofia> Ou fui eu que te liguei?? O telemóvel diz que fui eu. Eu não te liguei
set real_sofia_after_fake=true
@end

@beat helena_knows
@when at("01:40")
helena> Daniel, está acordado?
helena> Precisamos de falar sobre o que encontrou no restauro. Antes de falar com mais alguém.
clue helena_knows_restore
@end

@beat helena_knows_reply
@when beat("helena_knows") and read("helena")
wait 1
choice helena c7_helena3
  > Como é que sabe do restauro? | set asked_helena_restore=true inc trust_helena -1
  > Amanhã às 9h. | set agreed_helena=true inc trust_helena 1
  > [Não responder]
end
wait 12
if flag("asked_helena_restore")
  helena> O Daniel contou-me. Ao telefone. Esta tarde.
  wait 4
  helena> Não se lembra?
  clue helena_says_he_called
endif
@end

# ---------------------------------------------------------------- final
@beat tomorrow
@when beat("trust_ines") and at("02:10")
unknown> Amanhã vou mostrar-te o que corre dentro do teu telefone.
wait 3
unknown> Vai a Definições. Sobre o telefone. Não toques em nada até eu dizer.
wait 8
checkpoint
@end

@beat end_ch7
@when beat("tomorrow")
wait 6
lock
wait 2
endchapter
@end

@call joao c7_call_joao
joao: dani. tas bem? | 1.5
joao: se for por causa da mensagem que a tua medica diz, eu explico tudo. pessoalmente. | 4
@end

@call vasco c7_call_vasco
vasco: Daniel. É tarde. | 1.5
vasco: Traga-me o telemóvel amanhã e acabamos com isto. Para bem de todos. | 3.5
@end

# ---------------------------------------------------------------- o primo do Pedro
@beat pedro_cousin
@when at("22:50")
pedro> Daniel. o João contou-me que andas a investigar a rapariga da Lumen
pedro> eu sei que acham que eu só falo de criptomoedas mas ouve
pedro> o meu primo trabalha na segurança da Lumen. diz que há um piso no edifício 3 onde só entram 4 pessoas. chamam-lhe "o aquário"
pedro> e diz que na noite de 13 para 14 de outubro do ano passado o carro do diretor saiu do parque às 2 e meia e só voltou às 5
clue pedro_cousin
@end

@beat pedro_cousin_reply
@when beat("pedro_cousin") and read("pedro")
wait 1
choice pedro c7_pedro
  > O carro do diretor... um Audi cinzento? | set asked_pedro_audi=true
  > Obrigado, Pedro. A sério. | set thanked_pedro=true
end
wait 8
if flag("asked_pedro_audi")
  pedro> como é que sabes??
  pedro> sim. o Pimentel. ocupa dois lugares. toda a gente odeia
  clue vasco_audi
else
  pedro> de nada. e Daniel, apaga esta conversa. o meu primo precisa do emprego
endif
@end

# ---------------------------------------------------------------- Rita
@beat rita_admission
@when flag("rita_talked") and at("00:05")
rita> a dra. sousa quer internar-me. "uns dias". diz que estou a piorar
rita> diz que devo entregar o telemóvel à clínica. para "desintoxicar"
rita> o que faço daniel
@end

@beat rita_admission_reply
@when beat("rita_admission") and read("rita")
wait 1
choice rita c7_rita
  > Não entregues o telemóvel. Guarda tudo o que lá está. | set rita_keep=true
  > Talvez seja melhor descansares. Confia nela. | set rita_keep=false
end
wait 15
if flag("rita_keep")
  rita> ok. ok. vou dizer que o perdi
  rita> obrigada. és a primeira pessoa que não me diz que estou a inventar
else
  rita> ok... se calhar tens razão
  rita> amanhã vou. depois digo-te
  set rita_gave_phone=true
endif
@end

@beat eco_care_7
@when at("23:59")
notify settings "ECO Care" "Esta semana marca um ano desde uma perda importante. Estamos aqui consigo."
wait 10
unknown> "Uma perda importante."
unknown> Eles sabem a data melhor do que tu.
@end

# ---------------------------------------------------------------- Sofia e a gaveta
@beat sofia_drawer
@when at("23:35") and flag("sofia_has_old_phone")
sofia> Fui buscar o teu telemóvel velho à gaveta para o carregar
sofia> Estava dentro de um envelope com um bilhete de comboio. Faro–Lisboa, 15 de outubro do ano passado, 07:10
sofia> Comprado no dia 14 às 05:12. Nunca foi usado
sofia> Ias ter comigo?
@end

@beat sofia_drawer_reply
@when beat("sofia_drawer") and read("sofia")
wait 1
choice sofia c7_sofia
  > Não me lembro de o comprar. | set sofia7=blank
  > Ia. Depois não consegui sair de casa. | set sofia7=honest inc trust_sofia 1
  > Deita isso fora. | set sofia7=away
end
wait 20
if vs("sofia7") == "honest"
  sofia> Eu tinha ido buscar-te à estação
  wait 3
  sofia> Ainda vou, se quiseres. Não precisas de bilhete para isso
elif vs("sofia7") == "blank"
  sofia> Às 5 e 12 da manhã, Daniel. Uma hora depois de... 
  wait 4
  sofia> Ok. Não te lembras. Eu guardo-o
else
  sofia> Não deito. Fica comigo, junto com o telemóvel
  sofia> Um dia perguntas-me por ele
endif
clue train_ticket
@end
