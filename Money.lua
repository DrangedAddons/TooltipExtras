-- Money in a column that lines up exactly. Tooltip text can't: digits differ in width, so the
-- coins drift. Instead the line's right text is an invisible spacer of the right width, and an
-- overlay draws gold, silver and copper in fixed-width slots (digits right-aligned inside) with
-- each coin icon at a fixed spot.
--
--   ns.MoneyLine(tooltip, leftText, copper, goldDigits, lr, lg, lb, r, g, b)
--
-- goldDigits is the width of the gold slot in digits, the same for every line that should line
-- up; 0 leaves the gold slot out.
local ADDON, ns = ...

local SPACER = "Interface\\AddOns\\TooltipExtras\\blank"
local ICONS = {
  "Interface\\MoneyFrame\\UI-GoldIcon",
  "Interface\\MoneyFrame\\UI-SilverIcon",
  "Interface\\MoneyFrame\\UI-CopperIcon",
}
local GAP, SEP = 2, 4 -- digits to icon, icon to next slot

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
  o.text, o.icon = {}, {}
  for i = 1, 3 do
    o.text[i] = o:CreateFontString(nil, "OVERLAY")
    o.text[i]:SetJustifyH("RIGHT")
    o.icon[i] = o:CreateTexture(nil, "OVERLAY")
    o.icon[i]:SetTexture(ICONS[i])
  end
  o.used = true
  pool[#pool + 1] = o
  return o
end

function ns.MoneyLine(tooltip, left, copper, goldDigits, lr, lg, lb, r, g, b)
  local font, size, flags = GameTooltipText:GetFont()
  size = math.floor(size + 0.5)
  local dw = DigitWidth(font, size, flags)
  local slots = { goldDigits * dw, 2 * dw, 2 * dw }
  local first = goldDigits > 0 and 1 or 2
  local total = 0
  for i = first, 3 do total = total + slots[i] + GAP + size + (i < 3 and SEP or 0) end
  total = math.ceil(total)

  tooltip:AddDoubleLine(left, "|T" .. SPACER .. ":" .. size .. ":" .. total .. "|t", lr, lg, lb, 1, 1, 1)
  local right = tooltip:GetName() and _G[tooltip:GetName() .. "TextRight" .. tooltip:NumLines()]
  if not right then return end

  copper = math.max(0, math.floor((copper or 0) + 0.5))
  local amounts = { math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100 }
  -- The biggest coin with a value leads: coins above it are left blank (slot kept, so the
  -- column stays put) and it isn't zero-padded. Coins below it show two digits.
  local lead = amounts[1] > 0 and 1 or (amounts[2] > 0 and 2 or 3)
  local values = {}
  for i = 1, 3 do
    values[i] = i == lead and tostring(amounts[i]) or string.format("%02d", amounts[i])
  end

  local o = Overlay(tooltip)
  o:ClearAllPoints()
  o:SetPoint("RIGHT", right, "RIGHT", 0, 0)
  o:SetSize(total, size)
  -- right to left: copper icon at the right edge, then its digits, then silver, then gold
  local anchor, point = o, "RIGHT"
  for i = 3, 1, -1 do
    local t, icon = o.text[i], o.icon[i]
    if i >= first then
      icon:ClearAllPoints()
      icon:SetSize(size, size)
      icon:SetPoint("RIGHT", anchor, point, anchor == o and 0 or -SEP, 0)
      t:ClearAllPoints()
      t:SetFont(font, size, flags)
      t:SetWidth(slots[i])
      t:SetPoint("RIGHT", icon, "LEFT", -GAP, 0)
      t:SetText(values[i])
      t:SetTextColor(r, g, b)
      t:SetShown(i >= lead)
      icon:SetShown(i >= lead)
      anchor, point = t, "LEFT"
    else
      t:Hide()
      icon:Hide()
    end
  end
  o:Show()
end
