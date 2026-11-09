-- Essence swap: enchanting essences convert 3 lesser <-> 1 greater (right-click either one).
-- On either essence the tooltip shows both prices from Auctionator, highlights whether 3 lessers
-- or 1 greater sells for more, and says what converting the ones you own gains. An AH flip line
-- (buy, convert, resell) appears only when that is profitable too.
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
  tip = "On lesser and greater enchanting essences: 3 lessers against 1 greater, the better one highlighted, "
    .. "and whether to combine (3 into 1) or split (1 into 3) before selling. Prices come from Auctionator.",
  options = {
    { key = "ahCut", label = "Take off the 5% auction house cut", default = true,
      tip = "The profit lines count the 5% the auction house keeps when you sell." },
  },
  OnItem = function(tooltip, id, db)
    local e = byItem[id]
    if not e then return false end
    local lesserName = Name(e.lesser, "Lesser " .. e.short .. " Essence")
    local greaterName = Name(e.greater, "Greater " .. e.short .. " Essence")
    local lp, gp = Price(e.lesser), Price(e.greater)

    -- Which form sells for more: 3 lessers or 1 greater. nil until both prices are known.
    local better -- "lesser" | "greater" | "same"
    if lp and gp then
      if gp > lp * 3 then better = "greater"
      elseif gp < lp * 3 then better = "lesser"
      else better = "same" end
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("Essence swap (3 lesser = 1 greater)", 1, 0.82, 0)
    -- The side that sells for more goes green with a "<< better" tag, the other grey.
    -- Both stay white when the prices are equal.
    local function Row(label, price, ageID, side)
      if not price then
        tooltip:AddDoubleLine(label, "no price", 1, 1, 1, 0.5, 0.5, 0.5)
        return
      end
      local value = ns.Money(price) .. (ageID and Age(ageID) or "")
      if side and better == side then
        tooltip:AddDoubleLine(label .. "  |cff33ff99<< better|r", value, 0.2, 1, 0.6, 0.2, 1, 0.6)
      elseif side and better and better ~= "same" then
        tooltip:AddDoubleLine(label, value, 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
      else
        tooltip:AddDoubleLine(label, value, 1, 1, 1, 1, 1, 1)
      end
    end
    -- Just the two sides being compared. Auctionator already shows single-item prices.
    Row("3 x " .. lesserName, lp and lp * 3, e.lesser, "lesser")
    Row(greaterName, gp, e.greater, "greater")
    if not better then return true end

    -- Verdict for essences you already own: the AH cut comes off whichever form you sell,
    -- so the gain is the price gap times what you keep.
    local keep = db.ahCut and (1 - AH_CUT) or 1
    local cutNote = db.ahCut and " |cff808080(after AH cut)|r" or ""
    if better == "same" then
      tooltip:AddLine("Same price either way", 1, 1, 1)
    else
      local gain = math.abs(gp - lp * 3) * keep
      local action
      if better == "greater" then
        action = "Combine 3 into 1, sell the greater"
      else
        action = "Split 1 into 3, sell the lessers"
      end
      tooltip:AddDoubleLine(action .. cutNote, "+" .. ns.Money(gain), 0.2, 1, 0.6, 0.2, 1, 0.6)
    end

    -- AH flip: buy the cheap side off the AH, convert, sell the other side. You pay full
    -- price going in and lose the cut coming out, so only show it when it still makes money.
    local flip, flipLabel
    if better == "greater" then
      flip, flipLabel = gp * keep - lp * 3, "Flip: buy 3 lesser, sell 1 greater"
    elseif better == "lesser" then
      flip, flipLabel = lp * 3 * keep - gp, "Flip: buy 1 greater, sell 3 lesser"
    end
    if flip and flip >= 1 then
      tooltip:AddDoubleLine(flipLabel .. cutNote, "+" .. ns.Money(flip), 1, 1, 1, 0.2, 1, 0.6)
    end
    return true
  end,
})
