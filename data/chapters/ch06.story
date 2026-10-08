# =====================================================================
# CAPÍTULO 6 — A INVESTIGAÇÃO TORNA-SE PESSOAL
# domingo, 11 de outubro de 2026, 11:00 → 20:30
# Alguém pediu, às 03:17, o restauro da cópia de segurança do telemóvel
# antigo. Fotografias, emails e a última conversa com a Inês voltam.
# O Daniel não "mal a conhecia". O João mentiu. A Dra. Helena mente.
# "Estou a investigar outra pessoa ou a investigar-me a mim próprio?"
# =====================================================================
@chapter ch06
@title A Investigação Torna-se Pessoal
@start 2026-10-11 11:00

@beat setup
set chapter_n=6
rate 2
ambient room
location casa
battery 88
set clock_extra_city=true
@end

# ---------------------------------------------------------------- o restauro
@beat restore
@when since("setup", 4)
email lumen_cloud_restore
photo IMG_3398 silent Recuperadas
photo IMG_3366 silent Recuperadas
photo IMG_3302 silent Recuperadas
photo IMG_3301 silent Recuperadas
photo IMG_3240 silent Recuperadas
photo IMG_3102 silent Recuperadas
photo IMG_3010 silent Recuperadas
email ines_old_1 silent
email sent_daniel_ines silent
email ines_old_2 silent
email ines_old_3 silent
email ines_old_4 silent
file gravacao_002 silent
ines> {date=2025-09-14 23:58,silent} Obrigada por teres vindo. Mesmo tendo ficado o tempo todo a falar com o Rui sobre barcos
me@ines> {date=2025-09-15 00:03,silent} O teu irmão é fixe. Assustador, mas fixe
ines> {date=2025-09-15 00:04,silent} ele diz o mesmo de ti. sem o "fixe"
ines> {date=2025-10-13 21:39,silent} Posso ligar-te?
ines> {date=2025-10-13 22:30,silent} Não consigo dormir. Encontras-te comigo no cais? 2h30. Tenho uma coisa para te dar.
me@ines> {date=2025-10-13 22:41,silent} Vou.
ines> {date=2025-10-14 02:29,silent} Já cá estou
ines> {date=2025-10-14 03:12,silent} Daniel volta
ines> {date=2025-10-14 03:15,silent} Ele está aqui
me@ines> {date=2025-10-14 03:16,silent,deleted} .
notify gallery "Fotografias" "214 itens restaurados · álbum Recuperadas"
set restored=true
@end

@beat restore_seen
@when beat("restore") and app() == "messages:ines"
clue ines_last_messages
set read_last_messages=true
@end

@beat restore_unknown
@when beat("restore") and since("restore", 25)
unknown> Não fui eu que pedi o restauro.
wait 3
unknown> Às 03:17 eu estava contigo.
@end

@beat barely_knew
@when beat("restore") and viewed("IMG_3301") and flag("said_barely_knew")
wait 5
unknown> "Mal a conhecia."
wait 3
unknown> Disseste isso à Sofia na quinta.
clue barely_knew_lie
@end

# ---------------------------------------------------------------- Sofia liga
@beat sofia_call
@when at("11:50")
call sofia id=c6_sofia ring=18
  sofia: Bom dia. Dormiste alguma coisa? | 2.5
  sofia: Ontem assustaste-me. Aquela coisa da mensagem. | 3
  - (ouves-te a explicar o restauro, as fotografias)
  wait 1
  sofia: Daniel... vocês eram próximos. Eu sabia. Toda a gente sabia. | 4
  sofia: Tu é que disseste, uma semana depois, que mal a conhecias. E eu deixei. Achei que era a tua maneira de aguentar. | 6
  wait 1.5
  sofia: Ouve. Eu tenho o teu telemóvel antigo numa gaveta. Deste-mo em novembro e disseste "faz o que quiseres com isto". Nunca fiz nada. | 6
  sofia: Queres que o veja? | 2
end
if answered("c6_sofia")
  set sofia_has_old_phone=true
  clue sofia_old_phone
else
  wait 5
  sofia> Liguei-te. Tenho o teu telemóvel antigo numa gaveta, lembrei-me agora. Queres que o tente ligar?
  set sofia_has_old_phone=true
  clue sofia_old_phone
endif
@end

@beat sofia_phone_reply
@when flag("sofia_has_old_phone") and app() == "messages:sofia"
choice sofia c6_sofia_phone
  > Sim. Por favor. Vê se ainda liga. | set ask_old_phone=true
  > Não sei se quero saber o que lá está. | set ask_old_phone=false
end
wait 4
if flag("ask_old_phone")
  sofia> Ok. Hoje à noite não posso, tenho turno. Amanhã à noite trato disso
else
  sofia> Ok. Fica aqui guardado. Quando quiseres
  set ask_old_phone=true
endif
@end

# ---------------------------------------------------------------- Helena
@beat helena_vm
@when at("12:40")
calllog helena missed 12:39
voicemail vm_helena
wait 30
email helena_concern
@end

