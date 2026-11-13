-- Money columns that line up exactly. Tooltip text can't: digits differ in width, so the coins
-- drift, and a line only has a left and a right text. Instead the line's right text is an
-- invisible spacer of the right width, and an overlay draws one or more money columns over it.
-- Each column has gold, silver and copper in fixed-width slots (digits right-aligned inside)
-- with each coin icon at a fixed spot.
--
--   ns.MoneyLine(tooltip, leftText, { copper, ... }, { goldDigits, ... }, lr, lg, lb, r, g, b)
--   ns.MoneyHeader(tooltip, leftText, { label, ... }, { goldDigits, ... }, r, g, b)
--
-- One entry per column, left to right. goldDigits is the width of that column's gold slot in
-- digits; 0 leaves the slot out. Use the same goldDigits on every line that should line up.
-- A nil copper leaves that column blank.
local ADDON, ns = ...

local SPACER = "Interface\\AddOns\\TooltipExtras\\blank"
local ICONS = {
  "Interface\\MoneyFrame\\UI-GoldIcon",
  "Interface\\MoneyFrame\\UI-SilverIcon",
  "Interface\\MoneyFrame\\UI-CopperIcon",
}
local GAP, SEP, COLSEP = 2, 4, 14 -- digits to icon, icon to next slot, column to column

local measure
local function DigitWidth(font, size, flags)
  if not measure then
    measure = UIParent:CreateFontString(nil, "OVERLAY")
    measure:Hide()
  end
  measure:SetFont(font, size, flags)
  local w = 0
  for d = 0, 9 do
    measure:SetText(tostring(d))
    w = math.max(w, measure:GetStringWidth())
  end
  return math.ceil(w)
end

-- Font, slot widths per column and the total width for a set of columns.
local function Layout(goldDigits)
  local font, size, flags = GameTooltipText:GetFont()
  size = math.floor(size + 0.5)
  local dw = DigitWidth(font, size, flags)
  local cols, total = {}, 0
  for c, gd in ipairs(goldDigits) do
    local slots = { gd * dw, 2 * dw, 2 * dw }
    local first = gd > 0 and 1 or 2
    local w = 0
    for i = first, 3 do w = w + slots[i] + GAP + size + (i < 3 and SEP or 0) end
    cols[c] = { slots = slots, first = first, width = math.ceil(w) }
    total = total + cols[c].width + (c > 1 and COLSEP or 0)
  end
  return { font = font, size = size, flags = flags, cols = cols, total = total }
end

local pools = {} -- tooltip -> { overlay frames }

local function ReleaseAll(tooltip)
  for _, o in ipairs(pools[tooltip] or {}) do
    o:Hide()
    o.used = false
  end
end

