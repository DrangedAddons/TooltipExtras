-- Darkmoon Faire: hover a ticket turn-in NPC to see its hand-ins ranked by what a ticket costs.
-- Each hand-in costs the AH price of the items, or, when this character knows the recipe and
-- crafting is cheaper, the cost of the materials (AH or vendor price). Craftable rows are tagged.
-- Cheapest is green with "<< best". Buying, so no AH cut.
-- Hand-ins are classic's (Forever matches): count of item -> tickets.
local ADDON, ns = ...

-- Recipes for the craftable hand-ins (Forever's, from CraftRoute's data).
-- itemID -> { spell = recipe spell ID, makes = items per craft, { {reagentID, count}, ... } }
local RECIPES = {
  [3240] = { spell = 3116, { 2836, 1 } },                                     -- Coarse Weightstone
  [3486] = { spell = 3337, { 2838, 3 } },                                     -- Heavy Grinding Stone
  [3835] = { spell = 3501, { 3575, 6 }, { 2605, 1 } },                        -- Green Iron Bracers
  [7945] = { spell = 10001, { 3860, 16 }, { 7971, 1 }, { 1210, 4 }, { 7966, 1 }, { 4304, 2 } }, -- Big Black Mace
  [12644] = { spell = 16639, { 12365, 4 } },                                  -- Dense Grinding Stone
  [4363] = { spell = 3926, { 4359, 2 }, { 2840, 1 }, { 2589, 2 } },           -- Copper Modulator
  [4375] = { spell = 3942, { 2841, 2 }, { 2592, 1 } },                        -- Whirring Bronze Gizmo
  [9313] = { spell = 23068, makes = 3, { 4377, 1 }, { 4234, 1 } },            -- Green Firework
  [11590] = { spell = 15255, { 3860, 1 }, { 4338, 1 }, { 10505, 1 } },        -- Mechanical Repair Kit
  [15994] = { spell = 19791, { 12359, 3 }, { 14047, 1 } },                    -- Thorium Widget
  [2309] = { spell = 2161, { 2318, 8 }, { 2320, 5 } },                        -- Embossed Leather Boots
  [2314] = { spell = 2166, { 2319, 10 }, { 4231, 2 }, { 2321, 2 } },          -- Toughened Leather Armor
  [5739] = { spell = 6661, { 4234, 14 }, { 2321, 2 }, { 7071, 1 } },          -- Barbaric Harness
  [8185] = { spell = 10556, { 4304, 14 }, { 8167, 28 }, { 8343, 1 } },        -- Turtle Scale Leggings
  [15564] = { spell = 19058, { 8170, 5 } },                                   -- Rugged Armor Kit
}

-- npcID -> { { itemID, count, tickets, name until the item name loads }, ... }
local NPCS = {
  [14829] = { -- Yebb Neblegear: beast parts
    { 5134, 5, 1, "Small Furry Paw" },
    { 11407, 5, 4, "Torn Bear Pelt" },
    { 4582, 5, 8, "Soft Bushy Tail" },
    { 5117, 5, 12, "Vibrant Plume" },
    { 11404, 10, 20, "Evil Bat Eye" },
    { 19933, 10, 20, "Glowing Scorpid Blood" },
  },
  [14832] = { -- Kerri Hicks: Blacksmithing
    { 3240, 10, 1, "Coarse Weightstone" },
    { 3486, 7, 4, "Heavy Grinding Stone" },
    { 3835, 3, 8, "Green Iron Bracers" },
    { 7945, 3, 12, "Big Black Mace" },
    { 12644, 8, 20, "Dense Grinding Stone" },
  },
  [14841] = { -- Rinling: Engineering
    { 4363, 3, 1, "Copper Modulator" },
    { 4375, 7, 4, "Whirring Bronze Gizmo" },
    { 9313, 36, 8, "Green Firework" },
    { 11590, 6, 12, "Mechanical Repair Kit" },
    { 15994, 6, 20, "Thorium Widget" },
  },
  [14833] = { -- Chronos: Leatherworking
    { 2309, 3, 1, "Embossed Leather Boots" },
    { 2314, 3, 4, "Toughened Leather Armor" },
    { 5739, 3, 8, "Barbaric Harness" },
    { 8185, 1, 12, "Turtle Scale Leggings" },
    { 15564, 8, 20, "Rugged Armor Kit" },
  },
}

