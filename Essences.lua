-- Essence swap: enchanting essences convert 3 lesser <-> 1 greater (right-click either one).
-- On either essence the tooltip shows both prices from Auctionator, what 3 lessers cost
-- against 1 greater, and whether combining or splitting makes money.
local ADDON, ns = ...

local CALLER = "TooltipExtras"
local AH_CUT = 0.05

-- lesser item ID, greater item ID, short name (used until the item names load)
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

local function Name(id, fallback)
  return ns.ItemName(id) or fallback
end

ns.AddModule({
  key = "essences",
  label = "Essence swap prices",
  tip = "On lesser and greater enchanting essences: both prices, 3 lessers against 1 greater, "
    .. "and whether combining (3 into 1) or splitting (1 into 3) makes money. Prices come from Auctionator.",
  options = {
    { key = "ahCut", label = "Take off the 5% auction house cut", default = true,
      tip = "The profit line counts the 5% the auction house keeps when you sell the result." },
  },
  OnItem = function(tooltip, id, db)
    local e = byItem[id]
    if not e then return false end
    local lesserName = Name(e.lesser, "Lesser " .. e.short .. " Essence")
    local greaterName = Name(e.greater, "Greater " .. e.short .. " Essence")
    local lp, gp = Price(e.lesser), Price(e.greater)

    tooltip:AddLine(" ")
    tooltip:AddLine("Essence swap (3 lesser = 1 greater)", 1, 0.82, 0)
    local function Row(label, price, ageID)
      if price then
        tooltip:AddDoubleLine(label, ns.Money(price) .. (ageID and Age(ageID) or ""), 1, 1, 1, 1, 1, 1)
      else
        tooltip:AddDoubleLine(label, "no price", 1, 1, 1, 0.5, 0.5, 0.5)
      end
    end
    -- the hovered essence first
    if e.isGreater then
      Row(greaterName, gp, e.greater)
      Row(lesserName .. " (each)", lp, e.lesser)
      Row("3 x " .. lesserName, lp and lp * 3)
    else
      Row(lesserName .. " (each)", lp, e.lesser)
      Row("3 x " .. lesserName, lp and lp * 3)
      Row(greaterName, gp, e.greater)
    end
    if not (lp and gp) then return true end

    -- buy the cheaper side, convert, sell the other side
    local keep = db.ahCut and (1 - AH_CUT) or 1
    local combine = gp * keep - lp * 3 -- buy 3 lesser, sell 1 greater
    local split = lp * 3 * keep - gp   -- buy 1 greater, sell 3 lesser
    local label, profit
    if combine >= split then
      label, profit = "Combine 3 into 1", combine
    else
      label, profit = "Split 1 into 3", split
    end
    local r, g, b = 0.2, 1, 0.6
    if profit < 0 then r, g, b = 1, 0.33, 0.33 end
    tooltip:AddDoubleLine(label .. (db.ahCut and " |cff808080(after AH cut)|r" or ""),
      (profit >= 0 and "+" or "") .. ns.Money(profit), 1, 1, 1, r, g, b)
    return true
  end,
})
