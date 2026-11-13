// Run on a Wowhead Forever material page (https://www.wowhead.com/forever/item=<id>).
// Saves that page's "Disenchanted from" rows in localStorage 'tteDE', keyed by the material,
// so the pages can be loaded one at a time and summed up afterwards by report.js.
// Each row: [itemID, itemLevel, quality, itemClass, timesThisMaterial, timesDisenchanted, qtyShares]
(() => {
  const mat = +location.pathname.match(/item=(\d+)/)[1];
  const lv = window.g_listviews && g_listviews['disenchanted-from'];
  const rows = lv ? lv.data.map(r => [r.id, r.level, r.quality, r.classs, r.count, r.outof, r.pctstack || '']) : [];
  const all = JSON.parse(localStorage.getItem('tteDE') || '{}');
  all[mat] = rows;
  localStorage.setItem('tteDE', JSON.stringify(all));
  return mat + ': ' + rows.length + ' items (' + Object.keys(all).length + ' materials stored)';
})()
