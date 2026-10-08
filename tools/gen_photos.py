"""Generates data/photos.json. Photos are scene descriptions rendered by
PhotoView; keeping them in a script makes faces/people consistent."""
import json, os

F = {  # recurring people (face layer params)
 "daniel": {"skin": "#c9a083", "hair": "#2b2018", "style": "short", "cloth": "#2f3a45"},
 "daniel_tired": {"skin": "#bf9a80", "hair": "#2b2018", "style": "short", "cloth": "#1f252c", "smile": False},
 "ines": {"skin": "#e0b597", "hair": "#1c1210", "style": "long", "cloth": "#6b2f3a"},
 "sofia": {"skin": "#d4a98a", "hair": "#4a2a1a", "style": "bun", "cloth": "#3d6b5a"},
 "joao": {"skin": "#b88763", "hair": "#151110", "style": "beard", "cloth": "#2a2a2a"},
 "marta": {"skin": "#e3bfa0", "hair": "#a0522d", "style": "long", "cloth": "#5a3d6b"},
 "pedro": {"skin": "#d9b08f", "hair": "#3a2a1a", "style": "buzz", "cloth": "#3a5a7a"},
 "rui": {"skin": "#a8774f", "hair": "#1a1410", "style": "beard", "cloth": "#3a4a5a", "smile": False},
 "vasco": {"skin": "#d8b496", "hair": "#7d7d7d", "style": "short", "cloth": "#1d2633"},
 "helena": {"skin": "#e8c8b0", "hair": "#cbb68f", "style": "bun", "cloth": "#d8d8d0"},
 "clara": {"skin": "#c49477", "hair": "#111111", "style": "short", "cloth": "#4a3a2a", "smile": False},
 "mae": {"skin": "#d9b59a", "hair": "#9a9a9a", "style": "bun", "cloth": "#6b4a5a"},
}
def face(who, x, y, r=0.1, **kw):
    d = {"t": "face", "p": [x, y], "r": r}
    d.update(F[who]); d.update(kw); return d

P = {}
def photo(pid, date, scene, place="", device="Lumen One", album="Câmara", aspect=0.75, **kw):
    d = {"file": pid + ".jpg", "date": date, "place": place, "device": device, "album": album, "aspect": aspect, "scene": scene}
    d.update(kw); P[pid] = d

# ---------------------------------------------------------------- daily life (initial)
photo("IMG_2207", "2026-09-27 19:41", {"preset": "sunset", "variants": {
    "watcher": {"add": [{"t": "figure", "p": [0.71, 0.66], "h": 0.06, "c": "#0a0608", "n": "watcher"}]}}},
    place="Praia da Salgueira", aspect=0.75,
    hotspots=[{"r": [0.66, 0.58, 0.1, 0.1], "zoom": 2.0, "variant": "watcher", "clue": "wallpaper_watcher", "label": "Há alguém na água. Isto não estava aqui."}])
photo("IMG_2190", "2026-09-19 11:02", {"preset": "cat"}, place="Livraria Maré, Rua Direita 31", aspect=1.0)
photo("IMG_2155", "2026-08-29 21:15", {"preset": "food", "food": "#c98a3a"}, place="O Farol, Largo do Cais 4", aspect=1.0)
photo("IMG_2101", "2026-08-29 23:52", {"preset": "group", "bg": "bar", "faces": [
    face("joao", 0.2, 0.55, 0.11), face("marta", 0.42, 0.52, 0.1), face("pedro", 0.62, 0.55, 0.1), face("daniel", 0.82, 0.58, 0.1)]},
    place="O Farol, Largo do Cais 4", aspect=1.33)
photo("IMG_2044", "2026-07-16 18:30", {"preset": "bookshop", "seed": 21, "layers": [
    {"t": "rect", "r": [0.535, 0.405, 0.03, 0.135], "c": "#2e4a7a", "n": "saramago"},
    {"t": "rect", "r": [0.538, 0.45, 0.024, 0.008], "c": "#d9c9a0"},
    {"t": "text", "p": [0.06, 0.95], "s": 0.03, "c": "#c9b28a", "v": "LITERATURA PORTUGUESA", "a": 0.8}]},
    place="Livraria Maré, Rua Direita 31", aspect=0.75,
    hotspots=[{"r": [0.52, 0.39, 0.06, 0.16], "zoom": 2.0, "clue": "saramago_spine", "label": "\"O Ano da Morte de Ricardo Reis\". A lombada está inchada, como se houvesse algo lá dentro."}])
