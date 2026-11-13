"""Checks the disenchant table in Disenchant.lua against Wowhead Forever counts and updates it.

  python build.py --brackets   print the table's item-level groups as JSON, for report.js
  python build.py              compare forever_counts.json with the table; changes nothing
  python build.py --write "armor 2 16-20" ["weapon 3 41-45" ...]
                               rewrite those rows with Forever's numbers

Rows are only rewritten when named, after checking the report: Wowhead's counts have known
traps (below), so a difference isn't always a real change in the game.

See README.md in this folder for the whole update.
"""
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
LUA = HERE.parent.parent / "Disenchant.lua"
COUNTS = HERE / "forever_counts.json"

# A group's counts are only trusted with at least this many disenchants from this many items.
MIN_DE, MIN_ITEMS = 300, 5
# Rewrite a row when a material's chance is off by more than this many points, or its quantity
# range differs.
MAX_DRIFT = 3.0
# Materials under this chance (%) or quantities under this share (%) are noise.
MIN_CHANCE, MIN_QTY_SHARE = 0.4, 2.0

# A material page lists a limited number of items (about 200 seen). Items missing from a cut-off
# list fail report.js's "materials add up" check unless that material is a small share for them,
# so a cut-off material reads low or missing. Lists this short may be cut off.
SHORT_LIST = 215

# Known traps, from the 2026-11-14 check (no rows changed then):
# - Blues that give dust or essences: a few items Wowhead lists as blue disenchant like greens.
#   Every blue group shows some; the original game's blues give only shards (plus rare Nexus).
# - Green 51-65 with few or no Large/Small Brilliant Shards: those shard lists are cut off.
# - Groups at 16-20 picking up the 5-15 results: edge items; small samples.
# "kind quality low-high": reason the table keeps its row
KEEP = {
    "armor 3 11-25": "Wowhead blues that disenchant like greens",
    "weapon 3 11-25": "Wowhead blues that disenchant like greens",
    "armor 3 31-35": "Wowhead blues that disenchant like greens",
    "armor 3 36-40": "Wowhead blues that disenchant like greens",
    "armor 3 41-45": "Wowhead blues that disenchant like greens",
    "weapon 3 41-45": "Wowhead blues that disenchant like greens",
    "armor 3 56-99": "Wowhead blues that disenchant like greens",
    "armor 2 16-20": "edge items with 5-15 results; small sample",
    "weapon 2 16-20": "edge items with 5-15 results; small sample",
    "armor 2 21-25": "edge items with 16-20 dust counts (2-3 Strange Dust, under 10%)",
    "weapon 2 21-25": "edge items with 16-20 dust counts (2-3 Strange Dust, under 10%)",
}


def short(counts, mats_old, mats_new):
    """Materials in the table that read lower in Forever's counts and whose list may be cut off."""
    lists = counts.get("lists", {})
    new = {m[0]: m[1] for m in mats_new}
    return [str(m[0]) for m in mats_old
            if new.get(m[0], 0) < m[1] - MAX_DRIFT and lists.get(str(m[0]), 0) <= SHORT_LIST]

ROW = re.compile(r"^(\s*)\{ (\d+), (\d+), (.*) \},\s*$")
MAT = re.compile(r"\{ (\d+), ([\d.]+), (\d+), (\d+), ([\d.]+) \}")


def read_table():
    """Returns (lines, rows): every line between the DATA markers, and for each row line
    {index, kind, quality, lo, hi, mats: [[id, pct, min, max, avg], ...]}."""
    text = LUA.read_text(encoding="utf-8")
    start = text.index("-- BEGIN DATA\n") + len("-- BEGIN DATA\n")
    end = text.index("-- END DATA", start)
    lines = text[start:end].splitlines()
    rows, kind, quality = [], None, None
    for i, line in enumerate(lines):
        m = re.match(r"^\s*(armor|weapon) = \{", line)
        if m:
            kind = m.group(1)
            continue
        m = re.match(r"^\s*\[(\d)\] = \{", line)
        if m:
            quality = int(m.group(1))
            continue
        m = ROW.match(line)
        if m:
            mats = [[int(a), float(b), int(c), int(d), float(e)] for a, b, c, d, e in MAT.findall(m.group(4))]
            rows.append(dict(index=i, indent=m.group(1), kind=kind, quality=quality,
                             lo=int(m.group(2)), hi=int(m.group(3)), mats=mats))
    return text, start, end, lines, rows


def num(x):
    return ("%.2f" % x).rstrip("0").rstrip(".")


