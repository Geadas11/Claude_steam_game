"""Lists variables read by story conditions that are never written anywhere.
Dynamic prefixes written by code (meta_<photo>, cam_<event>_seen, ...) are allowed."""
import re, glob, json
story = {f: open(f).read() for f in glob.glob('data/chapters/*.story')}
code = "".join(open(f).read() for f in glob.glob('scripts/**/*.gd', recursive=True))
data = "".join(open(f).read() for f in glob.glob('data/*.json'))
read = set()
for txt in list(story.values()) + [data]:
    for m in re.finditer(r'\b(?:flag|v|vs)\("([\w]+)"\)', txt):
        read.add(m.group(1))
written = set()
for txt in story.values():
    for m in re.finditer(r'^\s*set (.+)$', txt, re.M):
        for tok in m.group(1).split():
            written.add(tok.split('=')[0])
    for m in re.finditer(r'^\s*inc (\w+)', txt, re.M):
        written.add(m.group(1))
    for m in re.finditer(r'\|\s*(.+)$', txt, re.M):
        toks = m.group(1).split()
        i = 0
        while i < len(toks):
            t = toks[i]
            if t == 'inc' and i + 1 < len(toks):
                written.add(toks[i + 1]); i += 2; continue
            if t != 'set':
                written.add(t.split('=')[0])
            i += 1
for m in re.finditer(r'(?:set_var|inc_var)\("([\w]+)"', code):
    written.add(m.group(1))
prefixes = ["call_", "meta_", "unlocked_page_", "unlocked_note_", "extracted_", "heard_", "cam_", "viewed_loc_",
            "opened_hidden_", "compared_", "read_note_", "photographed_", "pw_fail_", "dialed_", "settings_",
            "viewed_contact_", "clicked_injected_", "choice_", "hungup_", "prev_end_", "_called_"]
missing = sorted(r for r in read if r not in written and not any(r.startswith(p) for p in prefixes))
print("flag audit: read but never written:", missing if missing else "none")
raise SystemExit(1 if missing else 0)
