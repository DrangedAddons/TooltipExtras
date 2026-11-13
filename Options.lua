-- Options > AddOns > TooltipExtras: shared settings at the top, then the modules grouped under
-- category headings (Professions on the left; Events, Quests, Reputation on the right). Each
-- module row has a tick box to turn it all on or off and a +/- to show its features, each with
-- its own tick box. Which rows are open is remembered.
local ADDON, ns = ...

local panel = CreateFrame("Frame")
panel.name = "TooltipExtras"
local category
local checks = {}

local function Refresh()
  for _, cb in ipairs(checks) do
    cb:SetChecked(cb.get() and true or false)
    local on = not cb.enabledIf or cb.enabledIf()
    cb:SetEnabled(on)
    local c = on and 1 or 0.5
    if cb.isHeader then cb.label:SetTextColor(c, 0.82 * c, 0) else cb.label:SetTextColor(c, c, c) end
  end
end

-- get() -> bool, set(bool); enabledIf() -> bool greys the box out when false. Placed by Layout.
local function Check(label, tip, get, set, isHeader, enabledIf)
  local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb.get, cb.enabledIf, cb.isHeader = get, enabledIf, isHeader
  cb.label = cb:CreateFontString(nil, "OVERLAY", isHeader and "GameFontNormal" or "GameFontHighlight")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  cb.label:SetText(label)
  cb:SetScript("OnClick", function(self)
    set(self:GetChecked() and true or false)
    Refresh()
  end)
  if tip then
    cb:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(label)
      GameTooltip:AddLine(tip, 1, 1, 1, true)
      GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", GameTooltip_Hide)
  end
  checks[#checks + 1] = cb
  return cb
end

local function Heading(text, note)
  local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h:SetText(text)
  if note then
    h.note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    h.note:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
    h.note:SetText(note)
  end
  return h
end

local function Expanded()
  local g = ns.GeneralDB()
  g.expanded = type(g.expanded) == "table" and g.expanded or {}
  return g.expanded
end

-- { key, heading, note, column }
local CATEGORIES = {
  { "professions", "Professions", "Crafting profit on ore, cloth, leather, stone and essences.", 1 },
  { "events", "Events", "Darkmoon Faire turn-ins, ticket vendor and Sayge.", 2 },
  { "quests", "Quests", "Item turn-in quest costs.", 2 },
  { "reputation", "Reputation", "Cloth turn-ins to each standing.", 2 },
  { "other", "Other", nil, 2 },
}
local COLUMN_X = { 16, 340 }
local EXPAND_W = 18 -- room for the +/- left of a module's tick box

-- Per column, the rows in order: { kind = "heading" | "module" | "option", widget, module }
local columns = { {}, {} }
local columnTop

local function Layout()
  local open = Expanded()
  for c, rows in ipairs(columns) do
    local x, y = COLUMN_X[c], columnTop
    for _, row in ipairs(rows) do
      local w = row.widget
      if row.kind == "heading" then
        if row.gap then y = y - 12 end
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", x, y)
        y = y - (w.note and 44 or 28)
      elseif row.kind == "module" then
        local isOpen = open[row.module.key]
        w:ClearAllPoints()
        w:SetPoint("TOPLEFT", x + EXPAND_W, y)
        if row.expander then
          row.expander:ClearAllPoints()
          row.expander:SetPoint("RIGHT", w, "LEFT", -2, 0)
          row.expander:SetNormalTexture(isOpen and "Interface\\Buttons\\UI-MinusButton-Up"
            or "Interface\\Buttons\\UI-PlusButton-Up")
        end
        y = y - 28
      else -- option
        if open[row.module.key] then
          w:ClearAllPoints()
          w:SetPoint("TOPLEFT", x + EXPAND_W + 24, y)
          w:Show()
          y = y - 26
        else
          w:Hide()
        end
      end
    end
  end
end

local built = false
local function Build()
  if built then return end
  built = true
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("TooltipExtras |cff999999v" .. ((C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or "") .. "|r")
  local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Profit lines on item tooltips, with prices from Auctionator. Hover a box for what it adds; + shows its parts.")

  local prices = Heading("Prices")
  prices:SetPoint("TOPLEFT", 16, -72)
  local cut = Check("Take off the 5% auction house cut",
    "Profit counts the 5% the auction house keeps when you sell.",
    function() return ns.GeneralDB().ahCut end,
    function(v) ns.GeneralDB().ahCut = v end)
  cut:SetPoint("TOPLEFT", 16, -100)
  columnTop = -140

  for _, cat in ipairs(CATEGORIES) do
    local list = {}
    for _, m in ipairs(ns.modules) do
      if (m.category or "other") == cat[1] then list[#list + 1] = m end
    end
    if #list > 0 then
      table.sort(list, function(a, b) return a.label < b.label end)
      local rows = columns[cat[4]]
      rows[#rows + 1] = { kind = "heading", widget = Heading(cat[2], cat[3]), gap = #rows > 0 }
      for _, m in ipairs(list) do
        local row = { kind = "module", module = m }
        row.widget = Check(m.label, m.tip,
          function() return ns.ModuleDB(m).enabled end,
          function(v) ns.ModuleDB(m).enabled = v end, true)
        if m.options and #m.options > 0 then
          local b = CreateFrame("Button", nil, panel)
          b:SetSize(14, 14)
          b:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
          b:SetScript("OnClick", function()
            local open = Expanded()
            open[m.key] = not open[m.key] or nil
            Layout()
          end)
          row.expander = b
        end
        rows[#rows + 1] = row
        for _, o in ipairs(m.options or {}) do
          rows[#rows + 1] = { kind = "option", module = m, widget = Check(o.label, o.tip,
            function() return ns.ModuleDB(m)[o.key] end,
            function(v) ns.ModuleDB(m)[o.key] = v end, false,
            function() return ns.ModuleDB(m).enabled end) }
        end
      end
    end
  end
  Layout()
end

panel:SetScript("OnShow", function()
  Build()
  Refresh()
end)

if Settings and Settings.RegisterCanvasLayoutCategory then
  category = Settings.RegisterCanvasLayoutCategory(panel, "TooltipExtras")
  Settings.RegisterAddOnCategory(category)
elseif InterfaceOptions_AddCategory then
  InterfaceOptions_AddCategory(panel)
end

function ns.OpenOptions()
  if category and Settings and Settings.OpenToCategory then
    Settings.OpenToCategory(category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory then
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
  end
end
