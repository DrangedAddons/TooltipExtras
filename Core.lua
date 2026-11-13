-- TooltipExtras: extra lines on item tooltips. Each feature is a module, one per profession:
--   ns.AddModule{ key, label = profession name, tip, options = { {key, label, tip, default}... },
--     OnItem(tooltip, itemID, db), OnUnit(tooltip, npcID, db),
--     category = "professions" | "events" | "quests" | "reputation" | "classes" (settings heading) }
-- OnItem / OnUnit are both optional; each returns true when it added lines.
-- Core keeps the settings, hooks the item tooltip once and hands every item to each ticked module.
local ADDON, ns = ...

ns.modules = {}

function ns.AddModule(m)
  ns.modules[#ns.modules + 1] = m
end

-- Settings: TooltipExtrasDB[moduleKey] = { enabled = bool, <option> = bool }. Account-wide.
local function ModuleDB(m)
  TooltipExtrasDB = TooltipExtrasDB or {}
  local db = TooltipExtrasDB[m.key]
  if type(db) ~= "table" then
    db = {}
    TooltipExtrasDB[m.key] = db
  end
  if db.enabled == nil then db.enabled = m.default ~= false end
  for _, o in ipairs(m.options or {}) do
    if db[o.key] == nil then db[o.key] = o.default and true or false end
  end
  return db
end
ns.ModuleDB = ModuleDB

-- Settings shared by every module: TooltipExtrasDB.general. Account-wide.
function ns.GeneralDB()
  TooltipExtrasDB = TooltipExtrasDB or {}
  local g = TooltipExtrasDB.general
  if type(g) ~= "table" then
    g = {}
    TooltipExtrasDB.general = g
  end
  if g.ahCut == nil then
    -- 0.1.x kept this on the essences module
    local ess = TooltipExtrasDB.essences
    g.ahCut = not (type(ess) == "table" and ess.ahCut == false)
    if type(ess) == "table" then ess.ahCut = nil end
  end
  return g
end

----------------------------------------------------------------------------------------------
-- Shared helpers

-- "12g 50s 3c" with coin icons; negative amounts get a minus sign.
function ns.Money(copper)
  copper = math.floor((copper or 0) + 0.5)
  local sign = copper < 0 and "-" or ""
  copper = math.abs(copper)
  local text
  if GetMoneyString then
    text = GetMoneyString(copper, true)
  elseif C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
    text = C_CurrencyInfo.GetCoinTextureString(copper)
  else
    text = copper .. "c"
  end
  return sign .. text
end

function ns.ItemName(id)
  local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id))
    or (GetItemInfo and GetItemInfo(id))
  return name
end

-- Auctionator prices, callerID "TooltipExtras". nil when Auctionator is missing or has no price.
local CALLER = "TooltipExtras"
local function API()
  return Auctionator and Auctionator.API and Auctionator.API.v1
end

function ns.Price(id)
  local api = API()
  if not api or not api.GetAuctionPriceByItemID then return nil end
  local ok, price = pcall(api.GetAuctionPriceByItemID, CALLER, id)
  return ok and price or nil
end

-- What it costs to buy one: the cheaper of the auction price and the vendor price Auctionator
-- saw at a merchant (thread, dye, flux). nil when neither is known.
function ns.BuyPrice(id)
  local ah = ns.Price(id)
  local api = API()
  local vendor
  if api and api.GetVendorPriceByItemID then
    local ok, p = pcall(api.GetVendorPriceByItemID, CALLER, id)
    if ok and type(p) == "number" and p > 0 then vendor = p end
  end
  if ah and vendor then return math.min(ah, vendor) end
  return ah or vendor
end

-- " (3d old)" for the first of the given items whose price wasn't seen today, else "".
-- Auctionator gives up counting past 21 days.
function ns.Age(...)
  local api = API()
  if not api or not api.GetAuctionAgeByItemID then return "" end
  for i = 1, select("#", ...) do
    local ok, days = pcall(api.GetAuctionAgeByItemID, CALLER, (select(i, ...)))
    if ok then
      if days == nil then return " |cff808080(old)|r" end
      if days >= 1 then return string.format(" |cff808080(%dd old)|r", days) end
    end
  end
  return ""
