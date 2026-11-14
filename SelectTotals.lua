-- Bag item totals: Alt+click items in your bags to mark them, and a small window adds up what the
-- marked items are worth: all vendored, all auctioned, all disenchanted, and each sold its best
-- way (the same rule as the green highlight in Disenchant.lua). Alt+click a marked item again
-- to unmark it; Clear or closing the window unmarks everything.
--
-- Bag buttons: EllesmereUI Bags paints its slots through EUI_Bags.RegisterItemOverlayIcon,
-- which tells us each button's bag and slot whenever it redraws, so the marks follow the items.
-- Any other bag addon (Baganator, Blizzard's bags) works through the item tooltip: a slot button
-- is picked up the first time you hover it.
--
-- Marks are kept by bag and slot, with the item ID, and dropped when that slot's item changes.
local ADDON, ns = ...
local UI = ns.UI
ns.Print = ns.Print or function(...) print("|cff33ff99TooltipExtras|r:", ...) end

local MODULE = {
  key = "selecttotals",
  category = "other",
  label = "Bag item totals",
  tip = "Alt+click items in your bags to mark them. A window adds up what they're worth: "
    .. "vendored, auctioned, disenchanted, and each sold its best way.",
  options = { { key = "select", label = "Alt+click bag items to total them", default = true } },
}
ns.AddModule(MODULE)

local FIRST_BAG, LAST_BAG = 0, (NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4)

local selected = {} -- "bag:slot" -> { bag, slot, itemID }
local count = 0
local buttons = setmetatable({}, { __mode = "k" }) -- button -> { bag, slot } (EllesmereUI), or true
local window, Update

local function Enabled()
  local db = ns.ModuleDB(MODULE)
  return db.enabled and db.select ~= false
end

local function KeyOf(bag, slot) return bag .. ":" .. slot end

-- A button's bag and slot: what EllesmereUI last painted on it, else the button's own.
local function Where(btn)
  local s = buttons[btn]
  if type(s) == "table" then return s.bag, s.slot end
  if btn.GetBagID and btn.GetID then
    local ok, bag = pcall(btn.GetBagID, btn)
    if ok and type(bag) == "number" then return bag, btn:GetID() end
  end
end

local function ItemAt(bag, slot)
  local info = C_Container and C_Container.GetContainerItemInfo and C_Container.GetContainerItemInfo(bag, slot)
  return info and info.itemID and info or nil
end

----------------------------------------------------------------------------------------------
-- Marks on the buttons

local function Mark(btn, on)
  local m = btn.tteMark
  if not on then
    if m then m:Hide() end
    return
  end
  if not m then
    m = CreateFrame("Frame", nil, btn)
    m:SetAllPoints(btn)
    m:SetFrameLevel(btn:GetFrameLevel() + 5)
    m.shade = m:CreateTexture(nil, "OVERLAY")
    m.shade:SetAllPoints()
    m.tick = m:CreateTexture(nil, "OVERLAY", nil, 1)
    m.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    m.tick:SetSize(16, 16)
    m.tick:SetPoint("TOPRIGHT", 2, 2)
    btn.tteMark = m
  end
  local r, g, b = 1, 0.82, 0
  if ns.AccentColor then r, g, b = ns.AccentColor() end
  m.shade:SetColorTexture(r, g, b, 0.3)
  m:Show()
end

local function Repaint()
  for btn in pairs(buttons) do
    local bag, slot = Where(btn)
    Mark(btn, bag ~= nil and btn:IsVisible() and selected[KeyOf(bag, slot)] ~= nil)
  end
end

----------------------------------------------------------------------------------------------
-- Selecting

local function Clear()
  wipe(selected)
  count = 0
  Repaint()
end

local function Toggle(bag, slot)
  if bag < FIRST_BAG or bag > LAST_BAG then return end -- bags only, not the bank
  local key = KeyOf(bag, slot)
  if selected[key] then
    selected[key] = nil
    count = count - 1
  else
    local info = ItemAt(bag, slot)
    if not info then return end
    selected[key] = { bag = bag, slot = slot, itemID = info.itemID }
    count = count + 1
  end
  Repaint()
  Update()
end

local function OnClick(btn, mouse)
  if mouse ~= "LeftButton" or not IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then return end
  if not Enabled() then return end
  -- Auctionator's selling tab takes Alt+click on bag items while the auction house is open.
  if AuctionHouseFrame and AuctionHouseFrame:IsShown() then return end
  local bag, slot = Where(btn)
  if bag then Toggle(bag, slot) end
end

local function Track(btn, where)
  if buttons[btn] == nil then btn:HookScript("OnClick", OnClick) end
  if where or buttons[btn] == nil then buttons[btn] = where or true end
end

----------------------------------------------------------------------------------------------
-- Values

-- Copper for one stack: vendor, auction (after the cut), disenchant (after the cut).
local function Values(itemID, n, bound)
  local info = { (C_Item and C_Item.GetItemInfo or GetItemInfo)(itemID) }
  local sell = info[11]
  local vendor = (sell and sell > 0) and sell * n or nil
  local keep = ns.Keep()
  local ah = not bound and ns.Price(itemID)
  local auction = ah and ah * n * keep or nil
  local de = ns.DisenchantValue and ns.DisenchantValue(itemID)
  local disenchant = de and de * keep or nil
  return vendor, auction, disenchant
end

local function Totals()
  local t = { vendor = 0, auction = 0, disenchant = 0, best = 0, noAuction = 0, canDE = 0,
    bestBy = { vendor = 0, auction = 0, disenchant = 0 }, nothing = 0, items = 0 }
  for key, s in pairs(selected) do
    local info = ItemAt(s.bag, s.slot)
    if not info or info.itemID ~= s.itemID then
      selected[key] = nil -- moved, sold or used
      count = count - 1
    else
      t.items = t.items + 1
      local n = info.stackCount or 1
      local v, a, d = Values(s.itemID, n, info.isBound)
      t.vendor = t.vendor + (v or 0)
      if a then t.auction = t.auction + a else t.noAuction = t.noAuction + 1 end
      if d then t.disenchant = t.disenchant + d; t.canDE = t.canDE + 1 end
      local best, how = 0, nil
      for _, pair in ipairs({ { v, "vendor" }, { a, "auction" }, { d, "disenchant" } }) do
        if pair[1] and pair[1] > best then best, how = pair[1], pair[2] end
      end
      t.best = t.best + best
      if how then t.bestBy[how] = t.bestBy[how] + 1 else t.nothing = t.nothing + 1 end
    end
  end
  return t
end

----------------------------------------------------------------------------------------------
-- The window

local ROWS = { "vendor", "auction", "disenchant", "best" }

local function Build()
  ns.db = ns.db or ns.GeneralDB()
  local f = UI.Window({ name = "TooltipExtrasSelection", title = "Selected items", width = 400, height = 250 })
  local body = f.body
  f.summary = UI.Text(body, "", "GameFontHighlight")
  f.summary:SetPoint("TOPLEFT", 0, 0)
  f.rows = {}
  local y = -28
  for _, key in ipairs(ROWS) do
    local label = UI.Text(body, "", key == "best" and "GameFontNormal" or "GameFontHighlight")
    label:SetPoint("TOPLEFT", 0, y)
    local value = UI.Text(body, "", key == "best" and "GameFontNormal" or "GameFontHighlight")
    value:SetPoint("TOPRIGHT", 0, y)
    value:SetJustifyH("RIGHT")
    f.rows[key] = { label = label, value = value }
    y = y - 22
  end
  f.how = UI.Text(body, "", "GameFontDisableSmall")
  f.how:SetPoint("TOPLEFT", 0, y)
  f.how:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  f.how:SetWordWrap(true)
  f.hint = UI.Text(body, "|cffffd100Alt+click|r bag items to add or remove them.", "GameFontHighlightSmall")
  f.hint:SetPoint("BOTTOMLEFT", 0, 4)
  local clear = UI.Button(body, "Clear", 90, 22, function()
    Clear()
    Update()
  end)
  clear:SetPoint("BOTTOMRIGHT", 0, 0)
  f:HookScript("OnHide", Clear)
  -- Prices and stacks change while it's open (selling, stacking, a fresh scan).
  f:RegisterEvent("BAG_UPDATE_DELAYED")
  f:SetScript("OnEvent", function() Update() end)
  return f
end

local function Plural(n, word) return n .. " " .. word .. (n == 1 and "" or "s") end

function Update()
  if count <= 0 then
    count = 0
    if window and window:IsShown() then window:Hide() end
    return
  end
  window = window or Build()
  local t = Totals()
  if count <= 0 then
    window:Hide()
    return
  end
  Repaint()
  local cut = ns.Keep() < 1 and " |cff999999(after 5% cut)|r" or ""
  window.summary:SetText(Plural(t.items, "item") .. " selected")
  local r = window.rows
  r.vendor.label:SetText("All vendored")
  r.vendor.value:SetText(ns.Money(t.vendor))
  r.auction.label:SetText("All auctioned" .. cut
    .. (t.noAuction > 0 and (" |cff999999(" .. t.noAuction .. " no price or soulbound)|r") or ""))
  r.auction.value:SetText(ns.Money(t.auction))
  r.disenchant.label:SetText("All disenchanted" .. cut
    .. (t.canDE < t.items and (" |cff999999(" .. t.canDE .. " of " .. t.items .. " can)|r") or ""))
  r.disenchant.value:SetText(t.canDE > 0 and ns.Money(t.disenchant) or "|cff999999-|r")
  r.best.label:SetText("Each sold its best way")
  r.best.value:SetText(ns.Money(t.best))
  local parts = {}
  for _, how in ipairs({ "auction", "vendor", "disenchant" }) do
    local n = t.bestBy[how]
    if n > 0 then parts[#parts + 1] = n .. " " .. (how == "auction" and "auctioned" or how == "vendor" and "vendored" or "disenchanted") end
  end
  if t.nothing > 0 then parts[#parts + 1] = t.nothing .. " with no value" end
  window.how:SetText("Best way: " .. table.concat(parts, ", "))
  if not window:IsShown() then window:Show() end
end

----------------------------------------------------------------------------------------------
-- Finding the bag buttons

-- EllesmereUI Bags: called for every slot it paints, with { bag, slot, info }.
local function Paint(btn, data)
  if type(data) ~= "table" or not data.bag or not data.slot then return end
  Track(btn, { bag = data.bag, slot = data.slot })
  Mark(btn, selected[KeyOf(data.bag, data.slot)] ~= nil)
end

local hooker = CreateFrame("Frame")
hooker:RegisterEvent("PLAYER_LOGIN")
hooker:SetScript("OnEvent", function()
  if EUI_Bags and EUI_Bags.RegisterItemOverlayIcon then
    pcall(EUI_Bags.RegisterItemOverlayIcon, "TooltipExtras_Select", Paint)
  end
  -- Other bag addons: a container slot button is picked up when its tooltip shows.
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip)
      if tooltip ~= GameTooltip then return end
      local owner = tooltip:GetOwner()
      if owner and buttons[owner] == nil and owner.GetBagID and owner.HookScript then
        local ok, bag = pcall(owner.GetBagID, owner)
        if ok and type(bag) == "number" then Track(owner) end
      end
    end)
  end
end)
