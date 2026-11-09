-- Essence swap: enchanting essences convert 3 lesser <-> 1 greater (right-click either one).
-- One tooltip line: on a lesser, the profit from combining 3 into a greater; on a greater, the
-- profit from splitting it into 3 lessers. Prices come from Auctionator.
local ADDON, ns = ...

local CALLER = "TooltipExtras"
local AH_CUT = 0.05

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

local byItem = {} -- itemID -> { lesser, greater, short, isGreater }
for _, p in ipairs(PAIRS) do
  byItem[p[1]] = { lesser = p[1], greater = p[2], short = p[3], isGreater = false }
  byItem[p[2]] = { lesser = p[1], greater = p[2], short = p[3], isGreater = true }
end

local API = Auctionator and Auctionator.API and Auctionator.API.v1

local function Price(id)
  API = API or (Auctionator and Auctionator.API and Auctionator.API.v1)
  if not API or not API.GetAuctionPriceByItemID then return nil end
  local ok, price = pcall(API.GetAuctionPriceByItemID, CALLER, id)
  return ok and price or nil
end

-- " (3d old)" when the price wasn't seen today. Auctionator gives up counting past 21 days.
local function Age(id)
  if not API or not API.GetAuctionAgeByItemID then return "" end
  local ok, days = pcall(API.GetAuctionAgeByItemID, CALLER, id)
  if not ok then return "" end
  if days == nil then return " |cff808080(old)|r" end
  if days >= 1 then return string.format(" |cff808080(%dd old)|r", days) end
  return ""
end

ns.AddModule({
  key = "essences",
  label = "Essence swap profit",
  tip = "On a lesser enchanting essence: the profit from combining 3 into a greater. "
    .. "On a greater: the profit from splitting it into 3 lessers. Prices come from Auctionator.",
  options = {
    { key = "ahCut", label = "Take off the 5% auction house cut", default = true,
      tip = "The profit counts the 5% the auction house keeps when you sell." },
  },
  OnItem = function(tooltip, id, db)
    local e = byItem[id]
    if not e then return false end
    local label = e.isGreater and "Split to Lesser" or "Combine to Greater"
    local lp, gp = Price(e.lesser), Price(e.greater)

    tooltip:AddLine(" ")
    if not (lp and gp) then
      tooltip:AddDoubleLine(label, "no price", 1, 0.82, 0, 0.5, 0.5, 0.5)
      return true
    end

    -- You sell whichever form you end up with, so the AH cut applies to both sides and the
    -- profit is the price gap times what you keep.
    local keep = db.ahCut and (1 - AH_CUT) or 1
    local gap = gp - lp * 3
    if e.isGreater then gap = -gap end
    local profit = gap * keep

    local r, g, b = 0.2, 1, 0.6
    if profit < 0 then r, g, b = 1, 0.33, 0.33 end
    -- Auctionator already shows the hovered item's price age, so only flag the other one.
    local other = e.isGreater and e.lesser or e.greater
    tooltip:AddDoubleLine(label .. Age(other), (profit >= 0 and "+" or "") .. ns.Money(profit),
      1, 0.82, 0, r, g, b)
    return true
  end,
})
