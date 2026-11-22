-- Thorium Brotherhood: hover Master Smith Burninate (Thorium Point, Searing Gorge) to see what it
-- takes to reach each standing above yours, and what it costs on the AH.
-- WoW Forever quests (Wowhead's Forever pages), all repeatable for 25 rep, after What the Flux?:
--   Neutral: Restoring Fiery Flux Supplies, 2 Incendosaur Scale + 1 Coal and one of
--     4 Kingsblood (7736), 4 Iron Bar (8241) or 10 Heavy Leather (8242)
--   Friendly and up: Gaining Acceptance (7737), 4 Dark Iron Residue
-- Where Dark Iron Residue stops giving rep isn't listed for Forever; this counts it to Exalted.
-- Humans get 10% more rep.
local ADDON, ns = ...

local BURNINATE = 14624
local FACTION = 59
local REP_PER_TURNIN = 25

local SCALE, COAL, RESIDUE = 18944, 3857, 18945
local FLUX = { -- the third reagent of each Flux hand-in
  { id = 3356, count = 4, name = "Kingsblood" },
  { id = 3575, count = 4, name = "Iron Bar" },
  { id = 4234, count = 10, name = "Heavy Leather" },
}
local SCALES, COALS, RESIDUES = 2, 1, 4

local FRIENDLY = 3000
-- Reputation needed to reach each standing, counted from the bottom of Neutral.
local STANDINGS = {
  { "Friendly", FRIENDLY },
  { "Honored", 9000 },
  { "Revered", 21000 },
  { "Exalted", 42000 },
}

local function Rep()
  if C_Reputation and C_Reputation.GetFactionDataByID then
    local ok, d = pcall(C_Reputation.GetFactionDataByID, FACTION)
    if ok and type(d) == "table" and d.name then return d.name, d.currentStanding end
  end
  if GetFactionInfoByID then
    local name, _, _, _, _, value = GetFactionInfoByID(FACTION)
    if name then return name, value end
  end
end

local function Commas(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local k
    s, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    if k == 0 then return s end
  end
end

local function Turnins(n) return Commas(n) .. (n == 1 and " turn-in" or " turn-ins") end

-- AH cost of count of each { itemID, count } pair, or nil if any has no price
local function Cost(parts)
  local total = 0
  for _, p in ipairs(parts) do
    local price = ns.Price(p[1])
    if not price then return nil end
    total = total + price * p[2]
  end
  return total
end

local function Bags(id)
  local get = C_Item and C_Item.GetItemCount or GetItemCount
  return get and get(id) or 0
end

ns.AddModule({
  key = "thoriumrep",
  category = "reputation",
  label = "Thorium Brotherhood",
  tip = "Hover Master Smith Burninate in Searing Gorge: what it takes to reach each Thorium "
    .. "Brotherhood standing above yours, and what it costs on the auction house. To Friendly: "
    .. "the three Restoring Fiery Flux Supplies hand-ins, cheapest in green. From Friendly: "
    .. "Gaining Acceptance, 4 Dark Iron Residue each. 25 rep a hand-in, +10% for Humans.",
  options = { { key = "standings", label = "Hand-ins to each standing", default = true } },
  OnUnit = function(tooltip, npcID, db)
    if npcID ~= BURNINATE or db.standings == false then return false end
    local name, rep = Rep()
    if not (name and rep) then return false end

    local per = REP_PER_TURNIN
    if select(2, UnitRace("player")) == "Human" then per = per * 1.1 end

    tooltip:AddLine(" ")
    if rep >= STANDINGS[#STANDINGS][2] then
      tooltip:AddLine(name .. ": Exalted", 0.2, 1, 0.6)
      return true
    end

    -- money lines: { text, cost, best }, or { text } for a plain line
    local lines = {}
    if rep < FRIENDLY then
      local n = math.ceil((FRIENDLY - rep) / per)
      lines[#lines + 1] = { text = "Friendly: " .. Turnins(n) .. " of Restoring Fiery Flux Supplies" }
      -- Every way needs the scales and coal, so they get their own lines and each way is priced
      -- on its own reagent: one missing price doesn't blank the whole row.
      lines[#lines + 1] = { text = "  " .. Commas(n * SCALES) .. " " .. (ns.ItemName(SCALE) or "Incendosaur Scale"),
        cost = Cost({ { SCALE, n * SCALES } }), money = true }
      lines[#lines + 1] = { text = "  " .. Commas(n * COALS) .. " " .. (ns.ItemName(COAL) or "Coal"),
        cost = Cost({ { COAL, n * COALS } }), money = true }
      lines[#lines + 1] = { text = "  |cff808080and one of:|r" }
      local best
      for _, f in ipairs(FLUX) do
        local cost = Cost({ { f.id, n * f.count } })
        lines[#lines + 1] = { text = "    " .. Commas(n * f.count) .. " " .. (ns.ItemName(f.id) or f.name),
          cost = cost, money = true }
        if cost and (not best or cost < best.cost) then best = lines[#lines] end
      end
      if best then best.best = true end
    end
    local flux = #lines

    -- Gaining Acceptance from Friendly (or where you are now) to each standing after it
    local from = math.max(rep, FRIENDLY)
    local residue = ns.ItemName(RESIDUE) or "Dark Iron Residue"
    for _, s in ipairs(STANDINGS) do
      if s[2] > from then
        local n = math.ceil((s[2] - from) / per)
        lines[#lines + 1] = {
          text = s[1] .. ": " .. Commas(n * RESIDUES) .. " " .. residue .. " |cff808080("
            .. Turnins(n) .. (rep < FRIENDLY and ", after Friendly)|r" or ")|r"),
          cost = Cost({ { RESIDUE, n * RESIDUES } }), money = true,
        }
      end
    end
    -- a rule between the Flux block and the residue rows, when both show
    if flux > 0 and #lines > flux then table.insert(lines, flux + 1, { divider = true }) end
    local have = Bags(RESIDUE)
    if have >= RESIDUES then
      local n = math.floor(have / RESIDUES)
      lines[#lines + 1] = { text = "|cff808080You have " .. Commas(have) .. " " .. residue .. ": "
        .. Turnins(n) .. ", " .. Commas(math.floor(n * per)) .. " rep|r" }
    end

    local gold = 0
    for _, l in ipairs(lines) do
      if l.cost and l.cost >= 10000 then gold = math.max(gold, #tostring(math.floor(l.cost / 10000))) end
    end
    ns.MoneyHeader(tooltip, name .. " reputation", { "cost" }, { gold }, 1, 0.82, 0)
    for _, l in ipairs(lines) do
      if l.divider then
        ns.Divider(tooltip, 8)
      elseif not l.money then
        tooltip:AddLine(l.text, 1, 1, 1)
      elseif l.cost then
        if l.best then
          ns.MoneyLine(tooltip, l.text, { l.cost }, { gold }, 0.2, 1, 0.2, 0.2, 1, 0.2)
        else
          ns.MoneyLine(tooltip, l.text, { l.cost }, { gold }, 1, 1, 1, 1, 1, 1)
        end
      else
        tooltip:AddDoubleLine(l.text, "no price", 1, 1, 1, 0.5, 0.5, 0.5)
      end
    end
    return true
  end,
})
