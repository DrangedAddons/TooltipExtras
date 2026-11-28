-- Argent Dawn: hover Duke Nicholas Zverenhoff (Light's Hope Chapel) to see how many
-- scourgestones it takes to reach each standing above yours.
-- WoW Forever quests (Wowhead's Forever pages), all repeatable for 25 rep and a Valor Token:
--   Minion's Scourgestones (5510): 20 Minion's Scourgestone
--   Invader's Scourgestones (5509): 10 Invader's Scourgestone
--   Corruptor's Scourgestones (5508): 1 Corruptor's Scourgestone
-- Minion's and Invader's stop giving rep at Honored (as in the original game; Wowhead's Forever
-- pages don't list a cap); Corruptor's goes to Exalted. Scourgestones are soulbound, so this
-- counts stones, not gold. Humans get 10% more rep.
local ADDON, ns = ...

local DUKE = 11039
local FACTION = 529
local REP_PER_TURNIN = 25

local MINION, INVADER, CORRUPTOR = 12840, 12841, 12843
local STONES = { -- per turn-in; capped = no rep from Honored
  { id = MINION, count = 20, name = "Minion's Scourgestone", capped = true },
  { id = INVADER, count = 10, name = "Invader's Scourgestone", capped = true },
  { id = CORRUPTOR, count = 1, name = "Corruptor's Scourgestone" },
}

local HONORED = 9000
-- Reputation needed to reach each standing, counted from the bottom of Neutral.
local STANDINGS = {
  { "Friendly", 3000 },
  { "Honored", HONORED },
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

local function Bags(id)
  local get = C_Item and C_Item.GetItemCount or GetItemCount
  return get and get(id) or 0
end

local GREY = "|cff808080"

ns.AddModule({
  key = "argentdawn",
  category = "reputation",
  label = "Argent Dawn scourgestones",
  tip = "Hover Duke Nicholas Zverenhoff at Light's Hope Chapel: how many scourgestones it takes "
    .. "to reach each Argent Dawn standing above yours, and how far the ones in your bags get you. "
    .. "20 Minion's, 10 Invader's or 1 Corruptor's per turn-in, 25 rep each (+10% for Humans). "
    .. "Minion's and Invader's stop giving rep at Honored.",
  options = { { key = "standings", label = "Scourgestones to each standing", default = true } },
  OnUnit = function(tooltip, npcID, db)
    if npcID ~= DUKE or db.standings == false then return false end
    local name, rep = Rep()
    if not (name and rep) then return false end

    local per = REP_PER_TURNIN
    if select(2, UnitRace("player")) == "Human" then per = per * 1.1 end

    tooltip:AddLine(" ")
    if rep >= STANDINGS[#STANDINGS][2] then
      tooltip:AddLine(name .. ": Exalted", 0.2, 1, 0.6)
      return true
    end

    tooltip:AddLine(name .. " reputation", 1, 0.82, 0)
    local divider = false
    for _, s in ipairs(STANDINGS) do
      if s[2] > rep then
        local n = math.ceil((s[2] - rep) / per)
        if s[2] <= HONORED then
          -- any stone works up to Honored
          tooltip:AddLine("To " .. s[1] .. ": " .. Turnins(n) .. ", any of", 1, 1, 1)
          for _, st in ipairs(STONES) do
            tooltip:AddLine("    " .. Commas(n * st.count) .. " " .. (ns.ItemName(st.id) or st.name), 1, 1, 1)
          end
        else
          -- past Honored only Corruptor's count; from Honored when you're below it
          if not divider and rep < HONORED then
            ns.Divider(tooltip, 8)
            divider = true
          end
          local from = math.max(rep, HONORED)
          local m = math.ceil((s[2] - from) / per)
          tooltip:AddLine("To " .. s[1] .. ": " .. Commas(m) .. " " .. (ns.ItemName(CORRUPTOR) or "Corruptor's Scourgestone")
            .. (rep < HONORED and (GREY .. " (from Honored)|r") or ""), 1, 1, 1)
        end
      end
    end
    if rep >= HONORED then
      tooltip:AddLine(GREY .. "Minion's and Invader's give no rep from Honored|r")
    end

    -- what the stones in your bags are worth
    local turnins, gained, parts = 0, 0, {}
    local room = math.max(0, HONORED - rep) -- rep the capped stones can still give
    for _, st in ipairs(STONES) do
      local have = Bags(st.id)
      local t = math.floor(have / st.count)
      if have > 0 then parts[#parts + 1] = Commas(have) .. " " .. (st.id == MINION and "Minion's"
        or st.id == INVADER and "Invader's" or "Corruptor's") end
      if t > 0 then
        local r = t * per
        if st.capped then
          r = math.min(r, room)
          room = room - r
        end
        turnins = turnins + t
        gained = gained + r
      end
    end
    if #parts > 0 then
      tooltip:AddLine(GREY .. "You have " .. table.concat(parts, ", ") .. ": " .. Turnins(turnins)
        .. ", " .. Commas(math.floor(gained)) .. " rep|r")
    end
    return true
  end,
})