----------------------------------------------------------------------------------------------
-- Which of these recipes this character knows. Saved per character from the profession window,
-- since recipes can't be asked about while it's closed.

local spellToItem = {}
for itemID, r in pairs(RECIPES) do spellToItem[r.spell] = itemID end

local function Known()
  TooltipExtrasCharDB = TooltipExtrasCharDB or {}
  TooltipExtrasCharDB.knownRecipes = TooltipExtrasCharDB.knownRecipes or {}
  return TooltipExtrasCharDB.knownRecipes
end

local function KnowsRecipe(spell)
  if Known()[spell] then return true end
  if IsPlayerSpell then
    local ok, yes = pcall(IsPlayerSpell, spell)
    if ok and yes then return true end
  end
  return false
end

local function ScanTradeSkill()
  local known = Known()
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs and C_TradeSkillUI.GetRecipeInfo then
    for _, recipeID in ipairs(C_TradeSkillUI.GetAllRecipeIDs() or {}) do
      if spellToItem[recipeID] then
        local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipeID)
        if ok and info and info.learned ~= nil then known[recipeID] = info.learned or nil end
      end
    end
  elseif GetNumTradeSkills and GetTradeSkillRecipeLink then
    for i = 1, GetNumTradeSkills() do
      local link = GetTradeSkillRecipeLink(i)
      local spell = link and tonumber(link:match("enchant:(%d+)"))
      if spell and spellToItem[spell] then known[spell] = true end
    end
  end
end

local scanner = CreateFrame("Frame")
for _, ev in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "NEW_RECIPE_LEARNED" }) do
  pcall(scanner.RegisterEvent, scanner, ev)
end
scanner:SetScript("OnEvent", function() pcall(ScanTradeSkill) end)

-- Materials for one item, bought at the cheaper of AH and vendor. nil if any price is missing.
local function CraftCost(r)
  local total = 0
  for _, rg in ipairs(r) do
    local p = ns.BuyPrice(rg[1])
    if not p then return nil end
    total = total + p * rg[2]
  end
  return total / (r.makes or 1)
end

----------------------------------------------------------------------------------------------

local NPC_NAMES = {
  [14829] = "Yebb Neblegear",
  [14832] = "Kerri Hicks",
  [14841] = "Rinling",
  [14833] = "Chronos",
}
local NPC_ORDER = { 14829, 14832, 14841, 14833 }

-- One NPC's hand-ins as { text, items, tag, tickets, cost = whole quest, perTicket }, cheapest
-- per ticket first, unpriced last.
local function Rows(npcID)
  local rows = {}
  for _, q in ipairs(NPCS[npcID]) do
    local itemID, count, tickets = q[1], q[2], q[3]
    local buy = ns.Price(itemID)
    local recipe = RECIPES[itemID]
    local craftable = recipe and KnowsRecipe(recipe.spell)
    local craft = craftable and CraftCost(recipe)
    local each, tag
    if craft and (not buy or craft <= buy) then
      each, tag = craft, "  |cff66ccff[craft]|r"
    elseif craftable then
      each, tag = buy, "  |cff66ccff[craftable, buying is cheaper]|r"
    else
      each, tag = buy, ""
    end
    local items = count .. " x " .. (ns.ItemName(itemID) or q[4])
    rows[#rows + 1] = {
      text = items .. " |cff808080(" .. tickets .. (tickets == 1 and " ticket)|r" or " tickets)|r") .. tag,
      items = items,
      tag = tag,
      tickets = tickets,
      cost = each and each * count,
      perTicket = each and each * count / tickets,
    }
  end
  table.sort(rows, function(a, b)
    if a.perTicket and b.perTicket then return a.perTicket < b.perTicket end
    return a.perTicket ~= nil
  end)
  return rows
end