@beat helena_vm_heard
@when file_open("vm_vm_helena")
wait 6
unknown> Ela não te devia ligar ao domingo.
wait 2
unknown> Pergunta-lhe quem lhe contou que não dormes.
@end

# ---------------------------------------------------------------- conta
@beat ines_account
@when at("13:05")
set ines_account=true
notify settings "Contas" "A sincronizar: ines.matos@lumen.pt"
@end

# ---------------------------------------------------------------- João
@beat joao_confront
@when clue("joao_knew_ines") and app() == "messages:joao"
choice joao c6_joao
  > Tu conhecias a Inês. Estás na fotografia dos anos dela. | set confront_joao=true
  > [Fechar a conversa] | set confront_joao=false
end
if flag("confront_joao")
  wait 20
  joao> conhecia
  joao> eramos amigos. ela vinha ao bar quase todas as sextas
  joao> nao te disse pq tu nao querias falar dela. a sofia pediu-me para nao tocar no assunto
  wait 5
  joao> e ha outra coisa
  typing joao joao 8
  wait 4
  joao> nessa noite as 3 e 40 passaste em frente ao bar. eu tava a fechar
  joao> tavas encharcado ate aos joelhos. com areia ate as canelas
  joao> disseste que tinhas caido. pediste para eu nao dizer a ninguem
  joao> e eu nao disse. ate hoje
  clue joao_saw_daniel
  set joao_told_truth=true
  inc trust_joao 1
  choice joao c6_joao2
    > Porque é que nunca me disseste? | set joao_why=true
    > Obrigado por me dizeres agora. | set joao_thanks=true inc trust_joao 1
    > Não sei se acredito em ti. | set joao_doubt=true inc trust_joao -1
  end
  wait 8
  if flag("joao_why")
    joao> pq tu tavas a desfazer-te. e pq eu achei q se dissesse alguem ia pensar o pior de ti
    joao> eu nunca pensei o pior de ti dani
  elif flag("joao_thanks")
    joao> devia ter dito ha um ano
  else
    joao> ok
    joao> eu percebo
  endif
endif
@end

@beat joao_voicemail
@when at("15:30") and not flag("joao_told_truth")
calllog joao missed 15:29
voicemail vm_joao
@end

@beat joao_unprompted
@when at("16:10") and not flag("joao_told_truth")
joao> dani deixei-te uma mensagem de voz
joao> nessa noite as 3 e 40 passaste em frente ao bar. tavas encharcado ate aos joelhos
joao> pediste para eu nao dizer a ninguem. e eu nao disse
joao> desculpa
clue joao_saw_daniel
set joao_told_truth=true
@end

# ---------------------------------------------------------------- Rui
@beat rui_comment
@when at("17:00") and phone("rui_known")
rui> Vi o teu comentário na página dela.
rui> "Desculpa." Escreveste isso no dia em que ela morreu. Às 23:58.
rui> Desculpa o quê?
clue memorial_daniel_comment
@end

@beat rui_comment_reply
@when beat("rui_comment") and read("rui")
wait 1
choice rui c6_rui
  > Acho que discutimos nessa noite. No cais. Fui-me embora e deixei-a lá sozinha. | set rui6=honest inc trust_rui 2
  > Não me lembro de ter escrito isso. | set rui6=forgot
  > Não te devo explicações. | set rui6=cold inc trust_rui -1
end
wait 30
if vs("rui6") == "honest"
  rui> ...
  wait 6
  rui> Obrigado por dizeres.
  wait 3
  rui> Isso não quer dizer que te perdoe.
  wait 3
  rui> Quer dizer que agora sei mais do que a polícia.
  set rui_ally_seed=true
  wait 40
  rui> Os pais dela deram-me um caixote com as coisas da secretária. Nunca o abri até hoje.
  wait 4
  rui> Tirei-te fotografias. Tu é que sabes ler a letra dela.
  rui> [photo:IMG_RUI_DESK]
  wait 2
  rui> [photo:IMG_RUI_CAL]
  achieve her_handwriting
elif vs("rui6") == "forgot"
  rui> Tu não te lembras de nada. Que conveniente.
else
  rui> Vais dever. Mais cedo ou mais tarde.
endif
@end

@beat forum_nudge
@when at("16:10") and visited("forum_lumen") and not visited("forum_profile")
unknown> ex_lumen_qa.
wait 3
unknown> Nunca te perguntaste quem avisava toda a gente?
@end

# ---------------------------------------------------------------- final
@beat yourself
@when at("19:40")
wait 2
unknown> Já reparaste?
wait 4
unknown> Começaste a procurar quem me escreve.
unknown> Agora só procuras o que tu fizeste.
choice unknown c6_self
  > Eu não fiz nada. | set c6_self=denial
  > O que é que eu fiz, Inês? | set c6_self=ask inc trust_ines 1
  > [Não responder]
end
wait 8
if vs("c6_self") == "ask"
  unknown> Foste-te embora.
  wait 4
  unknown> E antes disso fizeste outra coisa. Mas essa ainda não estás pronto para ver.
