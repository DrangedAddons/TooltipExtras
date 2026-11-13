-- Cloth quartermasters: hover one to see how much Runecloth it takes to reach each standing
-- above yours with their faction, and what that Runecloth costs on the AH.
-- WoW Forever values (checked on Wowhead's Forever pages): the repeatable Additional Runecloth
-- takes 20 Runecloth for 50 rep. The one-time Wool/Silk/Mageweave/Runecloth donations
-- (150 rep each) aren't counted. Humans get 10% more rep.
local ADDON, ns = ...

local RUNECLOTH = 14047
local PER_TURNIN, REP_PER_TURNIN = 20, 50

-- npcID -> faction ID
local QUARTERMASTERS = {
  [14722] = 72,  -- Clavicus Knavingham: Stormwind
  [14723] = 47,  -- Mistina Steelshield: Ironforge
  [14724] = 54,  -- Bubulo Acerbus: Gnomeregan Exiles
  [14725] = 69,  -- Raedon Duskstriker: Darnassus
  [14726] = 76,  -- Rashona Straglash: Orgrimmar
  [14727] = 530, -- Vehena: Darkspear Trolls
  [14728] = 81,  -- Rumstag Proudstrider: Thunder Bluff
  [14729] = 68,  -- Ralston Farnsley: Undercity
  [276170] = 2779, -- Belanaa Windveil (Dalaran, Forever only): High Order; Additional Runecloth is quest 99195
}

-- Reputation needed to reach each standing, counted from the bottom of Neutral.
local STANDINGS = {
  { "Friendly", 3000 },
  { "Honored", 9000 },
  { "Revered", 21000 },
  { "Exalted", 42000 },
}

-- Faction name and reputation counted from the bottom of Neutral (negative below Neutral),
-- or nil if this character can't see the faction.
local function Rep(factionID)
  if C_Reputation and C_Reputation.GetFactionDataByID then
    local ok, d = pcall(C_Reputation.GetFactionDataByID, factionID)
    if ok and type(d) == "table" and d.name then return d.name, d.currentStanding end
  end
  if GetFactionInfoByID then
    local name, _, _, _, _, value = GetFactionInfoByID(factionID)
    if name then return name, value end
  end
  return nil
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

ns.AddModule({
  key = "clothrep",
  label = "Cloth reputation",
  tip = "Hover a city's cloth quartermaster: how much Runecloth you need to reach each standing "
    .. "above yours with their faction, and what it costs on the auction house. Uses the "
    .. "repeatable Additional Runecloth (20 for 50 rep, +10% for Humans).",
  OnUnit = function(tooltip, npcID)
    local factionID = QUARTERMASTERS[npcID]
    if not factionID then return false end
    local name, rep = Rep(factionID)
    if not (name and rep) then return false end

    local perTurnin = REP_PER_TURNIN
    if select(2, UnitRace("player")) == "Human" then perTurnin = REP_PER_TURNIN * 1.1 end
    local price = ns.Price(RUNECLOTH)

    local rows = {}
    for _, s in ipairs(STANDINGS) do
      local need = s[2] - rep
      if need > 0 then
        local turnins = math.ceil(need / perTurnin)
        local cloth = turnins * PER_TURNIN
        rows[#rows + 1] = {
          text = s[1] .. ": " .. Commas(cloth) .. " Runecloth |cff808080(" .. Commas(turnins)
            .. (turnins == 1 and " turn-in)|r" or " turn-ins)|r"),
          cost = price and price * cloth,
        }
      end
    end

    tooltip:AddLine(" ")
    if #rows == 0 then
      tooltip:AddLine(name .. ": Exalted", 0.2, 1, 0.6)
      return true
    end
    local gold = 0
    for _, r in ipairs(rows) do
      if r.cost and r.cost >= 10000 then gold = math.max(gold, #tostring(math.floor(r.cost / 10000))) end
    end
    ns.MoneyHeader(tooltip, name .. " reputation", { "cost" }, { gold }, 1, 0.82, 0)
    for _, r in ipairs(rows) do
      if r.cost then
        ns.MoneyLine(tooltip, r.text, { r.cost }, { gold }, 1, 1, 1, 1, 1, 1)
      else
        tooltip:AddDoubleLine(r.text, "no price", 1, 1, 1, 0.5, 0.5, 0.5)
      end
    end
    return true
  end,
})