photo("IMG_1980", "2026-07-05 16:20", {"preset": "portrait", "bg": "beach", "faces": [
    face("sofia", 0.35, 0.55, 0.15), face("daniel", 0.66, 0.58, 0.15)]}, place="Praia da Salgueira", aspect=1.0)
photo("IMG_1702", "2026-03-11 17:48", {"preset": "document", "title": "CLÍNICA ATLÂNTICO", "seed": 8,
    "text": ["Utente: Daniel Reis", "Clonazepam 0,5 mg", "1 comp. ao deitar se necessário", "Dra. Helena Sousa"], "stamp": ""},
    place="Faro", aspect=0.75, hotspots=[{"r": [0.1, 0.1, 0.8, 0.3], "clue": "prescription", "label": "A receita da Dra. Helena."}])
photo("IMG_1650", "2026-02-15 15:05", {"preset": "food", "food": "#5a2a1a"}, place="Tavira", aspect=1.0)
photo("IMG_1433", "2026-01-14 08:12", {"preset": "pier_day", "layers": [
    {"t": "circle", "p": [0.505, 0.47], "r": 0.012, "c": "#c94a5a", "n": "flowers"},
    {"t": "circle", "p": [0.512, 0.475], "r": 0.009, "c": "#e8d24a"}]}, place="Cais Velho, Salgueira", aspect=0.75,
    hotspots=[{"r": [0.47, 0.43, 0.08, 0.08], "zoom": 2.0, "clue": "pier_flowers", "label": "Flores atadas ao poste. Alguém deixou flores no cais."}])
photo("IMG_1288", "2025-12-20 01:33", {"preset": "street_night", "rain": True, "seed": 4, "layers": [
    {"t": "rect", "r": [0.03, 0.585, 0.26, 0.035], "c": "#1c140e"},
    {"t": "text", "p": [0.045, 0.61], "s": 0.017, "c": "#a8865a", "v": "LIVRARIA MARÉ · 31", "a": 0.75},
    {"t": "rect", "r": [0.2, 0.625, 0.05, 0.03], "c": "#2a2418"},
    {"t": "glow", "p": [0.225, 0.64], "r": 0.03, "c": "#ffcf8a22"}]},
    place="Rua Direita, Salgueira", aspect=0.75,
    hotspots=[{"r": [0.0, 0.56, 0.33, 0.1], "clue": "december_bookshop", "label": "\"Livraria Maré · 31\". 20 de dezembro, 01:33. Estavas à porta da livraria, à chuva, dois meses depois."}])
photo("IMG_0901", "2025-11-21 03:40", {"preset": "portrait", "bg": "#121418", "faces": [face("daniel_tired", 0.5, 0.48, 0.2)],
    "layers": [{"t": "rect", "r": [0.07, 0.1, 0.13, 0.09], "c": "#8a8472", "a": 0.55},
               {"t": "text", "p": [0.085, 0.14], "s": 0.022, "c": "#1a1a1a", "v": "14/10", "a": 0.7},
               {"t": "text", "p": [0.085, 0.172], "s": 0.022, "c": "#5a1010", "v": "03:17", "a": 0.7}]},
    place="Rua das Gaivotas 12, Salgueira", aspect=0.75,
    hotspots=[{"r": [0.05, 0.08, 0.17, 0.13], "clue": "wall_note_0317", "label": "Um papel na parede atrás de ti: \"14/10 — 03:17\". Já em novembro sabias a hora."}])
