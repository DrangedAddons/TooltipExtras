# Updating the disenchant table

`Disenchant.lua` holds the table of what gear disenchants into, between `-- BEGIN DATA` and
`-- END DATA`. These steps check it against Wowhead Forever's counts and change the rows that are
really off. Not shipped: the release zip leaves out `tools/`.

## 1. Collect (Chrome, Wowhead Forever)

Use Chrome (Claude in Chrome). The in-app browser gets Wowhead's human check after quick page
loads. Load the pages one at a time about 7 seconds apart, and never try to get past a human
check.

Clear the old run first, on any wowhead.com page:

```js
localStorage.removeItem('tteDE')
```

Then for each material, open `https://www.wowhead.com/forever/item=<id>` and run `store.js`:

| Group | Item IDs |
|---|---|
| Dust | 10940 11083 11137 11176 16204 |
| Essences | 10938 10939 10998 11082 11134 11135 11174 11175 16202 16203 |
| Shards | 10978 11084 11138 11139 11177 11178 14343 14344 |
| Crystal | 20725 |

If Forever ever adds disenchant materials, add them here and to the table.

## 2. Report

```bash
python build.py --brackets
```

On a wowhead.com page, run that output (it sets `window.tteBrackets`), then `report.js`. Read
`window.tteReport` back in pieces (`window.tteReport.slice(0, 900)`, `slice(900, 1800)`, ...)
and join them into `forever_counts.json`.

## 3. Compare and update

```bash
python build.py
```

The output lists each table row as `ok`, `DIFFERS` (with both versions) or `kept` with the
reason. Check every `DIFFERS` line that isn't kept. The known traps are listed at the top of
`build.py` (cut-off material lists, blues that disenchant like greens, edge item levels). Then
rewrite only the rows that are real changes:

```bash
python build.py --write "armor 2 26-30" "weapon 3 41-45"
```

## 4. Ship it

Syntax-check `Disenchant.lua`, bump the version, add a CHANGELOG line saying which rows changed,
commit `forever_counts.json` with it and push. Tag when it's time to roll it out.