elif vs("c6_self") == "denial"
  unknown> Então porque é que tens areia nos sapatos há um ano?
endif
wait 8
note note_quem
@end

@beat end_ch6
@when beat("yourself")
wait 10
lock
wait 2
endchapter
@end

@call helena c6_call_helena
helena: Daniel. Que bom que ligou. | 2
helena: Como está a dormir? | 2
- (contas-lhe pouco. Ela ouve.)
helena: Como falámos na terça, é normal a memória preencher os vazios com histórias. Algumas parecem muito reais. | 5
helena: Não partilhe essas histórias com ninguém antes de falarmos. Nem com a sua irmã. Nem com o seu amigo do bar. | 5
helena: Pode vir amanhã às nove? | 2
set helena_wants_meeting=true
inc trust_helena 1
@end

@call joao c6_call_joao
joao: dani. | 1
joao: nao ao telefone. manda mensagem ou passa no bar. | 2.5
@end

# ---------------------------------------------------------------- a mãe liga ao domingo
@beat mae_call
@when at("18:15") and called("mae") == 0
call mae id=c6_mae ring=20
  mae: Está? Daniel? | 1.5
  mae: Ah, atendeste! A tua irmã disse que não atendias ninguém. | 3
  mae: Guardei-te bacalhau. Está no congelador. Quando vieres levas. | 3.5
  - (ela fala do tempo, da vizinha, da missa)
  wait 1.5
  mae: Quarta é aquele dia, não é. Da menina. | 3
  mae: Eu vou acender uma vela por ela. E outra por ti. | 3.5
  wait 1
  mae: Daniel... tu estás a comer? | 2
  - (dizes que sim)
  mae: Pronto. Eu acredito. As mães acreditam sempre. Beijinho, filho. | 3.5
end
if not answered("c6_mae")
  voicemail vm_mae
endif
@end

@call mae c6_call_mae
mae: Daniel! Ligaste ao domingo! | 2
mae: Estou tão contente. Guardei-te bacalhau. | 2.5
- (falam de nada durante dez minutos. Sabe bem.)
mae: Quarta acendo uma vela pela menina. E outra por ti. Beijinho, filho. | 4
@end


# ---------------------------------------------------------------- o fundo de ecrã muda enquanto olhas
@beat wallpaper_changes
@when app() == "home" and since("setup", 60) and not photo_is("IMG_2207", "watcher")
wait 8
if app() == "home"
  glitch 0.12 0.15
  variant IMG_2207 watcher
  set saw_wallpaper_change=true
else
  variant IMG_2207 watcher
endif
@end

@beat wallpaper_fallback
@when at("15:00") and not photo_is("IMG_2207", "watcher")
variant IMG_2207 watcher
@end

# ---------------------------------------------------------------- escrever na conversa antiga
@beat write_old_thread
@when beat("restore_seen") and app() == "messages:ines"
wait 6
choice ines c6_old
  > Desculpa. | set old_msg=sorry
  > Estás aí? | set old_msg=there
  > [Fechar a conversa] | set old_msg=none
end
if vs("old_msg") != "none"
  wait 3
  toast "Mensagem não entregue · número inativo desde 14/10/2025"
  wait 12
  unknown> Escreveste no sítio errado.
  wait 3
  unknown> Eu agora estou aqui.
  clue wrote_old_thread
endif
@end

# ---------------------------------------------------------------- Clara (domingo)
@beat clara_sunday
@when at("14:30") and flag("clara_talked")
clara> Domingo, eu sei. Desculpe.
clara> Fui ao arquivo da redação. A Inês ligou para a linha geral três vezes nessa semana. A última no dia 13, às 18:02. Durou onze segundos.
clara> Ninguém lhe devolveu a chamada. Fui eu que fiquei com a mensagem. Li-a no dia 15.
@end

@beat clara_sunday_reply
@when beat("clara_sunday") and read("clara")
wait 1
if flag("read_last_messages")
  choice clara c6_clara
    > Recuperei as últimas mensagens dela. 03:15: "Ele está aqui." | set clara6=shared inc trust_clara 1
    > Ainda não tenho nada que possa mostrar. | set clara6=wait
  end
else
  choice clara c6_clara
    > O que dizia a mensagem? | set clara6=ask
    > Ainda não tenho nada que possa mostrar. | set clara6=wait
  end
endif
wait 30
if vs("clara6") == "shared"
  clara> "Ele."
  wait 5
  clara> Uma mensagem não é prova. Mas é a primeira coisa que ouço em um ano que não é "acidente".
  clara> Guarde tudo. Fora desse telemóvel, se conseguir.
  set clara_saw_msgs=true
elif vs("clara6") == "ask"
  clara> "Clara, é a Inês. Amanhã às dez levo tudo. Se eu não aparecer, não é por ter mudado de ideias."
  wait 6
  clara> Li-a dois dias depois. Já tinha saído a notícia do "acidente". Nunca a apaguei.
  clue clara_voicemail_ines
else
  clara> Eu espero. Já esperei um ano.
endif
@end