photo("IMG_0899", "2025-11-03 17:02", {"preset": "office", "layers": [
    {"t": "rect", "r": [0.36, 0.56, 0.22, 0.12], "c": "#a07a4a"}, {"t": "text", "p": [0.38, 0.63], "s": 0.025, "c": "#3a2a1a", "v": "D. REIS"},
    {"t": "rect", "r": [0.5, 0.565, 0.04, 0.03], "c": "#e8d84a"}]},
    place="Lumen Systems, Faro", aspect=1.33,
    hotspots=[{"r": [0.34, 0.54, 0.26, 0.16], "zoom": 2.0, "clue": "daniel_postit", "label": "Na tampa da caixa, um post-it com a tua letra: \"NÃO testar o espelho com dados reais. Falar com a I.\""}])

# ---------------------------------------------------------------- recovered (cloud backup, ch06)
photo("IMG_3010", "2025-03-21 13:22", {"preset": "portrait", "bg": "#5a4a3a", "faces": [face("ines", 0.33, 0.55, 0.14), face("daniel", 0.67, 0.57, 0.14)]},
    place="Tasca do Zé, Faro", album="Recuperadas", aspect=1.0, device="Pixel 7 (antigo)")
photo("IMG_3102", "2025-04-30 16:10", {"preset": "portrait", "bg": "#dfe3e6", "faces": [face("ines", 0.5, 0.5, 0.2)]},
    place="Lumen Systems, Faro", album="Recuperadas", aspect=0.75, device="Pixel 7 (antigo)")
photo("IMG_3240", "2025-09-14 23:31", {"preset": "group", "bg": "bar", "faces": [
    face("rui", 0.17, 0.56, 0.1), face("ines", 0.38, 0.52, 0.11), face("daniel", 0.6, 0.55, 0.1), face("joao", 0.82, 0.57, 0.1)]},
    place="O Farol, Largo do Cais 4", album="Recuperadas", aspect=1.33, device="Pixel 7 (antigo)",
    hotspots=[{"r": [0.7, 0.4, 0.24, 0.35], "clue": "joao_knew_ines", "label": "O João está na fotografia. Ele conhecia-a."},
              {"r": [0.05, 0.4, 0.24, 0.35], "clue": "rui_at_party", "label": "O Rui também lá estava."}])
photo("IMG_3301", "2025-09-28 19:12", {"preset": "portrait", "bg": "beach", "faces": [face("ines", 0.38, 0.56, 0.15, closed=True), face("daniel", 0.64, 0.58, 0.15)]},
    place="Cais Velho, Salgueira", album="Recuperadas", aspect=1.0, device="Pixel 7 (antigo)", pair="IMG_3302")
photo("IMG_3302", "2025-09-28 19:12", {"preset": "portrait", "bg": "beach", "faces": [face("ines", 0.38, 0.56, 0.15), face("daniel", 0.64, 0.58, 0.15)],
    "layers": [{"t": "figure", "p": [0.9, 0.44], "h": 0.07, "c": "#14100e", "a": 0.85}]},
    place="Cais Velho, Salgueira", album="Recuperadas", aspect=1.0, device="Pixel 7 (antigo)", pair="IMG_3301",
    hotspots=[{"r": [0.85, 0.34, 0.1, 0.12], "zoom": 1.8, "clue": "pier_watcher_2025", "label": "Ao fundo, de pé dentro de água, alguém a olhar para vocês. Na fotografia anterior — tirada no mesmo segundo — não está lá ninguém."}])
photo("IMG_3366", "2025-10-02 22:47", {"preset": "document", "title": "LUMEN SYSTEMS · CONFIDENCIAL", "seed": 33,
    "text": ["Acordo de partilha de dados", "Clínica Atlântico, Lda.", "Objeto: dados de 3.412 utentes", "Finalidade: treino do modelo ECO", "Assinado: V. Pimentel"], "stamp": "CONFIDENCIAL"},
    place="Lumen Systems, Faro", album="Recuperadas", aspect=0.75, device="Pixel 7 (antigo)",
    hotspots=[{"r": [0.1, 0.18, 0.8, 0.3], "clue": "clinic_contract", "label": "Um contrato. Dados de 3.412 utentes da clínica — para treinar o ECO."}])
