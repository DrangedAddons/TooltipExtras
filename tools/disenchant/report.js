// Run on any wowhead.com page after store.js has run on every material page.
// Set window.tteBrackets first to the output of `python build.py --brackets`.
// Sums the stored rows into the table's groups (weapon/armour, quality, item-level range) and
// keeps the result in window.tteReport as JSON. Read it back in pieces with
// window.tteReport.slice(0, 1500), slice(1500, 3000), ... and paste them together into
// forever_counts.json.
//
// Only items whose materials add up to their disenchant count (within 3%) are used: a material
// page lists at most a few hundred items, so an item missing from one page would otherwise look
// like it never gives that material.
(() => {
  const B = window.tteBrackets;
  if (!B) return 'set window.tteBrackets first (python build.py --brackets)';
  const stored = JSON.parse(localStorage.getItem('tteDE') || '{}');
  const shares = ps => {
    const o = {};
    if (typeof ps === 'string') for (const m of ps.matchAll(/(\d+)\s*:\s*([\d.]+)/g)) o[m[1]] = +m[2];
    else if (ps) Object.assign(o, ps);
    if (!Object.keys(o).length) o[1] = 100;
    return o;
  };
  const items = {};
  for (const mat in stored) for (const [id, lvl, q, cls, count, outof, ps] of stored[mat]) {
    const it = items[id] || (items[id] = { lvl, q, cls, outof, mats: {} });
    it.outof = Math.max(it.outof, outof);
    it.mats[mat] = { count, ps: shares(ps) };
  }
  const out = {};
  let used = 0;
  for (const id in items) {
    const it = items[id];
    const kind = it.cls == 2 ? 'weapon' : it.cls == 4 ? 'armor' : null;
    if (!kind) continue;
    let sum = 0;
    for (const m in it.mats) sum += it.mats[m].count;
    if (Math.abs(sum / it.outof - 1) >= 0.03) continue;
    const br = ((B[kind] || {})[it.q] || []).find(b => it.lvl >= b[0] && it.lvl <= b[1]);
    const key = br ? br[0] + '-' + br[1] : 'level ' + it.lvl;
    const g = ((out[kind] = out[kind] || {})[it.q] = out[kind][it.q] || {});
    const a = g[key] || (g[key] = { n: 0, de: 0, mats: {} });
    a.n++; a.de += it.outof; used++;
    for (const m in it.mats) {
      const mm = a.mats[m] || (a.mats[m] = [0, {}]);
      const c = it.mats[m].count;
      mm[0] += c;
      for (const q in it.mats[m].ps) mm[1][q] = (mm[1][q] || 0) + it.mats[m].ps[q] * c / 100;
    }
  }
  // quantity counts -> rounded % shares
  for (const kind in out) for (const q in out[kind]) for (const k in out[kind][q])
    for (const m in out[kind][q][k].mats) {
      const mm = out[kind][q][k].mats[m];
      const tot = Object.values(mm[1]).reduce((x, y) => x + y, 0) || 1;
      for (const n in mm[1]) mm[1][n] = Math.round(1000 * mm[1][n] / tot) / 10;
    }
  const lists = {};
  for (const mat in stored) lists[mat] = stored[mat].length;
  window.tteReport = JSON.stringify({ collected: new Date().toISOString().slice(0, 10),
    materials: Object.keys(stored).length, items: used, lists, groups: out });
  return 'materials ' + Object.keys(stored).length + ', items used ' + used + ', report ' + window.tteReport.length + ' chars';
})()
