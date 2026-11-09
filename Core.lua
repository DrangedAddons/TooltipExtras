-- TooltipExtras: extra lines on item tooltips. Each feature is a module:
--   ns.AddModule{ key, label, tip, options = { {key, label, tip, default}... }, OnItem(tooltip, itemID) }
-- Core keeps the settings, hooks the item tooltip once and hands every item to each enabled module.
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

local function OnItem(tooltip, data)
  if not tooltip or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip and tooltip ~= ShoppingTooltip1
    and tooltip ~= ShoppingTooltip2 then
    return
  end
  local id = ItemIDOf(tooltip, data)
  if not id then return end
  local added = false
  for _, m in ipairs(ns.modules) do
    local db = ModuleDB(m)
    if db.enabled then
      local ok, err = pcall(m.OnItem, tooltip, id, db)
      if ok and err then added = true end
      if not ok and not m.failed then
        m.failed = true
        print("|cff33ff99TooltipExtras|r: " .. m.label .. " failed: " .. tostring(err))
      end
    end
  end
  if added then tooltip:Show() end -- resize to fit the new lines
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function()
  for _, m in ipairs(ns.modules) do ModuleDB(m) end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItem)
  else
    for _, tip in ipairs({ GameTooltip, ItemRefTooltip }) do
      tip:HookScript("OnTooltipSetItem", function(self) OnItem(self) end)
    end
  end
end)

----------------------------------------------------------------------------------------------
-- Slash command and the addon list button

SLASH_TOOLTIPEXTRAS1 = "/tooltipextras"
SLASH_TOOLTIPEXTRAS2 = "/tte"
SlashCmdList.TOOLTIPEXTRAS = function() ns.OpenOptions() end

function TooltipExtras_OnCompartmentClick() ns.OpenOptions() end