photo("IMG_3398", "2025-10-14 04:13", {"preset": "bookshop", "seed": 21, "grain": 0.22, "layers": [
    {"t": "tint", "c": "#000000", "a": 0.72}, {"t": "rect", "r": [0.535, 0.405, 0.03, 0.135], "c": "#2e4a7a"},
    {"t": "glow", "p": [0.55, 0.47], "r": 0.25, "c": "#bcd0ff30"},
    {"t": "figure", "p": [0.72, 1.2], "h": 0.95, "c": "#020203", "pose": "phone", "a": 0.9}]},
    place="Rua Direita 31, Salgueira", album="Recuperadas", aspect=0.75, device="Pixel 7 (antigo)",
    hotspots=[{"r": [0.5, 0.38, 0.1, 0.2], "zoom": 1.5, "clue": "night_bookshop", "label": "A estante da literatura portuguesa. Às 04:13. Na noite em que ela morreu."}])

# ---------------------------------------------------------------- story photos
photo("IMG_6612", "2026-10-08 23:44", {"preset": "window_outside", "grain": 0.12}, place="Rua das Gaivotas 12, Salgueira", device="desconhecido",
    album="Mensagens", aspect=0.75,
    meta_variants={"later": {"device": "Lumen One", "origin": "Câmara deste dispositivo"}},
    meta_clues=["photo_window_meta"],
    hotspots=[{"r": [0.28, 0.3, 0.44, 0.3], "clue": "photo_window", "label": "És tu. No sofá. Há três minutos."}])
photo("IMG_6630", "2026-10-09 03:02", {"preset": "door", "gap": 0.07, "grain": 0.16,
    "variants": {"eye": {"add": [{"t": "circle", "p": [0.335, 0.47], "r": 0.006, "c": "#d8d4c8", "a": 0.7}]}}},
    place="Rua das Gaivotas 12, Salgueira", device="desconhecido", album="Mensagens", aspect=0.75,
    hotspots=[{"r": [0.3, 0.1, 0.08, 0.8], "zoom": 2.0, "clue": "door_from_inside", "label": "A porta do teu quarto. Fotografada de dentro. Às 03:02."}])
photo("IMG_6641", "2026-10-09 21:58", {"preset": "street_night", "seed": 9, "figs": [[0.31, 0.62, 0.17, "stand", "watcher"]],
    "variants": {"gone": {"remove": ["watcher"]}}}, place="Rua das Gaivotas, Salgueira", device="desconhecido", album="Mensagens", aspect=0.75,
    hotspots=[{"r": [0.26, 0.42, 0.1, 0.22], "zoom": 1.5, "variant": "base", "clue": "street_watcher", "label": "Alguém debaixo do candeeiro. A olhar para a tua janela."}])
photo("IMG_0317", "2026-10-14 03:17", {"preset": "pier_night", "figs": [[0.47, 0.52, 0.06, "stand", "fig"]],
    "variants": {
      "closer": {"remove": ["fig"], "add": [{"t": "figure", "p": [0.45, 0.68], "h": 0.16, "c": "#030304", "n": "fig"}]},
      "two": {"add": [{"t": "figure", "p": [0.56, 0.6], "h": 0.11, "c": "#030304"}]},
      "empty": {"remove": ["fig"]}}},
    place="Cais Velho, Salgueira", device="desconhecido", album="Mensagens", aspect=0.75,
    meta_clues=["future_photo"],
    hotspots=[{"r": [0.42, 0.44, 0.1, 0.12], "zoom": 2.0, "clue": "pier_figure", "label": "Uma pessoa no fim do cais. De costas para ti. Ou de frente?"}])
photo("IMG_BACK", "2026-10-11 01:12", {"preset": "back", "grain": 0.14}, place="Rua das Gaivotas 12, Salgueira", device="Lumen One", album="Câmara", aspect=0.75,
    hotspots=[{"r": [0.5, 0.55, 0.15, 0.2], "clue": "photo_from_behind", "label": "O ecrã do telemóvel, por cima do teu ombro. Nada podia estar ali para tirar esta fotografia."}])
photo("IMG_6700", "2026-10-11 02:47", {"preset": "black", "grain": 0.25, "figs": [[0.62, 0.95, 0.85, "stand", "f", 0.08, "#ffffff"]]},
    place="Rua das Gaivotas 12, Salgueira", device="Lumen One", album="Câmara", aspect=0.75,
    hotspots=[{"r": [0.45, 0.1, 0.35, 0.85], "zoom": 1.5, "clue": "black_photo_figure", "label": "Não está totalmente escura. Há uma forma."}])