local function Overlay(tooltip)
  local pool = pools[tooltip]
  if not pool then
    pool = {}
    pools[tooltip] = pool
    tooltip:HookScript("OnHide", ReleaseAll)
    if tooltip:HasScript("OnTooltipCleared") then tooltip:HookScript("OnTooltipCleared", ReleaseAll) end
  end
  for _, o in ipairs(pool) do
    if not o.used then
      o.used = true
      return o
    end
  end
  local o = CreateFrame("Frame", nil, tooltip)
  o.cols = {}
  o.used = true
  pool[#pool + 1] = o
  return o
end

-- The widgets for column c of an overlay, made on first use.
local function Column(o, c)
  local col = o.cols[c]
  if not col then
    col = { anchor = CreateFrame("Frame", nil, o), text = {}, icon = {} }
    for i = 1, 3 do
      col.text[i] = o:CreateFontString(nil, "OVERLAY")
      col.text[i]:SetJustifyH("RIGHT")
      col.icon[i] = o:CreateTexture(nil, "OVERLAY")
      col.icon[i]:SetTexture(ICONS[i])
    end
    col.label = o:CreateFontString(nil, "OVERLAY")
    col.label:SetJustifyH("RIGHT")
    o.cols[c] = col
  end
  return col
end

-- Adds the line with a spacer and returns its overlay, with each column's anchor frame placed
-- (right to left from the line's right edge) and everything in it hidden.
local function PlaceLine(tooltip, left, L, lr, lg, lb)
  tooltip:AddDoubleLine(left, "|T" .. SPACER .. ":" .. L.size .. ":" .. L.total .. "|t", lr, lg, lb, 1, 1, 1)
  local right = tooltip:GetName() and _G[tooltip:GetName() .. "TextRight" .. tooltip:NumLines()]
  if not right then return nil end
  local o = Overlay(tooltip)
  o:ClearAllPoints()
  o:SetPoint("RIGHT", right, "RIGHT", 0, 0)
  o:SetSize(L.total, L.size)
  for _, col in pairs(o.cols) do
    col.anchor:Hide()
    col.label:Hide()
    for i = 1, 3 do
      col.text[i]:Hide()
      col.icon[i]:Hide()
    end
  end
  local x = 0
  for c = #L.cols, 1, -1 do
    local col = Column(o, c)
    col.anchor:ClearAllPoints()
    col.anchor:SetPoint("RIGHT", o, "RIGHT", -x, 0)
    col.anchor:SetSize(L.cols[c].width, L.size)
    x = x + L.cols[c].width + COLSEP
  end
  o:Show()
  return o
end

function ns.MoneyLine(tooltip, left, amounts, goldDigits, lr, lg, lb, r, g, b)
  local L = Layout(goldDigits)
  local o = PlaceLine(tooltip, left, L, lr, lg, lb)
  if not o then return end
  for c, spec in ipairs(L.cols) do
    local col = o.cols[c]
    local copper = amounts[c]
    if copper then
      copper = math.max(0, math.floor(copper + 0.5))
      local parts = { math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100 }
      -- The biggest coin with a value leads: coins above it are left blank (slot kept, so the
      -- column stays put) and it isn't zero-padded. Coins below it show two digits.
      local lead = parts[1] > 0 and 1 or (parts[2] > 0 and 2 or 3)
      local anchor, point, offset = col.anchor, "RIGHT", 0
      for i = 3, spec.first, -1 do
        local t, icon = col.text[i], col.icon[i]
        icon:ClearAllPoints()
        icon:SetSize(L.size, L.size)
        icon:SetPoint("RIGHT", anchor, point, offset, 0)
        t:ClearAllPoints()
        t:SetFont(L.font, L.size, L.flags)
        t:SetWidth(spec.slots[i])
        t:SetPoint("RIGHT", icon, "LEFT", -GAP, 0)
        t:SetText(i == lead and tostring(parts[i]) or string.format("%02d", parts[i]))
        t:SetTextColor(r, g, b)
        t:SetShown(i >= lead)
        icon:SetShown(i >= lead)
        anchor, point, offset = t, "LEFT", -SEP
      end
    end
  end
end

-- Text columns on the same overlay: each column is as wide as the widest of its sample strings
-- and its text is right-aligned in it, so values line up down the tooltip. Pass the same
-- samples on every line that should line up.
--   ns.TextLine(tooltip, left, { text, ... }, { { sample, ... }, ... }, lr, lg, lb, { {r,g,b}, ... })
local function TextLayout(samples)
  local font, size, flags = GameTooltipText:GetFont()
  size = math.floor(size + 0.5)
  if not measure then
    measure = UIParent:CreateFontString(nil, "OVERLAY")
    measure:Hide()
  end
  measure:SetFont(font, size, flags)
  local cols, total = {}, 0
  for c, list in ipairs(samples) do
    local w = 0
    for _, s in ipairs(list) do
      measure:SetText(s)
      w = math.max(w, measure:GetStringWidth())
    end
    cols[c] = { width = math.ceil(w) + 1 }
    total = total + cols[c].width + (c > 1 and COLSEP or 0)
  end
  return { font = font, size = size, flags = flags, cols = cols, total = total }
end

function ns.TextLine(tooltip, left, texts, samples, lr, lg, lb, colors)
  local L = TextLayout(samples)
  local o = PlaceLine(tooltip, left, L, lr, lg, lb)
  if not o then return end
  for c in ipairs(L.cols) do
    local label = o.cols[c].label
    local color = colors and colors[c] or { 1, 1, 1 }
    label:ClearAllPoints()
    label:SetFont(L.font, L.size, L.flags)
    label:SetPoint("RIGHT", o.cols[c].anchor, "RIGHT", 0, 0)
    label:SetText(texts[c] or "")
    label:SetTextColor(color[1], color[2], color[3])
    label:Show()
  end
end

function ns.MoneyHeader(tooltip, left, labels, goldDigits, r, g, b)
  local L = Layout(goldDigits)
  local o = PlaceLine(tooltip, left, L, r, g, b)
  if not o then return end
  for c in ipairs(L.cols) do
    local label = o.cols[c].label
    label:ClearAllPoints()
    label:SetFont(L.font, L.size, L.flags)
    label:SetPoint("RIGHT", o.cols[c].anchor, "RIGHT", 0, 0)
    label:SetText(labels[c] or "")
    label:SetTextColor(r, g, b)
    label:Show()
  end
end
