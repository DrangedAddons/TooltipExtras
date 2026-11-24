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
-- quest you haven't picked up, red = safe to delete, grey = needed but you have enough.
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
    .. "Grey: needed, but you already have enough. Needs Questie.",
  options = { { key = "show", label = "Quest needed / leftover line", default = true } },
}
ns.AddModule(MODULE)

-- itemID -> { [questID] = true }; nil until the pass finishes
local index

local function Build()
  local L = LibQuestieDB
  local Q = L and L.Quest
  if not (Q and Q.GetAllIds and Q.Get) then return end
  local ok, ids = pcall(Q.GetAllIds)
  if not ok or type(ids) ~= "table" then return end
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

-- "3/5" for item in quest q's log objectives, matched by the item's name in the text
local function Progress(q, id)
  local name = ns.ItemName(id) or ItemField(id, "name")
  if not (name and C_QuestLog and C_QuestLog.GetQuestObjectives) then return nil end
  local objs = C_QuestLog.GetQuestObjectives(q)
  if type(objs) ~= "table" then return nil end
  for _, o in ipairs(objs) do
    if o.text and o.text:find(name, 1, true) and o.numRequired and o.numRequired > 0 then
      return o.numFulfilled .. "/" .. o.numRequired, o.finished
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

MODULE.OnItem = function(tooltip, id, db)
  if db.show == false or not index then return false end
  local quests = index[id]
  local starts = ItemField(id, "startQuest")
  if not quests and not starts then return false end
  local classID = select(6, C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(id)
    or GetItemInfoInstant(id))
  local questOnly = classID == QUEST_CLASS or starts ~= nil

  local lines, open, waiting = {}, false, {}
  for _, q in ipairs(quests and Sorted(quests) or {}) do
    if OnQuest(q) then
      open = true
      local p, finished = Progress(q, id)
      local text = "Needed for " .. QuestName(q) .. (p and (" (" .. p .. ")") or "")
      if finished then
        lines[#lines + 1] = { text, 0.5, 0.5, 0.5 }
      else
        lines[#lines + 1] = { text, 0.2, 0.8, 1 }
      end
    elseif not Done(q) and ForMe(q) then
      waiting[#waiting + 1] = q
    end
  end

  if type(starts) == "number" and not Done(starts) and not OnQuest(starts) and ForMe(starts) then
    lines[#lines + 1] = { "Starts a quest: " .. QuestName(starts), 0.2, 0.8, 1 }
    open = true
  end

  if not open and questOnly then
    if #waiting > 0 then
      for k = 1, math.min(#waiting, 3) do
        lines[#lines + 1] = { "Quest item: " .. QuestName(waiting[k]) .. " (not picked up)",
          0.6, 0.75, 0.9 }
      end
    else
      lines[#lines + 1] = { "Quest leftover: safe to delete", 1, 0.25, 0.25 }
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

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", function()
  -- after Questie's own login setup has had its frame
  C_Timer.After(5, Build)
end)