photo("IMG_6720", "2026-10-12 04:02", {"preset": "bedroom", "grain": 0.2, "layers": [
    {"t": "ellipse", "p": [0.4, 0.58], "rx": 0.16, "ry": 0.05, "c": "#2a2b30"},
    {"t": "ellipse", "p": [0.22, 0.55], "rx": 0.05, "ry": 0.04, "c": "#3a2f2a"}]},
    place="Rua das Gaivotas 12, Salgueira", device="desconhecido", album="Câmara", aspect=1.33,
    hotspots=[{"r": [0.1, 0.45, 0.5, 0.2], "clue": "sleeping_photo", "label": "Tu, a dormir. Fotografado da porta."}])
photo("IMG_5530", "2025-10-14 03:04", {"preset": "cctv", "plate": "AX-31-PL", "stamp": "CAM 02  14-10-2025  03:04:51"},
    place="Bombas Galp, EN125 — saída Cais Velho", device="Hikvision DS-2CD", album="Transferências", aspect=1.33,
    hotspots=[{"r": [0.4, 0.55, 0.32, 0.18], "zoom": 1.5, "clue": "vasco_car_cctv", "label": "Um Audi cinzento. Matrícula AX-31-PL. A caminho do cais às 03:04."}])
photo("IMG_6800", "2026-10-12 11:30", {"preset": "screen", "lines": [">Vasco, ela vai ter com uma", ">jornalista amanhã.", ">Fala com ela antes.", ">Está no Cais Velho às 2h30.", ">Não lhe digas que fui eu.", "Obrigado, Daniel. Eu trato."]},
    place="", device="Lumen One · captura de ecrã", album="Capturas", aspect=0.75,
    hotspots=[{"r": [0.0, 0.0, 1.0, 0.5], "clue": "daniel_told_vasco", "label": "Foste tu. Foste tu que lhe disseste onde ela estava."}])

photo("IMG_INES_LAST", "2025-10-14 03:05", {"preset": "pier_night", "grain": 0.12, "layers": [
        {"t": "glow", "p": [0.46, 0.7], "r": 0.28, "c": "#ffcf8a22"},
        {"t": "figure", "p": [0.46, 0.84], "h": 0.3, "c": "#3a3029"},
        {"t": "glow", "p": [0.46, 0.6], "r": 0.06, "c": "#ffdca822"}]},
    place="Cais Velho, Salgueira", device="Pixel 8 (I.M.)", album="Transferências", aspect=0.75, file="IMG_20251014_030540.jpg",
    hotspots=[{"r": [0.35, 0.5, 0.18, 0.38], "clue": "ines_last_photo", "label": "Tu. De costas. A ir-te embora pelo cais. A última fotografia que ela tirou."}])
photo("IMG_RUI_DESK", "2026-10-11 17:20", {"preset": "custom", "layers": [
        {"t": "grad", "c": ["#4a3524", "#2e2016"]},
        {"t": "rect", "r": [0.18, 0.3, 0.42, 0.5], "c": "#2e4a7a"},
        {"t": "rect", "r": [0.2, 0.32, 0.38, 0.46], "c": "#34548a"},
        {"t": "text", "p": [0.22, 0.42], "s": 0.032, "c": "#e8e0c8", "v": "O ANO DA MORTE"},
        {"t": "text", "p": [0.22, 0.47], "s": 0.032, "c": "#e8e0c8", "v": "DE RICARDO REIS"},
        {"t": "text", "p": [0.22, 0.72], "s": 0.022, "c": "#c8c0a8", "v": "José Saramago"},
        {"t": "rect", "r": [0.58, 0.22, 0.24, 0.2], "c": "#e8d84a"},
        {"t": "text", "p": [0.6, 0.3], "s": 0.032, "c": "#3a3010", "v": "D. — p. 317"},
        {"t": "text", "p": [0.6, 0.36], "s": 0.024, "c": "#3a3010", "v": "(a de cima)"},
        {"t": "ellipse", "p": [0.78, 0.8], "rx": 0.08, "ry": 0.05, "c": "#c94a5a"},
        {"t": "glow", "p": [0.3, 0.1], "r": 0.6, "c": "#ffe0b012"}]},
    place="Rua do Mar 7, Salgueira", device="Galaxy A14 (Rui)", album="Mensagens", aspect=1.0,
    hotspots=[{"r": [0.56, 0.2, 0.28, 0.24], "clue": "postit_p317", "label": "Um post-it com a letra dela: \"D. — p. 317 (a de cima)\"."}])
