-- Quest items: one line on an item's tooltip saying whether a quest still wants it.
-- Uses Questie's database (LibQuestieDB, from the QuestieDB addon). Each quest lists its item
-- objectives, the items it needs to start (requiredSourceItems) and the item its starter hands
-- you (sourceItemId). A pass over every quest after login turns that into item -> quests.
--
--   Needed for <quest> (3/5)     a quest in your log wants it
--   Starts a quest: <quest>       the item starts a quest you haven't done
--   Quest item: <quest> (not picked up)
--                                 quest-only item, its quest isn't done or in your log
--   Quest leftover: safe to delete
--                                 quest-only item, every quest that wants it is done
-- Normal items (cloth, bars, herbs) only get the first line: they're never called leftovers.
-- Items Questie doesn't know get no line.
--
-- Colours: bright blue = a quest needs it (in your log, or it starts one), pale blue = for a
-- quest you haven't picked up, red = safe to delete. Needed stays blue past the count (13/10).
-- Orange = a quest item Questie doesn't know and no quest in your log uses: likely a leftover.
-- The quest log is also checked directly (objective text, the quest's usable item), so Forever's
-- own quests that Questie lacks still show "Needed for" / "Used for".
-- Quest-like items (soulbound, not equippable, unique or a key) get the orange lines too, but
-- never red: a key may still open a door. /tte quest <itemID> shows what it knows.
-- Gold, white, green and the item-quality blue are all taken by normal tooltip text.
local ADDON, ns = ...

local QUEST_CLASS = 12 -- Enum.ItemClass.Questitem
local BATCH = 300      -- quests indexed per frame

local MODULE = {
  key = "questitems",
  category = "quests",
  label = "Quest items",
  tip = "On item tooltips: whether a quest in your log needs the item (with your count), whether it "
    .. "starts a quest, or whether it's a quest item left over from quests you've finished and can "
    .. "be deleted. Shown right under the item name (or its Quest Item line). Bright blue: a quest needs it. "
    .. "Pale blue: for a quest you haven't picked up. Red: safe to delete. "
    .. "Needed stays blue even when you have more than enough. Needs Questie.",
  options = { { key = "show", label = "Quest needed / leftover line", default = true } },
}
ns.AddModule(MODULE)

-- itemID -> { [questID] = true }; nil until the pass finishes
local index

local status = "waiting for login"
local tries = 0

local function Build()
  tries = tries + 1
  local L = LibQuestieDB
  local Q = L and L.Quest
  local ok, ids
  if Q and Q.GetAllIds and Q.Get then ok, ids = pcall(Q.GetAllIds) end
  if not ok or type(ids) ~= "table" or #ids == 0 then
    -- QuestieDB missing or not ready yet: try again for a minute or so
    status = (Q and "Questie's quest list was empty" or "QuestieDB not loaded") .. " (try " .. tries .. ")"
    if tries < 8 then C_Timer.After(10, Build) end
    return
  end
  status = "building (" .. #ids .. " quests)"
  local out, i = {}, 1
  local function Add(item, quest)
    if type(item) ~= "number" or item <= 0 then return end
    local t = out[item]
    if not t then t = {}; out[item] = t end
    t[quest] = true
  end
  local f = CreateFrame("Frame")
  f:SetScript("OnUpdate", function(self)
    local stop = math.min(i + BATCH - 1, #ids)
    for k = i, stop do
      local q = ids[k]
      local ok2, obj = pcall(Q.Get, q, "objectives")
      if ok2 and type(obj) == "table" and type(obj[3]) == "table" then
        for _, o in ipairs(obj[3]) do Add(type(o) == "table" and o[1], q) end
      end
      local ok3, req = pcall(Q.Get, q, "requiredSourceItems")
      if ok3 and type(req) == "table" then
        for _, it in ipairs(req) do Add(it, q) end
      end
      local ok4, src = pcall(Q.Get, q, "sourceItemId")
      if ok4 then Add(src, q) end
    end
    i = stop + 1
    if i > #ids then
      self:SetScript("OnUpdate", nil)
      index = out
      local n = 0
      for _ in pairs(out) do n = n + 1 end
      status = "ready: " .. n .. " items from " .. #ids .. " quests"
    end
  end)
end

local function ItemField(id, field)
  local I = LibQuestieDB and LibQuestieDB.Item
  if not (I and I.Get) then return nil end
  local ok, v = pcall(I.Get, id, field)
  if ok then return v end
end

local function QuestField(id, field)
  local Q = LibQuestieDB and LibQuestieDB.Quest
  if not (Q and Q.Get) then return nil end
  local ok, v = pcall(Q.Get, id, field)
  if ok then return v end
end

local function Done(q)
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    return C_QuestLog.IsQuestFlaggedCompleted(q)
  end
  return IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(q)
end

local function OnQuest(q)
  if C_QuestLog and C_QuestLog.IsOnQuest then return C_QuestLog.IsOnQuest(q) end
  if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
    return C_QuestLog.GetLogIndexForQuestID(q) ~= nil
  end
  return GetQuestLogIndexByID and (GetQuestLogIndexByID(q) or 0) > 0
end

local function QuestName(q)
  local n = C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(q)
  return n or QuestField(q, "name") or ("quest " .. q)
end

-- Questie's mask test: 0/nil means everyone, else the player's bit must be set
local function MaskHas(mask, bitValue)
  if not mask or mask == 0 or not bitValue then return true end
  return (mask % (2 * bitValue)) >= bitValue
end

-- whether this character could ever take quest q: race, class, and not shut out by a
-- pick-one sibling already done
local function ForMe(q)
  local race = select(3, UnitRace("player"))
  local enum = LibQuestieDB and LibQuestieDB.Enum
  local raceBit = enum and enum.raceMaskById and enum.raceMaskById[race]
  if not MaskHas(QuestField(q, "requiredRaces"), raceBit) then return false end
  local class = select(3, UnitClass("player"))
  if class and not MaskHas(QuestField(q, "requiredClasses"), 2 ^ (class - 1)) then return false end
  local excl = QuestField(q, "exclusiveTo")
  if type(excl) == "table" then
    for _, other in ipairs(excl) do
      if Done(other) then return false end
    end
  end
  return true
end

local function Bags(id)
  local get = C_Item and C_Item.GetItemCount or GetItemCount
  return get and get(id) or 0
end

-- "3/5" for item in quest q's log objectives, matched by the item's name in the text
local function Progress(q, id)
  local name = ns.ItemName(id) or (GetItemInfo and GetItemInfo(id)) or ItemField(id, "name")
  if not (name and C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
  local objs = C_QuestLog.GetQuestObjectives(q)
  if type(objs) ~= "table" then return nil end
  for _, o in ipairs(objs) do
    -- "Linen Cloth: 3/10" or "3/10 Linen Cloth", exactly: so Linen Cloth doesn't match
    -- "Bolt of Linen Cloth"
    local t = o.text
    local hit = t and (t:sub(1, #name + 1) == name .. ":" or t:sub(-(#name + 1)) == " " .. name)
    if hit and o.numRequired and o.numRequired > 0 then
      -- the log caps numFulfilled at numRequired; show what's in the bags (13/10)
      local have = math.max(Bags(id), o.numFulfilled or 0)
      return have .. "/" .. o.numRequired
    end
  end
end

local function Sorted(set)
  local list = {}
  for q in pairs(set) do list[#list + 1] = q end
  table.sort(list)
  return list
end

-- Puts text right under the item name, or under the "Quest Item" line when there is one.
-- A tooltip can't insert a line mid-way, so the text joins an existing line with a newline:
-- after the Quest Item line, or before line 2. The lines below keep their own FontStrings, so
-- anything anchored to them stays put.
local function Place(tooltip, text)
  local name = tooltip.GetName and tooltip:GetName()
  local n = tooltip.NumLines and tooltip:NumLines() or 0
  if not name or n < 2 then
    tooltip:AddLine(text)
    return
  end
  local questLabel = ITEM_BIND_QUEST or "Quest Item"
  for i = 2, math.min(n, 5) do
    local fs = _G[name .. "TextLeft" .. i]
    local t = fs and fs:GetText()
    if t and t:find(text, 1, true) then return end -- already placed on this build
    if t == questLabel then
      fs:SetText(t .. "\n" .. text)
      return
    end
  end
  local fs = _G[name .. "TextLeft2"]
  local t = fs and fs:GetText()
  if not fs then
    tooltip:AddLine(text)
  elseif t and t ~= "" then
    fs:SetText(text .. "\n" .. t)
  else
    fs:SetText(text)
  end
end

-- Quests in the log: { id, index } each
local function LogQuests()
  local out = {}
  if C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo then
    for i = 1, C_QuestLog.GetNumQuestLogEntries() do
      local info = C_QuestLog.GetInfo(i)
      if info and not info.isHeader and info.questID and info.questID > 0 then
        out[#out + 1] = { id = info.questID, index = i }
      end
    end
  elseif GetNumQuestLogEntries and GetQuestLogTitle then
    for i = 1, GetNumQuestLogEntries() do
      local _, _, _, isHeader, _, _, _, q = GetQuestLogTitle(i)
      if not isHeader and q and q > 0 then out[#out + 1] = { id = q, index = i } end
    end
  end
  return out
end

-- the item a quest gives you to use (the button on the quest log / tracker)
local function SpecialItem(logIndex)
  if not GetQuestLogSpecialItemInfo then return nil end
  local ok, link = pcall(GetQuestLogSpecialItemInfo, logIndex)
  return ok and type(link) == "string" and tonumber(link:match("item:(%d+)")) or nil
end

-- which of "Quest Item", "Soulbound", "Unique" the tooltip shows near the top
local function Flags(tooltip)
  local name = tooltip.GetName and tooltip:GetName()
  local quest, bound, unique = false, false, false
  if not name then return quest, bound, unique end
  for i = 2, math.min(tooltip:NumLines() or 0, 6) do
    local fs = _G[name .. "TextLeft" .. i]
    local t = fs and fs:GetText()
    if t == (ITEM_BIND_QUEST or "Quest Item") then quest = true
    elseif t == (ITEM_SOULBOUND or "Soulbound") then bound = true
    elseif t and t:find("^" .. (ITEM_UNIQUE or "Unique")) then unique = true end
  end
  return quest, bound, unique
end

local KEY_CLASS = 13

local BLUE = { 0.2, 0.8, 1 }

MODULE.OnItem = function(tooltip, id, db)
  if db.show == false then return false end
  local quests = index and index[id]
  -- Questie stores 0, not nil, for items that start nothing
  local starts = ItemField(id, "startQuest")
  if type(starts) ~= "number" or starts <= 0 then starts = nil end
  local info = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
  local _, _, _, equipLoc, _, classID = info(id)
  local questLine, bound, unique = Flags(tooltip)
  -- quest-only: red "safe to delete" is allowed once Questie says its quests are done
  local questOnly = classID == QUEST_CLASS or starts ~= nil or questLine
  -- quest-like: soulbound, can't be equipped, and unique or a key (Lamora's Key, Gemstone of
  -- Bloodaxe). Gets a line, but never a red one: keys open doors, gems may have other uses.
  local questLike = questOnly or (bound and (equipLoc == nil or equipLoc == "")
    and (unique or classID == KEY_CLASS))

  local lines, open, waiting, listed = {}, false, {}, {}
  local function Needed(q, verb)
    listed[q] = true
    open = true
    -- blue even with more than enough: better to keep extras than invite a deleted stack
    local p = Progress(q, id)
    lines[#lines + 1] = { verb .. QuestName(q) .. (p and (" (" .. p .. ")") or ""), BLUE[1], BLUE[2], BLUE[3] }
  end
  for _, q in ipairs(quests and Sorted(quests) or {}) do
    if OnQuest(q) then
      Needed(q, "Needed for ")
    elseif not Done(q) and ForMe(q) then
      waiting[#waiting + 1] = q
    end
  end

  -- The quest log itself, for every item: covers what Questie doesn't know (Forever's own
  -- quests) and an index that isn't built yet. An objective naming the item, or the item the
  -- quest gives you to use.
  for _, e in ipairs(LogQuests()) do
    if not listed[e.id] then
      if SpecialItem(e.index) == id then
        Needed(e.id, "Used for ")
      elseif Progress(e.id, id) then
        Needed(e.id, "Needed for ")
      end
    end
  end

  if starts and not Done(starts) and not OnQuest(starts) and ForMe(starts) then
    lines[#lines + 1] = { "Starts a quest: " .. QuestName(starts), BLUE[1], BLUE[2], BLUE[3] }
    open = true
  end

  if not open and questLike then
    if #waiting > 0 then
      for k = 1, math.min(#waiting, 3) do
        lines[#lines + 1] = { "Quest item: " .. QuestName(waiting[k]) .. " (not picked up)",
          0.6, 0.75, 0.9 }
      end
    elseif (quests or starts) and questOnly then
      lines[#lines + 1] = { "Quest leftover: safe to delete", 1, 0.25, 0.25 }
    elseif quests or starts then
      lines[#lines + 1] = { "Its quests are done", 1, 0.6, 0.2 }
      lines[#lines + 1] = { "Probably a leftover: check it has no other use", 0.6, 0.6, 0.6 }
    else
      -- Questie ties no quest to it, so "done" can't be known: say what we can see
      lines[#lines + 1] = { "No quest in your log uses this", 1, 0.6, 0.2 }
      lines[#lines + 1] = { questOnly and "Questie ties no quest to it: probably a leftover, not certain"
        or "Questie ties no quest to it: check before deleting", 0.6, 0.6, 0.6 }
    end
  end

  if #lines == 0 then return false end
  local parts = {}
  for k, l in ipairs(lines) do
    parts[k] = string.format("|cff%02x%02x%02x%s|r", l[2] * 255, l[3] * 255, l[4] * 255, l[1])
  end
  Place(tooltip, table.concat(parts, "\n"))
  return true
end

-- /tte quest [itemID]: index state, and what it knows about one item
ns.slash = ns.slash or {}
ns.slash.quest = function(arg)
  local p = "|cff33ff99TooltipExtras|r quest items: "
  print(p .. status)
  local id = tonumber(arg or "")
  if not id then
    print(p .. "add an item ID for details, e.g. /tte quest 12337")
    return
  end
  local qs = index and index[id]
  local list = {}
  for _, q in ipairs(qs and Sorted(qs) or {}) do
    list[#list + 1] = q .. (OnQuest(q) and " in log" or Done(q) and " done" or "")
  end
  print(p .. id .. " used by: " .. (#list > 0 and table.concat(list, ", ") or "none")
    .. "; starts: " .. tostring(ItemField(id, "startQuest")))
  local log = {}
  for _, e in ipairs(LogQuests()) do
    local special = SpecialItem(e.index)
    local prog = Progress(e.id, id)
    if special == id or prog then log[#log + 1] = e.id .. (prog and (" " .. prog) or " use") end
  end
  print(p .. "quest log: " .. #LogQuests() .. " quests" .. (#log > 0 and (", match " .. table.concat(log, ", ")) or ", no match"))
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
  -- after Questie's own login setup has had its frame
  C_Timer.After(5, Build)
end)