----------------------------------------------------------------------------------------------
-- Ticket vendor (Gelvas Grimegate): on an item priced in tickets, what the tickets you're short
-- would cost through the cheapest mix of quests at all four NPCs.

local TICKET = 19182 -- Darkmoon Faire Prize Ticket

-- Whether a merchant is open. Tracked by event because merchant window replacements may never
-- show MerchantFrame or use its button names.
local merchantOpen = false
local merchantWatch = CreateFrame("Frame")
merchantWatch:RegisterEvent("MERCHANT_SHOW")
merchantWatch:RegisterEvent("MERCHANT_CLOSED")
merchantWatch:SetScript("OnEvent", function(_, event) merchantOpen = event == "MERCHANT_SHOW" end)

local function MerchantItemID(i)
  if GetMerchantItemID then
    local id = GetMerchantItemID(i)
    if id then return id end
  end
  local link = GetMerchantItemLink and GetMerchantItemLink(i)
  return link and tonumber(link:match("item:(%d+)"))
end

-- The ticket price of item `id` at the open merchant, or nil when it isn't sold for tickets.
local function MerchantTicketPrice(id)
  if not merchantOpen or not (GetMerchantNumItems and GetMerchantItemCostInfo and GetMerchantItemCostItem) then
    return nil
  end
  for i = 1, GetMerchantNumItems() or 0 do
    if MerchantItemID(i) == id then
      for k = 1, GetMerchantItemCostInfo(i) or 0 do
        local _, value, link = GetMerchantItemCostItem(i, k)
        if link and tonumber(link:match("item:(%d+)")) == TICKET then return value end
      end
      return nil
    end
  end
  return nil
end