def _cal_layers():
    # October 2025 wall calendar (weeks start on Monday; the 1st is a Wednesday)
    x0, y0, w, h = 0.06, 0.24, 0.88 / 7, 0.13
    L = [{"t": "grad", "c": ["#d8d2c4", "#bdb6a6"]},
         {"t": "text", "p": [0.08, 0.1], "s": 0.05, "c": "#2a2a2a", "v": "OUTUBRO 2025"},
         {"t": "rect", "r": [0.06, 0.17, 0.88, 0.005], "c": "#a02020"}]
    for i, d in enumerate("STQQSSD"):
        L.append({"t": "text", "p": [x0 + i * w + 0.01, 0.215], "s": 0.022, "c": "#6a6458", "v": d})
    for r in range(6):
        L.append({"t": "line", "pts": [x0, y0 + r * h, x0 + 7 * w, y0 + r * h], "c": "#9a9488", "w": 0.002})
    for c in range(8):
        L.append({"t": "line", "pts": [x0 + c * w, y0, x0 + c * w, y0 + 5 * h], "c": "#9a9488", "w": 0.002})
    for day in range(1, 32):
        idx = day + 1
        r, c = divmod(idx, 7)
        L.append({"t": "text", "p": [x0 + c * w + 0.01, y0 + r * h + 0.035], "s": 0.026,
                  "c": "#a02020" if c == 6 else "#2a2a2a", "v": str(day)})
    # her handwriting
    L += [{"t": "circle", "p": [x0 + 1.5 * w, y0 + 2.5 * h], "r": 0.055, "c": "#c0303040"},
          {"t": "text", "p": [x0 + 1 * w + 0.008, y0 + 2 * h + 0.095], "s": 0.02, "c": "#a02020", "v": "Clara 10h!"},
          {"t": "text", "p": [x0 + 0.008, y0 + 2 * h + 0.095], "s": 0.019, "c": "#2a3a8a", "v": "cais 2h30"},
          {"t": "text", "p": [x0 + 0.03, y0 + 2 * h + 0.118], "s": 0.019, "c": "#2a3a8a", "v": "(D.)"},
          {"t": "text", "p": [x0 + 4 * w + 0.008, y0 + 0 * h + 0.095], "s": 0.019, "c": "#2a3a8a", "v": "jantar mãe"},
          {"t": "text", "p": [x0 + 1 * w + 0.008, y0 + 4 * h + 0.095], "s": 0.019, "c": "#2a3a8a", "v": "1 ano :)"}]
    return L


photo("IMG_RUI_CAL", "2026-10-11 17:21", {"preset": "custom", "layers": _cal_layers()},
    place="Rua do Mar 7, Salgueira", device="Galaxy A14 (Rui)", album="Mensagens", aspect=1.0,
    hotspots=[{"r": [0.06, 0.24 + 2 * 0.13, 2 * 0.88 / 7, 0.13], "clue": "ines_calendar", "label": "13: \"cais 2h30 (D.)\". 14: \"Clara 10h!\". Ela tinha tudo planeado."}])
photo("IMG_RITA", "2026-10-13 00:29", {"preset": "screen", "lines": ["/.eco", "sim_112.log", "mirror_pai.cfg", "pred_rsantos.txt", "sujeita: R.SANTOS", "espelho: pai (J.SANTOS)"]},
    place="", device="Lumen One · captura de ecrã", album="Mensagens", aspect=0.75)

