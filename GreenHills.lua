-- The Green Hills of Stranglethorn: hover Barnil Stonepot (Booty Bay) to see what each chapter
-- costs if you buy its pages off the AH, and the total. Pages you carry aren't counted; chapters
-- you've turned in or hold show as done.
local ADDON, ns = ...

local BARNIL = 716
local FINAL_QUEST = 338

local function PageItem(n) return 2724 + n end -- Page 1 is 2725 ... Page 27 is 2751

-- { name, quest ID, chapter item, pages }
local CHAPTERS = {
  { "Chapter I", 339, 2756, { 1, 4, 6, 8 } },
  { "Chapter II", 340, 2757, { 10, 11, 14, 16 } },
  { "Chapter III", 341, 2758, { 18, 20, 21, 24 } },
  { "Chapter IV", 342, 2759, { 25, 26, 27 } },
}

local function QuestDone(id)
  local f = (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) or IsQuestFlaggedCompleted
  if not f then return false end
  local ok, done = pcall(f, id)
  return ok and done or false
end

local function Count(id)
  return GetItemCount and GetItemCount(id, true) or 0
end

ns.AddModule({
  key = "greenhills",
  label = "Green Hills of Stranglethorn",
  tip = "Hover Barnil Stonepot in Booty Bay: what each chapter costs if you buy the pages you don't "
    .. "have off the auction house, and the total.",
  OnUnit = function(tooltip, npcID)
    if npcID ~= BARNIL then return false end

    if QuestDone(FINAL_QUEST) then
      tooltip:AddLine(" ")
      tooltip:AddLine("Green Hills of Stranglethorn: done", 0.2, 1, 0.6)
      return true
    end

    -- { left text, cost or nil, status text when there's no cost to show }
    local rows, total, missing = {}, 0, false
    for _, ch in ipairs(CHAPTERS) do
      local name, quest, item, pages = ch[1], ch[2], ch[3], ch[4]
      if QuestDone(quest) or Count(item) > 0 then
        rows[#rows + 1] = { name .. " |cff808080(pages " .. table.concat(pages, ", ") .. ")|r", nil, "done" }
      else
        local cost, have, unpriced = 0, 0, {}
        for _, n in ipairs(pages) do
          if Count(PageItem(n)) > 0 then
            have = have + 1
          else
            local p = ns.Price(PageItem(n))
            if p then cost = cost + p else unpriced[#unpriced + 1] = n end
          end
        end
        local left = name .. " |cff808080(pages " .. table.concat(pages, ", ")
          .. (have > 0 and ("; have " .. have .. " of " .. #pages) or "") .. ")|r"
        if #unpriced > 0 then
          missing = true
          rows[#rows + 1] = { left, nil, "no price: page " .. table.concat(unpriced, ", ") }
        elseif have == #pages then
          rows[#rows + 1] = { left, nil, "have all pages" }
        else
          total = total + cost
          rows[#rows + 1] = { left, cost }
        end
      end
    end

    local gold = 0
    for _, r in ipairs(rows) do
      if r[2] and r[2] >= 10000 then gold = math.max(gold, #tostring(math.floor(r[2] / 10000))) end
    end
    if total >= 10000 then gold = math.max(gold, #tostring(math.floor(total / 10000))) end

    tooltip:AddLine(" ")
    ns.MoneyHeader(tooltip, "Green Hills of Stranglethorn", { "pages cost" }, { gold }, 1, 0.82, 0)
    for _, r in ipairs(rows) do
      if r[2] then
        ns.MoneyLine(tooltip, r[1], { r[2] }, { gold }, 1, 1, 1, 1, 1, 1)
      else
        local done = r[3] == "done" or r[3] == "have all pages"
        tooltip:AddDoubleLine(r[1], r[3], 1, 1, 1, done and 0.2 or 0.5, done and 1 or 0.5, done and 0.6 or 0.5)
      end
    end
    ns.MoneyLine(tooltip, missing and "Total |cff808080(priced pages only)|r" or "Total", { total }, { gold },
      0.2, 1, 0.6, 0.2, 1, 0.6)
    return true
  end,
})