-- Cheapest set of quests giving at least `need` tickets, as { { row, times }, ... } and the
-- total cost. Unbounded knapsack over every priced quest; need is a few hundred at most.
local function TicketPlan(need)
  local quests = {}
  for _, npc in ipairs(NPC_ORDER) do
    for _, r in ipairs(Rows(npc)) do
      if r.cost then
        r.npc = NPC_NAMES[npc]
        quests[#quests + 1] = r
      end
    end
  end
  if #quests == 0 then return nil end
  local best, pick = { [0] = 0 }, {}
  for t = 1, need do
    for qi, q in ipairs(quests) do
      local c = best[math.max(0, t - q.tickets)] + q.cost
      if not best[t] or c < best[t] then best[t], pick[t] = c, qi end
    end
  end
  local counts, order, t = {}, {}, need
  while t > 0 do
    local qi = pick[t]
    if not counts[qi] then order[#order + 1] = qi end
    counts[qi] = (counts[qi] or 0) + 1
    t = math.max(0, t - quests[qi].tickets)
  end
  local plan = {}
  for _, qi in ipairs(order) do plan[#plan + 1] = { row = quests[qi], times = counts[qi] } end
  table.sort(plan, function(a, b) return a.row.perTicket < b.row.perTicket end)
  return plan, best[need]
end

local function VendorTooltip(tooltip, price)
  local have = GetItemCount and GetItemCount(TICKET, true) or 0
  local need = price - have
  tooltip:AddLine(" ")
  tooltip:AddLine(string.format("Darkmoon tickets: costs %d, you have %d", price, have), 1, 0.82, 0)
  if need <= 0 then
    tooltip:AddLine("You have enough tickets", 0.2, 1, 0.6)
    return true
  end
  local plan, total = TicketPlan(need)
  if not plan then
    tooltip:AddLine("No quest prices from Auctionator yet", 0.6, 0.6, 0.6)
    return true
  end
  local gold = 0
  for _, p in ipairs(plan) do
    local v = p.row.cost * p.times
    if v >= 10000 then gold = math.max(gold, #tostring(math.floor(v / 10000))) end
  end
  if total >= 10000 then gold = math.max(gold, #tostring(math.floor(total / 10000))) end
  ns.MoneyHeader(tooltip, "Cheapest quests for " .. need .. " more", { "cost" }, { gold }, 1, 0.82, 0)
  for _, p in ipairs(plan) do
    local got = p.row.tickets * p.times
    local left = p.row.npc .. ": " .. (p.times > 1 and (p.times .. " x (" .. p.row.items .. ")") or p.row.items)
      .. " |cff808080(" .. got .. (got == 1 and " ticket)|r" or " tickets)|r") .. p.row.tag
    ns.MoneyLine(tooltip, left, { p.row.cost * p.times }, { gold }, 1, 1, 1, 1, 1, 1)
  end
  ns.MoneyLine(tooltip, "Total", { total }, { gold }, 0.2, 1, 0.6, 0.2, 1, 0.6)
  return true
end

ns.AddModule({
  key = "darkmoon",
  label = "Darkmoon Faire",
  tip = "Hover Yebb Neblegear, Kerri Hicks, Rinling or Chronos: their ticket quests with what each "
    .. "costs to complete, best value per ticket first, then the best hand-in at each of the other three. Hand-ins you can craft "
    .. "are tagged, and use the material cost when crafting is cheaper than buying them made. "
    .. "At the ticket vendor, items show the cheapest quests for the tickets you're short.",
  OnItem = function(tooltip, id)
    local price = MerchantTicketPrice(id)
    if not price then return false end
    return VendorTooltip(tooltip, price)
  end,
  OnUnit = function(tooltip, npcID)
    if not NPCS[npcID] then return false end

    local rows = Rows(npcID)
    -- The best hand-in at each other NPC. Green when its cost per ticket beats this NPC's best.
    local mine = rows[1] and rows[1].perTicket
    local others = {}
    for _, id in ipairs(NPC_ORDER) do
      if id ~= npcID then
        others[#others + 1] = { name = NPC_NAMES[id], row = Rows(id)[1] }
      end
    end
    table.sort(others, function(a, b)
      local pa, pb = a.row and a.row.perTicket, b.row and b.row.perTicket
      if pa and pb then return pa < pb end
      return pa ~= nil
    end)

    -- Two money columns, per ticket then cost. One gold slot width per column for the whole
    -- tooltip so both blocks line up; 0 when no row in that column reaches a gold.
    local goldDigits = { 0, 0 }
    local function Measure(r)
      if not r then return end
      for c, v in ipairs({ r.perTicket, r.cost }) do
        if v and v >= 10000 then
          goldDigits[c] = math.max(goldDigits[c], #tostring(math.floor(v / 10000)))
        end
      end
    end
    for _, r in ipairs(rows) do Measure(r) end
    for _, o in ipairs(others) do Measure(o.row) end
    local LABELS = { "per ticket", "cost" }

    tooltip:AddLine(" ")
    ns.MoneyHeader(tooltip, "Darkmoon quests, best value first", LABELS, goldDigits, 1, 0.82, 0)
    for i, r in ipairs(rows) do
      if not r.perTicket then
        tooltip:AddDoubleLine(r.text, "no price", 0.6, 0.6, 0.6, 0.5, 0.5, 0.5)
      elseif i == 1 then
        ns.MoneyLine(tooltip, r.text .. "  |cff33ff99<< best|r", { r.perTicket, r.cost }, goldDigits,
          0.2, 1, 0.6, 0.2, 1, 0.6)
      else
        ns.MoneyLine(tooltip, r.text, { r.perTicket, r.cost }, goldDigits, 1, 1, 1, 1, 1, 1)
      end
    end

    tooltip:AddLine(" ")
    ns.MoneyHeader(tooltip, "Best at the other NPCs", LABELS, goldDigits, 1, 0.82, 0)
    for _, o in ipairs(others) do
      local p = o.row and o.row.perTicket
      local text = o.name .. ": " .. (o.row and o.row.text or "?")
      if not p then
        tooltip:AddDoubleLine(text, "no price", 0.6, 0.6, 0.6, 0.5, 0.5, 0.5)
      elseif not mine or p < mine then
        ns.MoneyLine(tooltip, text .. "  |cff33ff99<< better value|r", { o.row.perTicket, o.row.cost }, goldDigits,
          0.2, 1, 0.6, 0.2, 1, 0.6)
      else
        ns.MoneyLine(tooltip, text, { o.row.perTicket, o.row.cost }, goldDigits, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
      end
    end
    return true
  end,
})
