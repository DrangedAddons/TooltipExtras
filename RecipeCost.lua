-- Recipe links in chat (clicked, or hovered via ChatHover.lua), every profession: swaps the tooltip's "Reagents:" line for a priced list, one
-- row per reagent with the price each and the cost for the recipe's count, then the total.
-- Prices are the cheaper of AH and vendor (ns.BuyPrice). Reagents you don't have enough of are
-- red.
--
-- It reads the names and counts off the "Reagents:" line itself and maps the names to item IDs
-- with RecipeData.lua, so it works on any linked recipe
-- without knowing the spell. A line pre-call draws the list in the line's place and skips the
-- line. If a name isn't known, the default line is left alone.
local ADDON, ns = ...

local MODULE = {
  key = "recipecost",
  category = "professions",
  subcategory = "All professions", -- not a profession itself, so its own group in settings
  subnote = "Works on every profession's recipes.",
  label = "Recipe reagents",
  tip = "On a recipe linked in chat, for every profession: the Reagents line "
    .. "becomes a priced list, each reagent's price and cost, and the total.",
  options = { { key = "list", label = "Priced reagent list", default = true } },
}
ns.AddModule(MODULE)

local byName -- lower-case reagent name -> item ID
local function ItemByName(name)
  if not byName then
    byName = {}
    for id, n in pairs(ns.RecipeReagents or {}) do byName[n:lower()] = id end
  end
  return byName[name:lower()]
end

-- "Reagents:" from the client's own format string ("Reagents: |n%s" or similar): everything up
-- to and including the first colon.
local PREFIX = (type(SPELL_REAGENTS) == "string" and SPELL_REAGENTS:match("^([^:]+:)")) or "Reagents:"

