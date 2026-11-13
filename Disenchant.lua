-- Enchanting: what a green, blue or purple weapon or armour piece disenchants into, the chance of
-- each, and what that's worth at Auctionator prices: one row per material with its quantity
-- range and price each, its chance, and its expected value (chance x average quantity x price),
-- then the expected total.
--
-- Data: Wowhead Forever's "disenchanted from" counts for every original-game material (2026-11),
-- grouped by weapon/armour, quality and item level. They match the original game's disenchant
-- table, so that table is used here (from Auctionator's Classic data). Forever has no Burning
-- Crusade materials: blues above level 65 still give Large Brilliant Shards and purples above 60
-- give 1-2 Nexus Crystals, as Wowhead Forever shows.
local ADDON, ns = ...

-- DE[kind][quality] = { { lowLevel, highLevel, { itemID, chance %, minQty, maxQty, avgQty }, ... } }
local DE = {
  armor = {
    [2] = {
      { 5, 15, { 10940, 80, 1, 2, 1.5 }, { 10938, 20, 1, 2, 1.5 } },
      { 16, 20, { 10940, 75, 2, 3, 2.5 }, { 10939, 20, 1, 2, 1.5 }, { 10978, 5, 1, 1, 1 } },
      { 21, 25, { 10940, 75, 4, 6, 5 }, { 10998, 15, 1, 2, 1.5 }, { 10978, 10, 1, 1, 1 } },
      { 26, 30, { 11083, 75, 1, 2, 1.5 }, { 11082, 20, 1, 2, 1.5 }, { 11084, 5, 1, 1, 1 } },
      { 31, 35, { 11083, 75, 2, 5, 3.5 }, { 11134, 20, 1, 2, 1.5 }, { 11138, 5, 1, 1, 1 } },
      { 36, 40, { 11137, 75, 1, 2, 1.5 }, { 11135, 20, 1, 2, 1.5 }, { 11139, 5, 1, 1, 1 } },
      { 41, 45, { 11137, 75, 2, 5, 3.5 }, { 11174, 20, 1, 2, 1.5 }, { 11177, 5, 1, 1, 1 } },
      { 46, 50, { 11176, 75, 1, 2, 1.5 }, { 11175, 20, 1, 2, 1.5 }, { 11178, 5, 1, 1, 1 } },
      { 51, 55, { 11176, 75, 2, 5, 3.5 }, { 16202, 20, 1, 2, 1.5 }, { 14343, 5, 1, 1, 1 } },
      { 56, 60, { 16204, 75, 1, 2, 1.5 }, { 16203, 20, 1, 2, 1.5 }, { 14344, 5, 1, 1, 1 } },
      { 61, 65, { 16204, 75, 2, 5, 3.5 }, { 16203, 20, 2, 3, 2.5 }, { 14344, 5, 1, 1, 1 } },
    },
    [3] = {
      { 11, 25, { 10978, 100, 1, 1, 1 } },
      { 26, 30, { 11084, 100, 1, 1, 1 } },
      { 31, 35, { 11138, 100, 1, 1, 1 } },
      { 36, 40, { 11139, 100, 1, 1, 1 } },
      { 41, 45, { 11177, 100, 1, 1, 1 } },
      { 46, 50, { 11178, 100, 1, 1, 1 } },
      { 51, 55, { 14343, 100, 1, 1, 1 } },
      { 56, 99, { 14344, 99.5, 1, 1, 1 }, { 20725, 0.5, 1, 1, 1 } },
    },
    [4] = {
      { 40, 45, { 11177, 100, 2, 4, 3 } },
      { 46, 50, { 11178, 100, 2, 4, 3 } },
      { 51, 55, { 14343, 100, 2, 4, 3 } },
      { 56, 60, { 20725, 100, 1, 1, 1 } },
      { 61, 99, { 20725, 100, 1, 2, 1.5 } },
    },
  },
  weapon = {
    [2] = {
      { 6, 15, { 10938, 80, 1, 2, 1.5 }, { 10940, 20, 1, 2, 1.5 } },
      { 16, 20, { 10939, 75, 1, 2, 1.5 }, { 10940, 20, 2, 3, 2.5 }, { 10978, 5, 1, 1, 1 } },
      { 21, 25, { 10939, 75, 1, 2, 1.5 }, { 10940, 15, 4, 6, 5 }, { 10978, 10, 1, 1, 1 } },
      { 26, 30, { 10939, 75, 1, 2, 1.5 }, { 11083, 20, 1, 2, 1.5 }, { 11084, 5, 1, 1, 1 } },
      { 31, 35, { 11134, 75, 1, 2, 1.5 }, { 11083, 20, 2, 5, 3.5 }, { 11138, 5, 1, 1, 1 } },
      { 36, 40, { 11135, 75, 1, 2, 1.5 }, { 11137, 20, 1, 2, 1.5 }, { 11139, 5, 1, 1, 1 } },
      { 41, 45, { 11174, 75, 1, 2, 1.5 }, { 11137, 20, 2, 5, 3.5 }, { 11177, 5, 1, 1, 1 } },
      { 46, 50, { 11175, 75, 1, 2, 1.5 }, { 11176, 20, 1, 2, 1.5 }, { 11178, 5, 1, 1, 1 } },
      { 51, 55, { 16202, 75, 1, 2, 1.5 }, { 11176, 22, 2, 5, 3.5 }, { 14343, 5, 1, 1, 1 } },
      { 56, 60, { 16203, 75, 1, 2, 1.5 }, { 16204, 22, 1, 2, 1.5 }, { 14344, 5, 1, 1, 1 } },
      { 61, 65, { 16203, 75, 2, 3, 2.5 }, { 16204, 22, 2, 5, 3.5 }, { 14344, 5, 1, 1, 1 } },
    },
    [3] = {
      { 11, 25, { 10978, 100, 1, 1, 1 } },
      { 26, 30, { 11084, 100, 1, 1, 1 } },
      { 31, 35, { 11138, 100, 1, 1, 1 } },
      { 36, 40, { 11139, 100, 1, 1, 1 } },
      { 41, 45, { 11177, 100, 1, 1, 1 } },
      { 46, 50, { 11178, 100, 1, 1, 1 } },
      { 51, 55, { 14343, 100, 1, 1, 1 } },
      { 56, 99, { 14344, 99.5, 1, 1, 1 }, { 20725, 0.5, 1, 1, 1 } },
    },
    [4] = {
      { 40, 45, { 11177, 100, 2, 4, 3 } },
      { 46, 50, { 11178, 100, 2, 4, 3 } },
      { 51, 55, { 14343, 100, 2, 4, 3 } },
      { 56, 60, { 20725, 100, 1, 1, 1 } },
      { 61, 99, { 20725, 100, 1, 2, 1.5 } },
    },
  },
}

-- Essences combine 3 lesser = 1 greater, so each is worth at least its share of the other.
local ESSENCE = {
  [10938] = { 10939, 1 / 3 }, [10939] = { 10938, 3 },
  [10998] = { 11082, 1 / 3 }, [11082] = { 10998, 3 },
  [11134] = { 11135, 1 / 3 }, [11135] = { 11134, 3 },
  [11174] = { 11175, 1 / 3 }, [11175] = { 11174, 3 },
  [16202] = { 16203, 1 / 3 }, [16203] = { 16202, 3 },
}

local function Value(id)
  local p = ns.Price(id)
  local e = ESSENCE[id]
  local other = e and ns.Price(e[1])
  if other then
    local via = other * e[2]
    if not p or via > p then return via end
  end
  return p
end

-- Shirts and tabards are armour but can't be disenchanted.
local NO_DE = { INVTYPE_BODY = true, INVTYPE_TABARD = true }

local function Row(id)
  local info = { (C_Item and C_Item.GetItemInfo or GetItemInfo)(id) }
  local quality, level, equipLoc, classID = info[3], info[4], info[9], info[12]
  if not quality or quality < 2 or quality > 4 or NO_DE[equipLoc] then return nil end
  local kind = (classID == 2 and "weapon") or (classID == 4 and "armor") or nil
  if not kind then return nil end
  for _, row in ipairs(DE[kind][quality]) do
    if level >= row[1] and level <= row[2] then return row end
  end
end

local function Chance(pct)
  if pct >= 10 or pct == math.floor(pct) then return string.format("%d%%", math.floor(pct + 0.5)) end
  return (string.format("%.1f", pct):gsub("%.0$", "")) .. "%"
end

local function GoldDigits(copper)
  local g = math.floor((copper or 0) / 10000)
  return g > 0 and #tostring(g) or 0
end

local CHANCE = { "chance", "100%" }

-- For item id: { { material, chance %, price each, expected value }, ... }, the expected total
-- and whether any price is missing. nil when it can't be disenchanted.
local function Compute(id)
  local row = Row(id)
  if not row then return nil end
  local sum = 0
  for i = 3, #row do sum = sum + row[i][2] end
  local lines, total, missing = {}, 0, false
  for i = 3, #row do
    local m = row[i]
    local pct = m[2] * 100 / sum
    local each = Value(m[1])
    local value = each and each * m[5] * pct / 100
    if value then total = total + value else missing = true end
    lines[#lines + 1] = { m, pct, each, value }
  end
  return lines, total, missing
end

-- Expected disenchant value of one item id in copper; nil when it can't be disenchanted or a
-- material has no price.
function ns.DisenchantValue(id)
  local lines, total, missing = Compute(id)
  if not lines or missing then return nil end
  return math.floor(total + 0.5)
end

function ns.CanDisenchant(id)
  return Row(id) ~= nil
end

-- Adds the disenchant rows for item id; true when it added any.
function ns.DisenchantLines(tooltip, id)
  local lines, total, missing = Compute(id)
  if not lines then return false end
  local widest = 0
  for _, l in ipairs(lines) do widest = math.max(widest, l[4] or 0) end
  local spec = { { text = CHANCE }, { gold = GoldDigits(math.max(widest, total)) } }
  local GOLD, WHITE = { 1, 0.82, 0 }, { 1, 1, 1 }
  tooltip:AddLine(" ")
  ns.MixedLine(tooltip, ns.ProfessionTag("Enchanting") .. "Disenchant", spec, { "chance", "value" },
    1, 0.82, 0, { GOLD, GOLD })
  for _, l in ipairs(lines) do
    local m, pct, each, value = l[1], l[2], l[3], l[4]
    local qty = m[3] == m[4] and tostring(m[3]) or (m[3] .. "-" .. m[4])
    local name = ns.ItemName(m[1]) or ("item " .. m[1])
    local left = "  " .. qty .. " x " .. name
      .. (each and (" |cff999999(" .. ns.Money(each) .. ")|r") or " |cff808080(no price)|r")
    ns.MixedLine(tooltip, left, spec, { Chance(pct), value }, 0.9, 0.9, 0.9, { WHITE, WHITE })
  end
  ns.MixedLine(tooltip, missing and "  Expected (prices missing)" or "  Expected", spec,
    { nil, total }, 1, 0.82, 0, { WHITE, WHITE })
  return true
end

----------------------------------------------------------------------------------------------
-- Auctionator's own "Disenchant" line (under Vendor and Auction) only knows Warlords of Draenor
-- and later gear, so it's blank on Forever. When it has no value, it gets ours instead. Nothing
-- in Auctionator's files changes: its two lookups are wrapped at login.

local function DisenchantOn()
  for _, m in ipairs(ns.modules) do
    if m.key == "essences" then
      local db = ns.ModuleDB(m)
      return db.enabled and db.disenchant ~= false
    end
  end
  return false
end

local function IDOf(itemLink)
  if type(itemLink) ~= "string" then return nil end
  return (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(itemLink)
end

local function WrapAuctionator()
  local E = Auctionator and Auctionator.Enchant
  if not E or not E.GetDisenchantAuctionPrice or not E.DisenchantStatus or E.TooltipExtras then return end
  E.TooltipExtras = true
  local price, status = E.GetDisenchantAuctionPrice, E.DisenchantStatus
  E.GetDisenchantAuctionPrice = function(itemLink, itemInfo, ...)
    local v = price(itemLink, itemInfo, ...)
    if v == nil and DisenchantOn() then
      local ok, id = pcall(IDOf, itemLink)
      if ok and id then v = ns.DisenchantValue(id) end
    end
    return v
  end
  E.DisenchantStatus = function(itemInfo, ...)
    local s = status(itemInfo, ...)
    -- itemInfo[2] is the link; ours are the original game's items, so mark them supported and
    -- Auctionator shows "Unknown" when a material has no price.
    local link = type(itemInfo) == "table" and itemInfo[2]
    if type(s) == "table" and DisenchantOn() then
      local ok, id = pcall(IDOf, link)
      if ok and id and ns.CanDisenchant(id) then
        s.isDisenchantable, s.supportedXpac = true, true
      end
    end
    return s
  end
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", WrapAuctionator)

----------------------------------------------------------------------------------------------
-- Best of Auctionator's Vendor, Auction and Disenchant lines in green. Compared after the auction
-- house cut (when that setting is on), since vendoring has none.

local BEST = "|cff33ff33"

local MODULE = {
  key = "bestsale",
  category = "other",
  label = "Best way to sell",
  tip = "Of Auctionator's Vendor, Auction and Disenchant lines, the one worth the most turns green. "
    .. "Auction and disenchant values count the 5% auction house cut when that setting is on.",
  options = { { key = "highlight", label = "Highlight the best of Vendor, Auction, Disenchant", default = true } },
}
ns.AddModule(MODULE)

-- The tooltip line whose left text is label, optionally followed by a count; nil if none.
local function FindLine(tooltip, label)
  if type(label) ~= "string" then return nil end
  local name = tooltip:GetName()
  if not name then return nil end
  local pattern = "^" .. label:gsub("%p", "%%%0") .. "%f[^%a]"
  for i = 1, tooltip:NumLines() do
    local left = _G[name .. "TextLeft" .. i]
    local text = left and left:GetText()
    if text and text:match(pattern) and not text:match("^" .. label:gsub("%p", "%%%0") .. " %a") then
      return left, _G[name .. "TextRight" .. i]
    end
  end
end

MODULE.OnItem = function(tooltip, id, db)
  if db.highlight == false then return false end
  local info = { (C_Item and C_Item.GetItemInfo or GetItemInfo)(id) }
  local keep = ns.Keep()
  local found = {}
  local function Try(label, value)
    if not value or value <= 0 then return end
    local left, right = FindLine(tooltip, label)
    if left then found[#found + 1] = { value, left, right } end
  end
  Try(AUCTIONATOR_L_VENDOR, info[11])
  local ah = ns.Price(id)
  Try(AUCTIONATOR_L_AUCTION, ah and ah * keep)
  local de = DisenchantOn() and ns.DisenchantValue(id)
  Try(AUCTIONATOR_L_DISENCHANT, de and de * keep)
  if #found < 2 then return false end
  table.sort(found, function(a, b) return a[1] > b[1] end)
  local left, right = found[1][2], found[1][3]
  left:SetText(BEST .. left:GetText() .. "|r")
  if right and right:GetText() then
    right:SetText(BEST .. right:GetText():gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") .. "|r")
  end
  return false
end
