-- Bag item totals: Alt+click items in your bags or bank to mark them, and a small window adds up what the
-- marked items are worth: all vendored, all auctioned, all disenchanted, and each sold its best
-- way (the same rule as the green highlight in Disenchant.lua). Alt+click a marked item again
-- to unmark it; hold the button after Alt+clicking and move over more items to mark (or unmark)
-- them all. Clear or closing the window unmarks everything.
--
-- Bag buttons: EllesmereUI Bags paints its slots through EUI_Bags.RegisterItemOverlayIcon,
-- which tells us each button's bag and slot whenever it redraws, so the marks follow the items.
-- Any other bag addon (Baganator, Blizzard's bags) works through the item tooltip: a slot button
-- is picked up the first time you hover it.
--
-- Marks are kept by bag and slot, with the item ID, and dropped when that slot's item changes.
-- Bank slots can only be read while the bank is open, so bank marks drop when it closes.
local ADDON, ns = ...
local UI = ns.UI
ns.Print = ns.Print or function(...) print("|cff33ff99TooltipExtras|r:", ...) end

local MODULE = {
  key = "selecttotals",
  category = "other",
  label = "Bag item totals",
  tip = "Alt+click items in your bags or bank to mark them, or Alt+click and drag over several. "
    .. "A window adds up what they're worth: "
    .. "vendored, auctioned, disenchanted, and each sold its best way.",
  options = { { key = "select", label = "Alt+click bag and bank items to total them", default = true } },
}
ns.AddModule(MODULE)

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

-- Marks (add = true) or unmarks (add = false) one slot; true when that changed anything.
local function Set(bag, slot, add)
  local key = KeyOf(bag, slot)
  if add and not selected[key] then
    local info = ItemAt(bag, slot)
    if not info then return false end
    selected[key] = { bag = bag, slot = slot, itemID = info.itemID }
    count = count + 1
    return true
  elseif not add and selected[key] then
    selected[key] = nil
    count = count - 1
    return true
  end
  return false
end

local function Toggle(bag, slot)
  if Set(bag, slot, not selected[KeyOf(bag, slot)]) then
    Repaint()
    Update()
  end
end

-- Alt + press on a slot marks it, or unmarks it if it was marked. Keep the button held and move
-- over other slots to do the same to each (the first slot decides mark or unmark). It works on
-- the press, so letting go doesn't toggle the first slot back. Moving with the button held
-- would pick the item up, so the cursor is cleared while painting.
local painting -- { add = bool, done = { key = true } } while the button is held
local painter = CreateFrame("Frame")
painter:Hide()

local function StopPainting()
  painting = nil
  painter:Hide()
  painter:UnregisterEvent("CURSOR_CHANGED")
end

local function MouseOver()
  if GetMouseFoci then return (GetMouseFoci())[1] end
  return GetMouseFocus and GetMouseFocus()
end

painter:SetScript("OnUpdate", function()
  if not painting or not IsMouseButtonDown("LeftButton") then
    StopPainting()
    return
  end
  local btn = MouseOver()
  if not btn or buttons[btn] == nil then return end
  local bag, slot = Where(btn)
  if not bag then return end
  local key = KeyOf(bag, slot)
  if painting.done[key] then return end
  painting.done[key] = true
  if Set(bag, slot, painting.add) then
    Repaint()
    Update()
  end
end)

painter:SetScript("OnEvent", function()
  -- the press started a drag of the item: put it back
  if painting and GetCursorInfo() then ClearCursor() end
end)

local function OnMouseDown(btn, mouse)
  if mouse ~= "LeftButton" or not IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then return end
  if not Enabled() then return end
  -- Auctionator's selling tab takes Alt+click on bag items while the auction house is open.
  if AuctionHouseFrame and AuctionHouseFrame:IsShown() then return end
  local bag, slot = Where(btn)
  if not bag then return end
  local key = KeyOf(bag, slot)
  painting = { add = not selected[key], done = { [key] = true } }
  painter:RegisterEvent("CURSOR_CHANGED")
  painter:Show()
  Toggle(bag, slot)
end

local function Track(btn, where)
  if buttons[btn] == nil then btn:HookScript("OnMouseDown", OnMouseDown) end
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
    bestBy = { vendor = 0, auction = 0, disenchant = 0 }, nothing = 0, items = 0, list = {} }
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
      t.list[#t.list + 1] = { key = key, bag = s.bag, slot = s.slot, itemID = s.itemID, n = n,
        icon = info.iconFileName, quality = info.quality, link = info.hyperlink, bound = info.isBound,
        vendor = v, auction = a, disenchant = d, best = best, how = how }
    end
  end
  table.sort(t.list, function(a, b)
    if a.best ~= b.best then return a.best > b.best end
    return a.key < b.key
  end)
  return t