def row_line(r):
    mats = ", ".join("{ %d, %s, %d, %d, %s }" % (m[0], num(m[1]), m[2], m[3], num(m[4])) for m in r["mats"])
    return "%s{ %d, %d, %s }," % (r["indent"], r["lo"], r["hi"], mats)


def from_counts(group):
    """Forever's version of a row's materials from one forever_counts.json group."""
    mats = []
    for mat, (count, qty) in group["mats"].items():
        pct = 100.0 * count / group["de"]
        if pct < MIN_CHANCE:
            continue
        shares = {int(q): s for q, s in qty.items() if s >= MIN_QTY_SHARE}
        if not shares:
            continue
        total = sum(shares.values())
        avg = sum(q * s for q, s in shares.items()) / total
        mats.append([int(mat), round(pct * 2) / 2, min(shares), max(shares), round(avg * 4) / 4])
    mats.sort(key=lambda m: -m[1])
    return mats


def compare(old, new):
    """Biggest chance difference in points, and whether any quantity range differs."""
    a = {m[0]: m for m in old}
    b = {m[0]: m for m in new}
    drift, qty = 0.0, False
    for mat in set(a) | set(b):
        pa = a[mat][1] if mat in a else 0.0
        pb = b[mat][1] if mat in b else 0.0
        drift = max(drift, abs(pa - pb))
        if mat in a and mat in b and (a[mat][2], a[mat][3]) != (b[mat][2], b[mat][3]):
            qty = True
    return drift, qty


def show(mats):
    return ", ".join("%s %s%% x%s" % (m[0], num(m[1]), m[2] if m[2] == m[3] else "%d-%d" % (m[2], m[3]))
                     for m in mats)


def main():
    text, start, end, lines, rows = read_table()
    if "--brackets" in sys.argv:
        out = {}
        for r in rows:
            out.setdefault(r["kind"], {}).setdefault(str(r["quality"]), []).append([r["lo"], r["hi"]])
        print("window.tteBrackets = " + json.dumps(out, separators=(",", ":")) + ";")
        return
    counts = json.loads(COUNTS.read_text(encoding="utf-8"))
    groups = counts["groups"]
    print("Forever counts from %s: %d materials, %d items\n"
          % (counts.get("collected", "?"), counts["materials"], counts["items"]))
    targets = set(sys.argv[sys.argv.index("--write") + 1:]) if "--write" in sys.argv else set()
    names = set()
    changed = 0
    seen = set()
    for r in rows:
        key = "%d-%d" % (r["lo"], r["hi"])
        name = "%s %d %s" % (r["kind"], r["quality"], key)
        names.add(name)
        g = groups.get(r["kind"], {}).get(str(r["quality"]), {}).get(key)
        seen.add((r["kind"], str(r["quality"]), key))
        if not g:
            print("%-16s no Forever data, kept" % name)
            continue
        new = from_counts(g)
        drift, qty = compare(r["mats"], new)
        solid = g["de"] >= MIN_DE and g["n"] >= MIN_ITEMS
        if drift <= MAX_DRIFT and not qty:
            print("%-16s ok (off by %.1f, %d items, %d disenchants)" % (name, drift, g["n"], g["de"]))
            continue
        cut = short(counts, r["mats"], new)
        why = KEEP.get(name) or (None if solid else "only %d items, %d disenchants" % (g["n"], g["de"]))
        if not why and cut:
            why = "list of " + ", ".join(cut) + " may be cut off"
        print("%-16s DIFFERS by %.1f%s%s" % (name, drift, " and quantities" if qty else "",
                                           ", kept: " + why if why else ""))
        print("    table:   " + show(r["mats"]))
        print("    Forever: " + show(new))
        if name in targets:
            if why:
                print("    rewriting anyway, as asked")
            r["mats"] = new
            lines[r["index"]] = row_line(r)
            changed += 1
    for kind, qs in groups.items():
        for q, ks in qs.items():
            for key, g in ks.items():
                if (kind, q, key) not in seen:
                    print("%s %s %s: Forever has %d items (%d disenchants) the table has no row for"
                          % (kind, q, key, g["n"], g["de"]))
    if changed:
        LUA.write_text(text[:start] + "\n".join(lines) + "\n" + text[end:], encoding="utf-8", newline="")
        print("\nRewrote %d rows in %s" % (changed, LUA.name))
    elif "--write" in sys.argv:
        print("\nNothing rewritten")
    for t in sorted(targets - names):
        print("No table row called %r" % t)


if __name__ == "__main__":
    main()