end

-- Share of a sale you keep: 0.95 with the AH cut option on, else 1.
function ns.Keep()
  return ns.GeneralDB().ahCut and 0.95 or 1
end

-- "Blacksmithing: " in light blue, to put in front of a conversion line's label.
function ns.ProfessionTag(name)
  return "|cff66ccff" .. name .. ":|r "
end

-- One "Label   +1g 2s 3c" line, green for profit, red for loss. Label in tooltip gold.
function ns.ProfitLine(tooltip, label, profit)
  if not profit then
    tooltip:AddDoubleLine(label, "no price", 1, 0.82, 0, 0.5, 0.5, 0.5)
    return
  end
  local r, g, b = 0.2, 1, 0.6
  if profit < 0 then r, g, b = 1, 0.33, 0.33 end
  tooltip:AddDoubleLine(label, (profit >= 0 and "+" or "") .. ns.Money(profit), 1, 0.82, 0, r, g, b)
end

----------------------------------------------------------------------------------------------
-- The tooltip hook: once per item tooltip, after Auctionator's own lines.

local function ItemIDOf(tooltip, data)
  if data and data.id then return data.id end
  if tooltip.GetItem then
    local _, link = tooltip:GetItem()
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then return id end
  end
end

-- Hands id to every ticked module that has handler `which` ("OnItem" / "OnUnit").
local function RunModules(tooltip, which, id)
  local added = false
  for _, m in ipairs(ns.modules) do
    local db = ModuleDB(m)
    if db.enabled and m[which] then
      local ok, err = pcall(m[which], tooltip, id, db)
      if ok and err then added = true end
      if not ok and not m.failed then
        m.failed = true
        print("|cff33ff99TooltipExtras|r: " .. m.label .. " failed: " .. tostring(err))
      end
    end
  end
  if added then tooltip:Show() end -- resize to fit the new lines
end

local function OnItem(tooltip, data)
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip and tooltip ~= ShoppingTooltip1
    and tooltip ~= ShoppingTooltip2 then
    return
  end
  local id = ItemIDOf(tooltip, data)
  if id then RunModules(tooltip, "OnItem", id) end
end

-- NPC ID from a creature GUID ("Creature-0-xxx-xxx-xxx-14829-xxx"); nil for players and pets.
local function NpcIDOf(tooltip, data)
  local guid = data and data.guid
  if not guid and tooltip.GetUnit then
    local _, unit = tooltip:GetUnit()
    guid = unit and UnitGUID(unit)
  end
  if type(guid) ~= "string" then return nil end
  local kind, _, _, _, _, npc = strsplit("-", guid)
  if kind ~= "Creature" then return nil end
  return tonumber(npc)
end

local function OnUnit(tooltip, data)
  if tooltip ~= GameTooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  local ok, id = pcall(NpcIDOf, tooltip, data)
  if ok and id then RunModules(tooltip, "OnUnit", id) end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  for _, m in ipairs(ns.modules) do ModuleDB(m) end
  ns.GeneralDB()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItem)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnit)
  else
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
      tip:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
    end
    GameTooltip:HookScript("OnTooltipSetUnit", function(self) OnUnit(self) end)
  end
end)

----------------------------------------------------------------------------------------------
-- Slash command and the addon list button

SLASH_TOOLTIPEXTRAS1 = "/tooltipextras"
SLASH_TOOLTIPEXTRAS2 = "/tte"
-- /tte debug toggles chat output from ns.Debug (session only).
function ns.Debug(...)
  if ns.debug then print("|cff33ff99TTE debug|r", ...) end
end

SlashCmdList.TOOLTIPEXTRAS = function(msg)
  if (msg or ""):lower():match("^%s*debug") then
    ns.debug = not ns.debug
    print("|cff33ff99TooltipExtras|r debug " .. (ns.debug and "on" or "off")
      .. ". Line hook API: " .. tostring(TooltipDataProcessor and TooltipDataProcessor.AddLinePreCall ~= nil))
    return
  end
  ns.OpenOptions()
end

function TooltipExtras_OnCompartmentClick() ns.OpenOptions() end
