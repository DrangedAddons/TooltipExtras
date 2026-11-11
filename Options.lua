-- Options > AddOns > TooltipExtras: shared settings at the top, then a tick box per profession
-- (one per module) with that module's own options indented under it.
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

local function Heading(y, text, note)
  local h = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  h:SetPoint("TOPLEFT", 16, y)
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

  y = Heading(y, "Professions and events", "Tick the ones you want tooltip lines for.")
  local sorted = {}
  for _, m in ipairs(ns.modules) do sorted[#sorted + 1] = m end
  table.sort(sorted, function(a, b) return a.label < b.label end)
  for _, m in ipairs(sorted) do
    Check(16, y, m.label, m.tip,
      function() return ns.ModuleDB(m).enabled end,
      function(v) ns.ModuleDB(m).enabled = v end, true)
    y = y - 28
    for _, o in ipairs(m.options or {}) do
      Check(40, y, o.label, o.tip,
        function() return ns.ModuleDB(m)[o.key] end,
        function(v) ns.ModuleDB(m)[o.key] = v end, false,
        function() return ns.ModuleDB(m).enabled end)
      y = y - 26
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
