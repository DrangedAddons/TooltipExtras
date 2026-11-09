-- Options > AddOns > TooltipExtras: a tick box per module, with its own options indented under it.
local ADDON, ns = ...

local panel = CreateFrame("Frame")
panel.name = "TooltipExtras"
local category
local checks = {}

local function Refresh()
  for _, cb in ipairs(checks) do
    local db = ns.ModuleDB(cb.module)
    if cb.option then
      cb:SetChecked(db[cb.option.key] and true or false)
      cb:SetEnabled(db.enabled)
      cb.label:SetTextColor(db.enabled and 1 or 0.5, db.enabled and 1 or 0.5, db.enabled and 1 or 0.5)
    else
      cb:SetChecked(db.enabled and true or false)
    end
  end
end

local function Check(x, y, label, tip, module, option)
  local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  cb:SetSize(26, 26)
  cb:SetPoint("TOPLEFT", x, y)
  cb.module, cb.option = module, option
  cb.label = cb:CreateFontString(nil, "OVERLAY", option and "GameFontHighlight" or "GameFontNormal")
  cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  cb.label:SetText(label)
  cb:SetScript("OnClick", function(self)
    local db = ns.ModuleDB(module)
    if option then db[option.key] = self:GetChecked() and true or false
    else db.enabled = self:GetChecked() and true or false end
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

local built = false
local function Build()
  if built then return end
  built = true
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("TooltipExtras |cff999999v" .. ((C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(ADDON, "Version") or "") .. "|r")
  local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  sub:SetText("Extra lines on item tooltips. Hover a box for what it adds.")
  local y = -64
  for _, m in ipairs(ns.modules) do
    Check(16, y, m.label, m.tip, m)
    y = y - 28
    for _, o in ipairs(m.options or {}) do
      Check(40, y, o.label, o.tip, m, o)
      y = y - 26
    end
    y = y - 8
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
