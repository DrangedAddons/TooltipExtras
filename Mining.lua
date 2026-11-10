-- Mining: is ore worth more smelted into bars? One tooltip line on the ore and on its bar,
-- with the profit per bar from smelting ore you already have instead of selling it.
-- Prices come from Auctionator. Smelts are Forever's (from CraftRoute's MiningRecipes.lua).
local ADDON, ns = ...

local COAL = 3857

-- ore item ID, ores per bar, bar item ID, extra reagents bought for the smelt { {itemID, count} }
local SMELTS = {
  { 2770, 1, 2840 },     -- Copper
  { 2771, 1, 3576 },     -- Tin
  { 2775, 1, 2842 },     -- Silver
  { 2772, 1, 3575 },     -- Iron
  { 2776, 1, 3577 },     -- Gold
  { 3858, 1, 3860 },     -- Mithril
  { 7911, 1, 6037 },     -- Truesilver
  { 11370, 8, 11371 },   -- Dark Iron (Black Forge)
  { 10620, 1, 12359 },   -- Thorium
  { 249426, 2, 249726, { { COAL, 1 } } }, -- Azerothium
  { 248815, 1, 251291 }, -- Heavy Thorium (Molten Foundry)
}

local byItem = {} -- itemID -> { smelt, isBar }
for _, s in ipairs(SMELTS) do
  local smelt = { ore = s[1], count = s[2], bar = s[3], extras = s[4] or {} }
  byItem[smelt.ore] = { smelt = smelt, isBar = false }
  byItem[smelt.bar] = { smelt = smelt, isBar = true }
end

-- " (8 ore per bar)" / " (2 ore + Coal per bar)"; "" for a plain 1:1 smelt.
local function Recipe(s)
  if s.count == 1 and #s.extras == 0 then return "" end
  local parts = { s.count .. " ore" }
  for _, x in ipairs(s.extras) do
    local name = ns.ItemName(x[1]) or (x[1] == COAL and "Coal") or "?"
    parts[#parts + 1] = (x[2] > 1 and (x[2] .. " ") or "") .. name
  end
  return " |cff808080(" .. table.concat(parts, " + ") .. " per bar)|r"
end

ns.AddModule({
  key = "mining",
  label = "Mining",
  tip = "Ore and bars. Whether smelting the ore into bars sells for more than the ore itself, "
    .. "as profit or loss per bar. Extra reagents like Coal count at their auction price.",
  OnItem = function(tooltip, id)
    local e = byItem[id]
    if not e then return false end
    local s = e.smelt
    local op, bp = ns.Price(s.ore), ns.Price(s.bar)
    -- You sell either the ore or the bar, so the AH cut hits both. Extra reagents you'd buy.
    local profit
    if op and bp then
      profit = (bp - op * s.count) * ns.Keep()
      for _, x in ipairs(s.extras) do
        local xp = ns.Price(x[1])
        if not xp then profit = nil break end
        profit = profit - xp * x[2]
      end
    end
    local age = ""
    if profit then
      -- Auctionator already shows the hovered item's age; flag the others.
      local others = { e.isBar and s.ore or s.bar }
      for _, x in ipairs(s.extras) do others[#others + 1] = x[1] end
      age = ns.Age(unpack(others))
    end
    local label = (e.isBar and "Smelt from Ore" or "Smelt to Bar") .. Recipe(s) .. age
    tooltip:AddLine(" ")
    ns.ProfitLine(tooltip, label, profit)
    return true
  end,
})