end

----------------------------------------------------------------------------------------------
-- The window: a list with an item column and Vendor / Auction / Disenchant columns, each row's
-- best value in green, and a Total row in the same columns.

local LIST_ROWS = 12
local ROW_H = 20
local COLS = { "vendor", "auction", "disenchant" }
local HEAD = { vendor = "Vendor", auction = "Auction", disenchant = "Disenchant" }
local COL_W, COL_GAP = 104, 8
local BEST = "|cff33ff33"
local DASH = "|cff666666-|r"

-- Right edge of column c (1 = Vendor) from the right edge of a list row.
local function ColX(c) return -6 - (#COLS - c) * (COL_W + COL_GAP) end

local function Cell(parent, font)
  local fs = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlight")
  fs:SetWidth(COL_W)
  fs:SetJustifyH("RIGHT")
  fs:SetWordWrap(false)
  return fs
end

local function Amount(v, best)
  if not v then return DASH end
  local text = ns.Money(v)
  return best and (BEST .. text:gsub("|r", "|r" .. BEST) .. "|r") or text
end

local function RowEnter(row)
  local item = row.item
  if not item then return end
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  if GameTooltip.SetBagItem then
    GameTooltip:SetBagItem(item.bag, item.slot)
  elseif item.link then
    GameTooltip:SetHyperlink(item.link)
  end
  GameTooltip:Show()
end

local function RenderRow(row, item)
  if not row.tteCells then
    row.tteCells = {}
    for c, key in ipairs(COLS) do
      local fs = Cell(row)
      fs:SetPoint("RIGHT", row, "RIGHT", ColX(c), 0)
      row.tteCells[key] = fs
    end
    row.text:ClearAllPoints()
    row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.text:SetPoint("RIGHT", row.tteCells.vendor, "LEFT", -8, 0)
    row:SetScript("OnEnter", RowEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
  end
  local name = ns.ItemName(item.itemID) or ("item " .. item.itemID)
  local color = item.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[item.quality]
  if color and color.hex then name = color.hex .. name .. "|r" end
  UI.RenderRow(row, name .. (item.n > 1 and (" |cff999999x" .. item.n .. "|r") or ""), item.icon)
  for _, key in ipairs(COLS) do
    local text = Amount(item[key], item.how == key)
    if key == "auction" and not item.auction and item.bound then text = "|cff666666bound|r" end
    row.tteCells[key]:SetText(text)
  end
end

local function Build()
  ns.db = ns.db or ns.GeneralDB()
  local f = UI.Window({ name = "TooltipExtrasSelection", title = "Selected items", width = 620, height = 500 })
  local body = f.body
  f.summary = UI.Text(body, "", "GameFontHighlight")
  f.summary:SetPoint("TOPLEFT", 0, 0)

  -- column headings, lined up with the row cells (rows end 10px inside the list)
  local head = CreateFrame("Frame", nil, body)
  head:SetHeight(ROW_H)
  head:SetPoint("TOPLEFT", 0, -22)
  head:SetPoint("RIGHT", body, "RIGHT", -10, 0)
  local itemHead = UI.Text(head, "Item", "GameFontNormal")
  itemHead:SetPoint("LEFT", 4, 0)
  for c, key in ipairs(COLS) do
    local fs = Cell(head, "GameFontNormal")
    fs:SetPoint("RIGHT", head, "RIGHT", ColX(c), 0)
    fs:SetText(HEAD[key])
  end

  f.list = UI.List(body, 580, ROW_H, LIST_ROWS, RenderRow, function(_, item, mouse)
    if mouse == "RightButton" then
      GameTooltip:Hide()
      Toggle(item.bag, item.slot)
    end
  end)
  f.list:SetPoint("TOPLEFT", 0, -22 - ROW_H)
  f.list:SetPoint("RIGHT", body, "RIGHT", 0, 0)

  -- Total row in the same columns
  local total = CreateFrame("Frame", nil, body)
  total:SetHeight(ROW_H)
  total:SetPoint("TOPLEFT", f.list, "BOTTOMLEFT", 0, -4)
  total:SetPoint("RIGHT", body, "RIGHT", -10, 0)
  local totalLabel = UI.Text(total, "Total", "GameFontNormal")
  totalLabel:SetPoint("LEFT", 4, 0)
  f.totals = {}
  for c, key in ipairs(COLS) do
    local fs = Cell(total)
    fs:SetPoint("RIGHT", total, "RIGHT", ColX(c), 0)
    f.totals[key] = fs
  end
  f.notes = UI.Text(body, "", "GameFontDisableSmall")
  f.notes:SetPoint("TOPLEFT", total, "BOTTOMLEFT", 4, -2)
  f.notes:SetPoint("RIGHT", body, "RIGHT", -10, 0)
  f.notes:SetWordWrap(true)

  f.best = UI.Text(body, "", "GameFontNormal")
  f.best:SetPoint("TOPLEFT", f.notes, "BOTTOMLEFT", 0, -10)
  f.bestValue = UI.Text(body, "", "GameFontNormal")
  f.bestValue:SetPoint("TOP", f.best, "TOP", 0, 0)
  f.bestValue:SetPoint("RIGHT", total, "RIGHT", ColX(#COLS), 0)
  f.bestValue:SetJustifyH("RIGHT")
  f.how = UI.Text(body, "", "GameFontDisableSmall")
  f.how:SetPoint("TOPLEFT", f.best, "BOTTOMLEFT", 0, -4)

  f.hint = UI.Text(body, "|cffffd100Alt+click|r bag or bank items to add or remove them (hold and drag "
    .. "over more), |cffffd100right-click|r a row to remove it.", "GameFontHighlightSmall")
  f.hint:SetPoint("BOTTOMLEFT", 0, 4)
  local clear = UI.Button(body, "Clear", 90, 22, function()
    Clear()
    Update()
  end)
  clear:SetPoint("BOTTOMRIGHT", 0, 0)
  f:HookScript("OnHide", Clear)
  -- Prices and stacks change while it's open (selling, stacking, a fresh scan).
  f:RegisterEvent("BAG_UPDATE_DELAYED")
  -- bank slots change and become unreadable without a BAG_UPDATE_DELAYED
  for _, e in ipairs({ "PLAYERBANKSLOTS_CHANGED", "BANKFRAME_CLOSED" }) do pcall(f.RegisterEvent, f, e) end
  f:SetScript("OnEvent", function(_, event)
    if event == "BANKFRAME_CLOSED" then C_Timer.After(0, Update) else Update() end
  end)
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
  window.summary:SetText(Plural(t.items, "item") .. " selected, best value first. "
    .. BEST .. "Green|r is each item's best way to sell.")
  window.list:SetData(t.list)
  window.totals.vendor:SetText(Amount(t.vendor))
  window.totals.auction:SetText(Amount(t.auction))
  window.totals.disenchant:SetText(t.canDE > 0 and Amount(t.disenchant) or DASH)
  local notes = {}
  if ns.Keep() < 1 then notes[#notes + 1] = "Auction and disenchant are after the 5% auction house cut." end
  if t.noAuction > 0 then notes[#notes + 1] = t.noAuction .. " with no auction price or soulbound." end
  if t.canDE < t.items then notes[#notes + 1] = t.canDE .. " of " .. t.items .. " can be disenchanted." end
  window.notes:SetText(table.concat(notes, " "))
  window.best:SetText("Each sold its best way")
  window.bestValue:SetText(Amount(t.best))
  local parts = {}
  for _, how in ipairs({ "auction", "vendor", "disenchant" }) do
    local n = t.bestBy[how]
    if n > 0 then parts[#parts + 1] = n .. " " .. (how == "auction" and "auctioned" or how == "vendor" and "vendored" or "disenchanted") end
  end
  if t.nothing > 0 then parts[#parts + 1] = t.nothing .. " with no value" end
  window.how:SetText(table.concat(parts, ", "))
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