-- Strips colour codes and turns the "|n" line-break escape (Forever's "Reagents: |n<list>")
-- into a real newline.
local function Plain(text)
  return (text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n"))
end

-- "Soul Dust (8), Large Glimmering Shard (6)" -> { { id, count, name }, ... }, or nil when any
-- name isn't an enchanting reagent we know.
local function Parse(list)
  local out = {}
  for piece in list:gmatch("[^,\n]+") do
    piece = piece:match("^%s*(.-)%s*$")
    if piece ~= "" then
      local name, n = piece:match("^(.-)%s*%((%d+)%)$")
      name, n = name or piece, tonumber(n) or 1
      local id = ItemByName(name)
      if not id then return nil end
      out[#out + 1] = { id, n, name }
    end
  end
  return #out > 0 and out or nil
end

local function Have(id)
  return (GetItemCount and GetItemCount(id, true)) or (C_Item and C_Item.GetItemCount and C_Item.GetItemCount(id, true)) or 0
end

local function GoldDigits(copper)
  local g = math.floor((copper or 0) / 10000)
  return g > 0 and #tostring(g) or 0
end

-- The priced list, added at the tooltip's current line.
-- 1px gold rules in the gaps above and below tooltip line n, from its left text to its right
-- text. They add no lines, so the rows keep their spacing. Hidden when the tooltip clears.
local rules = {}
local function Rule(tooltip, n)
  local name = tooltip:GetName()
  local left = name and _G[name .. "TextLeft" .. n]
  local right = name and _G[name .. "TextRight" .. n]
  if not left or not right then return end
  local pair = rules[tooltip]
  if not pair then
    pair = {}
    for i = 1, 2 do
      pair[i] = tooltip:CreateTexture(nil, "ARTWORK")
      pair[i]:SetColorTexture(1, 0.82, 0, 0.6)
    end
    rules[tooltip] = pair
    local hide = function() pair[1]:Hide() pair[2]:Hide() end
    tooltip:HookScript("OnHide", hide)
    if tooltip:HasScript("OnTooltipCleared") then tooltip:HookScript("OnTooltipCleared", hide) end
  end
  local above, below = pair[1], pair[2]
  above:ClearAllPoints()
  above:SetPoint("BOTTOMLEFT", left, "TOPLEFT", 0, 1)
  above:SetPoint("BOTTOMRIGHT", right, "TOPRIGHT", 0, 1)
  below:ClearAllPoints()
  below:SetPoint("TOPLEFT", left, "BOTTOMLEFT", 0, -1)
  below:SetPoint("TOPRIGHT", right, "BOTTOMRIGHT", 0, -1)
  for _, tex in ipairs(pair) do
    tex:SetHeight(1)
    tex:Show()
  end
end

local function Draw(tooltip, reagents)
  local rows, total, missing, widest = {}, 0, false, 0
  for i, r in ipairs(reagents) do
    local each = ns.BuyPrice(r[1])
    local cost = each and each * r[2]
    if cost then total = total + cost else missing = true end
    widest = math.max(widest, cost or 0)
    rows[i] = { r, each, cost }
  end
  widest = math.max(widest, total)
  local digits = { GoldDigits(widest) }

  -- One aligned cost column; the price each goes after the name in grey, e.g.
  -- "8 x Soul Dust (4s 47c)".
  ns.MoneyHeader(tooltip, PREFIX, { "cost" }, digits, 1, 0.82, 0)
  for _, row in ipairs(rows) do
    local r, each, cost = row[1], row[2], row[3]
    local lr, lg, lb = 0.9, 0.9, 0.9
    if Have(r[1]) < r[2] then lr, lg, lb = 1, 0.13, 0.13 end
    local left = "  " .. r[2] .. " x " .. r[3]
    if each then
      ns.MoneyLine(tooltip, left .. " |cff999999(" .. ns.Money(each) .. ")|r", { cost }, digits,
        lr, lg, lb, 1, 1, 1)
    else
      tooltip:AddDoubleLine(left, "no price", lr, lg, lb, 0.5, 0.5, 0.5)
    end
  end
  ns.MoneyLine(tooltip, missing and "  Total (prices missing)" or "  Total", { total }, digits,
    1, 0.82, 0, 1, 1, 1)
  Rule(tooltip, tooltip:NumLines())
  tooltip:AddLine(" ") -- gap before the effect text
end

local function Enabled()
  local db = ns.ModuleDB(MODULE)
  return db.enabled and db.list ~= false
end

local function OurTooltip(tooltip)
  -- chat links only (clicked, or hovered with the Chat links module), not bag or
  -- profession-window hovers
  return tooltip == ItemRefTooltip or (ns.IsChatHover and ns.IsChatHover(tooltip))
end

-- tooltip -> true while the line after a bare "Reagents:" header should hold the list
local pending = {}

-- Returns true to skip the game's own line.
local function OnLine(tooltip, line)
  if not OurTooltip(tooltip) or not line or type(line.leftText) ~= "string" then return end
  if tooltip.IsForbidden and tooltip:IsForbidden() then return end
  local text = Plain(line.leftText)
  local list
  if pending[tooltip] then
    pending[tooltip] = nil
    list = Parse(text)
    if list and Enabled() then
      Draw(tooltip, list)
      return true
    end
    tooltip:AddLine(PREFIX, 1, 1, 1) -- put back the header we skipped
    return
  end
  local rest = text:match("^" .. PREFIX:gsub("%p", "%%%0") .. "%s*(.*)$")
  if not rest then return end
  ns.Debug("reagent line found, enabled:", Enabled(), "list:", rest:sub(1, 40))
  if not Enabled() then return end
  if rest == "" then
    pending[tooltip] = true -- the list is on the next line
    return true
  end
  list = Parse(rest)
  if not list then
    ns.Debug("a reagent name isn't in RecipeData.lua, leaving the line alone")
    return
  end
  Draw(tooltip, list)
  ns.Debug("drew", #list, "reagents")
  return true
end

if TooltipDataProcessor and TooltipDataProcessor.AddLinePreCall then
  -- Line hooks fire per line type, and the reagent line is a plain line (type 0, None).
  -- AllTypes only works for whole-tooltip hooks.
  local lineType = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.None or 0
  local warned = false
  TooltipDataProcessor.AddLinePreCall(lineType, function(tooltip, line)
    if OurTooltip(tooltip) then
      ns.Debug("line hook:", line and line.type, line and type(line.leftText) == "string" and line.leftText:sub(1, 30))
    end
    local ok, skip = pcall(OnLine, tooltip, line)
    if not ok and not warned then
      warned = true
      print("|cff33ff99TooltipExtras|r: recipe reagents failed: " .. tostring(skip))
    end
    return ok and skip or nil
  end)
  ItemRefTooltip:HookScript("OnShow", function(self)
    ns.Debug("ItemRefTooltip shown,", self:NumLines(), "lines")
  end)
  -- A header with no list after it must not carry over to the next tooltip.
  for _, tip in ipairs({ ItemRefTooltip, GameTooltip }) do
    tip:HookScript("OnHide", function(self) pending[self] = nil end)
  end
  if TooltipDataProcessor.AddTooltipPostCall and TooltipDataProcessor.AllTypes then
    TooltipDataProcessor.AddTooltipPostCall(TooltipDataProcessor.AllTypes, function(tooltip)
      pending[tooltip] = nil
    end)
  end
end