# ---------------------------------------------------------------- web images
photo("IMG_4410", "2025-06-02 12:00", {"preset": "portrait", "bg": "#3a4a5a", "faces": [face("ines", 0.5, 0.48, 0.22)]}, album="Web", aspect=0.75)
photo("IMG_4415", "2025-10-14 09:30", {"preset": "pier_day", "layers": [
    {"t": "line", "pts": [0.2, 0.8, 0.8, 0.75], "c": "#e8d24a", "w": 0.008}, {"t": "line", "pts": [0.25, 0.83, 0.75, 0.79], "c": "#202020", "w": 0.004},
    {"t": "figure", "p": [0.3, 0.9], "h": 0.3, "c": "#1a2a4a"}, {"t": "figure", "p": [0.7, 0.88], "h": 0.28, "c": "#1a2a4a"}]}, album="Web", aspect=1.33)
photo("IMG_4420", "2024-05-10 10:00", {"preset": "office"}, album="Web", aspect=1.33)
photo("IMG_4430", "2025-01-10 10:00", {"preset": "portrait", "bg": "#2a3a4a", "faces": [face("vasco", 0.5, 0.48, 0.22)]}, album="Web", aspect=0.75)
photo("IMG_4431", "2024-09-10 10:00", {"preset": "portrait", "bg": "#cfd8d4", "faces": [face("helena", 0.5, 0.48, 0.22)]}, album="Web", aspect=0.75)
photo("IMG_4440", "2025-03-10 10:00", {"preset": "portrait", "bg": "#4a3a3a", "faces": [face("clara", 0.5, 0.48, 0.22)]}, album="Web", aspect=0.75)
photo("IMG_4450", "2025-10-20 02:11", {"preset": "pier_night", "grain": 0.2, "layers": [
    {"t": "glow", "p": [0.48, 0.55], "r": 0.08, "c": "#ffffff40"}, {"t": "glow", "p": [0.52, 0.56], "r": 0.04, "c": "#ff404040"}]},
    album="Web", aspect=1.33, place="Cais Velho, Salgueira")
photo("IMG_4460", "2025-10-15 08:00", {"preset": "portrait", "bg": "#3a3a2a", "faces": [face("rui", 0.5, 0.5, 0.22)]}, album="Web", aspect=0.75)

# ---------------------------------------------------------------- camera scenes
P["CAM_VIEW"] = {"file": "", "aspect": 0.75, "album": "", "scene": {"preset": "room_night", "grain": 0.12,
    "variants": {
      "hall_figure": {"add": [{"t": "figure", "p": [0.945, 0.78], "h": 0.6, "c": "#020203", "n": "hall"}]},
      "window_face": {"add": [{"t": "face", "p": [0.66, 0.3], "r": 0.05, "skin": "#3a3a40", "hair": "#050505", "style": "long", "cloth": "#050505", "smile": False}]},
      "close": {"add": [{"t": "figure", "p": [0.7, 1.15], "h": 1.0, "c": "#020202"}]}}},
    "events": {
      "hall": {"delay": 2.6, "variant": "hall_figure", "hold": 1.3, "sound": ""},
      "window": {"delay": 4.0, "variant": "window_face", "hold": 0.9, "sound": "knock_one"},
      "close": {"delay": 1.2, "variant": "close", "hold": 0.6, "sound": "breath"}}}
P["CAM_FRONT"] = {"file": "", "aspect": 0.75, "album": "", "scene": {"preset": "portrait", "grain": 0.2, "vignette": 0.95,
    "bg": "#07080a", "faces": [face("daniel_tired", 0.5, 0.55, 0.24, skin="#6e6560", hair="#120d0a", cloth="#101317"),
        {"t": "tint", "c": "#0b1a3a", "a": 0.38},
        {"t": "glow", "p": [0.5, 1.0], "r": 0.6, "c": "#a8c4ff20"}],
    "variants": {"behind": {"add": [{"t": "figure", "p": [0.18, 1.05], "h": 0.95, "c": "#030303"}]}}},
    "events": {"behind": {"front": True, "delay": 3.0, "variant": "behind", "hold": 1.0, "sound": "breath"}}}

out = os.path.join(os.path.dirname(__file__), "..", "data", "photos.json")
json.dump(P, open(out, "w"), ensure_ascii=False, indent=1)
print(len(P), "photos")
