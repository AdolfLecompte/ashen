# Picks the artwork of the result that IS the track asked for.
#
# iTunes' first hit for "The Dreamer Piano in the sea" is Frank Ocean's "blond":
# the old lookup asked for limit=1 and believed it, which is how one song showed
# two different covers on two surfaces. A cover that belongs to another record
# is worse than no cover, so a result has to earn it: same title, and an artist
# that is recognisably the same.
import json, sys, unicodedata, re

def norm(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode()
    s = s.lower()
    s = re.sub(r"\((?:feat|ft|with|prod)[^)]*\)", " ", s)   # featurings are noise
    s = re.sub(r"\[[^\]]*\]", " ", s)
    s = re.sub(r"\b(remaster(ed)?|slowed|reverb|sped up|live|radio edit|version)\b", " ", s)
    s = re.sub(r"[^a-z0-9]+", " ", s)
    return " ".join(s.split())

want_artist, want_title = norm(sys.argv[1]), norm(sys.argv[2])
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not want_title:
    sys.exit(0)

for r in data.get("results", []):
    t, a = norm(r.get("trackName")), norm(r.get("artistName"))
    title_ok = t == want_title or (len(want_title) > 6 and want_title in t) \
               or (len(t) > 6 and t in want_title)
    # The artist is what stops a same-titled cover from another record: one
    # side containing the other is enough (uploads say "Artist - Topic"), but
    # nothing at all is not.
    artist_ok = bool(want_artist) and (a == want_artist or want_artist in a or a in want_artist)
    if title_ok and artist_ok:
        u = r.get("artworkUrl100") or ""
        if u:
            print(u.replace("100x100bb", "600x600bb"))
            break
