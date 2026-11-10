-- Enchanting: essences convert 3 lesser <-> 1 greater (right-click either one).
-- One tooltip line: on a lesser, the profit from combining 3 into a greater; on a greater, the
-- profit from splitting it into 3 lessers. Prices come from Auctionator.
local ADDON, ns = ...

-- lesser item ID, greater item ID, short name (for reading the table)
local PAIRS = {
  { 10938, 10939, "Magic" },
  { 10998, 11082, "Astral" },
  { 11134, 11135, "Mystic" },
  { 11174, 11175, "Nether" },
  { 16202, 16203, "Eternal" },
  { 22447, 22446, "Planar" },
  { 34056, 34055, "Cosmic" },
  { 52718, 52719, "Celestial" },
}

local byItem = {} -- itemID -> { lesser, greater, isGreater }
for _, p in ipairs(PAIRS) do
  byItem[p[1]] = { lesser = p[1], greater = p[2], isGreater = false }
  byItem[p[2]] = { lesser = p[1], greater = p[2], isGreater = true }
end

ns.AddModule({
  key = "essences",
  label = "Enchanting",
  tip = "Essences. On a lesser: the profit from combining 3 into a greater. "
    .. "On a greater: the profit from splitting it into 3 lessers.",
  OnItem = function(tooltip, id)
    local e = byItem[id]
    if not e then return false end
    local lp, gp = ns.Price(e.lesser), ns.Price(e.greater)
    -- You sell whichever form you end up with, so the AH cut applies to both sides and the
    -- profit is the price gap times what you keep.
    local profit
    if lp and gp then
      local gap = gp - lp * 3
      if e.isGreater then gap = -gap end
      profit = gap * ns.Keep()
    end
    -- Auctionator already shows the hovered item's price age, so only flag the other one.
    local other = e.isGreater and e.lesser or e.greater
    local label = e.isGreater and "Split to Lesser" or "Combine to Greater"
    tooltip:AddLine(" ")
    ns.ProfitLine(tooltip, label .. (profit and ns.Age(other) or ""), profit)
    return true
  end,
})
