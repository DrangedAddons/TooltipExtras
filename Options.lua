-- Options > AddOns > TooltipExtras: shared settings at the top, then a tick box per module grouped
-- under category headings (Professions on the left; Events, Quests, Reputation on the right), with
-- each module's own options indented under it.
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

-- get() -> bool, set(bool); enabledIf() -> bool greys the box out when false.
local function Check(x, y, label, tip, get, set, isHeader, enabledIf)
  local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", x, y)
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

local function Heading(y, text, note, x)
  local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h:SetPoint("TOPLEFT", x or 16, y)
  h:SetText(text)
  if note then
    local n = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    n:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -4)
    n:SetText(note)
    return y - 44
  end
  return y - 28
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
  sub:SetText("Profit lines on item tooltips, with prices from Auctionator. Hover a box for what it adds.")

  local y = Heading(-72, "Prices")
  Check(16, y, "Take off the 5% auction house cut",
    "Profit counts the 5% the auction house keeps when you sell.",
    function() return ns.GeneralDB().ahCut end,
    function(v) ns.GeneralDB().ahCut = v end)
  y = y - 40

  -- Modules grouped by category: Professions down the left, the rest down the right.
  -- { key, heading, note, column }
  local CATEGORIES = {
    { "professions", "Professions", "Crafting profit on ore, cloth, leather, stone and essences.", 1 },
    { "events", "Events", "Darkmoon Faire turn-ins, ticket vendor and Sayge.", 2 },
    { "quests", "Quests", "Item turn-in quest costs.", 2 },
    { "reputation", "Reputation", "Cloth turn-ins to each standing.", 2 },
    { "other", "Other", nil, 2 },
  }
  local COLUMN_X = { 16, 340 }
  local top = y
  local colY = { top, top }
  for _, cat in ipairs(CATEGORIES) do
    local list = {}
    for _, m in ipairs(ns.modules) do
      if (m.category or "other") == cat[1] then list[#list + 1] = m end
    end
    if #list > 0 then
      table.sort(list, function(a, b) return a.label < b.label end)
      local col = cat[4]
      local x = COLUMN_X[col]
      local cy = Heading(colY[col], cat[2], cat[3], x)
      for _, m in ipairs(list) do
        Check(x, cy, m.label, m.tip,
          function() return ns.ModuleDB(m).enabled end,
          function(v) ns.ModuleDB(m).enabled = v end, true)
        cy = cy - 28
        for _, o in ipairs(m.options or {}) do
          Check(x + 24, cy, o.label, o.tip,
            function() return ns.ModuleDB(m)[o.key] end,
            function(v) ns.ModuleDB(m)[o.key] = v end, false,
            function() return ns.ModuleDB(m).enabled end)
          cy = cy - 26
        end
      end
      colY[col] = cy - 12
    end
  end
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
