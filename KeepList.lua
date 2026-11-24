-- Items to keep: a list you add to by hand, for items like the Mallet of Zul'Farrak that no
-- quest needs but you want to hang on to. A kept item's tooltip says so (in blue, with your
-- note) instead of the orange / red "leftover" lines from Quest items.
-- Saved account-wide in TooltipExtrasDB.keep = { [itemID] = note ("" for none) }.
--
-- Add one: the window (/tte keep, or the button in the settings) lists your bags and bank to
-- pick from; /tte keep <item> [note]; or hover the item and press the "Keep / unkeep hovered
-- item" key binding.
local ADDON, ns = ...
local UI = ns.UI

local function DB()
  TooltipExtrasDB = TooltipExtrasDB or {}
  if type(TooltipExtrasDB.keep) ~= "table" then TooltipExtrasDB.keep = {} end
  return TooltipExtrasDB.keep
end

-- note for a kept item ("" when it has none), or nil
function ns.KeepNote(id)
  return id and DB()[id]
end

local function Say(msg) print("|cff33ff99TooltipExtras|r " .. msg) end

local function IDOf(text)
  if type(text) ~= "string" then return nil end
  return tonumber(text:match("item:(%d+)")) or tonumber(text:match("^%s*(%d+)"))
end

local function Label(id)
  local name, link = GetItemInfo(id)
  return link or name or ("item " .. id)
end

local window
local function Refresh()
  if window and window:IsShown() then window.Update() end
end

local function Add(id, note)
  if not id then return end
  DB()[id] = note or DB()[id] or ""
  Say("keeping " .. Label(id) .. ((note and note ~= "") and (": " .. note) or ""))
  Refresh()
end

local function Remove(id)
  if not (id and DB()[id]) then return end
  DB()[id] = nil
  Say("no longer keeping " .. Label(id))
  Refresh()
end

-- key binding: toggle the item under the mouse
function TooltipExtras_ToggleKeep()
  local _, link = GameTooltip:GetItem()
  local id = IDOf(link)
  if not id then
    Say("hover an item first")
  elseif DB()[id] then
    Remove(id)
  else
    Add(id)
  end
end
BINDING_HEADER_TOOLTIPEXTRAS = "TooltipExtras"
BINDING_NAME_TOOLTIPEXTRAS_KEEP = "Keep / unkeep hovered item"

----------------------------------------------------------------------------------------------
-- What you're carrying: bags now, and the bank as it was on your last visit
-- (TooltipExtrasCharDB.bank = { [itemID] = { n = count, bound = bool }, seen = time }).

local function SlotInfo(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local i = C_Container.GetContainerItemInfo(bag, slot)
    if i then return i.itemID, i.stackCount or 1, i.isBound end
  elseif GetContainerItemInfo then
    local _, count, _, _, _, _, _, _, _, id, bound = GetContainerItemInfo(bag, slot)
    return id, count or 1, bound
  end
end

local function Slots(bag)
  local get = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
  return get and get(bag) or 0
end

local function Scan(bags, out)
  for _, bag in ipairs(bags) do
    for slot = 1, Slots(bag) do
      local id, n, bound = SlotInfo(bag, slot)
      if id then
        local e = out[id]
        if not e then e = { n = 0 }; out[id] = e end
        e.n = e.n + n
        e.bound = e.bound or bound or nil
      end
    end
  end
  return out
end

local function LastBag() return NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 end

local function BagIDs()
  local t = {}
  for b = 0, LastBag() do t[#t + 1] = b end
  return t
end

local function BankIDs()
  local t = { BANK_CONTAINER or -1 }
  if REAGENTBANK_CONTAINER then t[#t + 1] = REAGENTBANK_CONTAINER end
  for b = LastBag() + 1, LastBag() + (NUM_BANKBAGSLOTS or 7) do t[#t + 1] = b end
  return t
end

local atBank = false
local function SaveBank()
  if not atBank then return end
  TooltipExtrasCharDB = TooltipExtrasCharDB or {}
  local bank = Scan(BankIDs(), {})
  TooltipExtrasCharDB.bank = { items = bank, seen = time() }
end

local function BankItems()
  local b = TooltipExtrasCharDB and TooltipExtrasCharDB.bank
  return b and b.items or {}, b and b.seen
end

----------------------------------------------------------------------------------------------
-- Window: everything in your bags and bank, pick rows, then Keep / Don't keep.

local ROW_H, ROWS = 22, 16
local WHITE = "Interface\\Buttons\\WHITE8X8"
local KEY_CLASS = 13

local function Build()
  local f = UI.Window({ name = "TooltipExtrasKeep", title = "Items to keep", width = 780, height = 600 })
  local body = f.body
  local filter, search, selected, last = "quest", "", {}, nil

  local help = UI.Text(body, "Click rows to select them (Shift-click for a range), then Keep or "
    .. "Don't keep. Kept items say so on their tooltip and never show as a leftover.",
    "GameFontHighlightSmall")
  help:SetPoint("TOPLEFT", 0, 0)
  help:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  help:SetJustifyH("LEFT")
  help:SetWordWrap(true)

  local show = UI.Dropdown(body, 200, function()
    return {
      { value = "quest", label = "Quest and unique items" },
      { value = "all", label = "Everything" },
      { value = "kept", label = "Kept items" },
    }
  end, function() return filter end, function(v)
    filter = v
    f.Update()
  end)
  show:SetPoint("TOPLEFT", 0, -26)

  local searchBox = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  searchBox:SetSize(200, 20)
  searchBox:SetAutoFocus(false)
  searchBox:SetPoint("LEFT", show, "RIGHT", 16, 0)
  local searchHint = UI.Text(searchBox, "Search", "GameFontDisable")
  searchHint:SetPoint("LEFT", 2, 0)
  searchBox:SetScript("OnTextChanged", function(self)
    search = self:GetText():lower()
    searchHint:SetShown(search == "")
    f.Update()
  end)
  searchBox:SetScript("OnEscapePressed", searchBox.ClearFocus)
  searchBox:SetScript("OnEnterPressed", searchBox.ClearFocus)

  local bankNote = UI.Text(body, "", "GameFontHighlightSmall")
  bankNote:SetPoint("LEFT", searchBox, "RIGHT", 14, 0)
  bankNote:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  bankNote:SetJustifyH("RIGHT")

  local list
  local function Render(row, e)
    local text = e.link or e.name
    local count = {}
    if e.bags > 0 then count[#count + 1] = e.bags .. " in bags" end
    if e.bank > 0 then count[#count + 1] = e.bank .. " in bank" end
    if #count > 0 then text = text .. "  |cff808080" .. table.concat(count, ", ") .. "|r" end
    UI.RenderRow(row, text, e.icon)
    row.mark:SetShown(selected[e.id] == true)
    local st = e.status
    if st then
      row.status:SetText(st[1])
      row.status:SetTextColor(st[2], st[3], st[4])
    else
      row.status:SetText("")
    end
  end
  local function Click(_, e)
    local data = list.data
    local at
    for i, d in ipairs(data) do if d == e then at = i break end end
    if IsShiftKeyDown() and last and at then
      local want = not selected[e.id]
      for i = math.min(last, at), math.max(last, at) do selected[data[i].id] = want or nil end
    else
      selected[e.id] = not selected[e.id] or nil
    end
    last = at
    f.Count()
    list:Update()
  end
  list = UI.List(body, 744, ROW_H, ROWS, Render, Click)
  list:SetPoint("TOPLEFT", 0, -56)
  local ar, ag, ab = ns.AccentColor()
  for _, r in ipairs(list.rows) do
    r.mark = r:CreateTexture(nil, "BACKGROUND")
    r.mark:SetAllPoints()
    r.mark:SetTexture(WHITE)
    r.mark:SetVertexColor(ar, ag, ab, 0.3)
    r.mark:Hide()
    r.status = UI.Text(r, "", "GameFontHighlightSmall")
    r.status:SetPoint("RIGHT", -6, 0)
    r.status:SetWidth(300)
    r.status:SetJustifyH("RIGHT")
    r.status:SetWordWrap(false)
    r.text:SetPoint("RIGHT", r.status, "LEFT", -8, 0)
    r:SetScript("OnEnter", function(self)
      if not self.item then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.item.id)
      GameTooltip:Show()
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
  end

  local empty = UI.Text(body, "Nothing here.", "GameFontDisable")
  empty:SetPoint("TOP", list, "TOP", 0, -20)

  -- actions
  local count = UI.Text(body, "", "GameFontNormalSmall")
  count:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 2, -10)
  local all = UI.Button(body, "Select all", 100, 22, function()
    for _, e in ipairs(list.data) do selected[e.id] = true end
    f.Count()
    list:Update()
  end)
  all:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -28)
  local none = UI.Button(body, "Select none", 100, 22, function()
    wipe(selected)
    f.Count()
    list:Update()
  end)
  none:SetPoint("LEFT", all, "RIGHT", 6, 0)

  local noteBox = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  noteBox:SetSize(220, 20)
  noteBox:SetAutoFocus(false)
  noteBox:SetMaxLetters(60)
  noteBox:SetPoint("LEFT", none, "RIGHT", 24, 0)
  local noteHint = UI.Text(noteBox, "Note (optional)", "GameFontDisable")
  noteHint:SetPoint("LEFT", 2, 0)
  noteBox:SetScript("OnTextChanged", function(self) noteHint:SetShown(self:GetText() == "") end)
  noteBox:SetScript("OnEscapePressed", noteBox.ClearFocus)
  noteBox:SetScript("OnEnterPressed", noteBox.ClearFocus)

  local function Picked()
    local ids = {}
    for id in pairs(selected) do ids[#ids + 1] = id end
    return ids
  end
  local keep = UI.Button(body, "Keep", 90, 22, function()
    local ids = Picked()
    if #ids == 0 then Say("select some items first") return end
    local note = noteBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
    for _, id in ipairs(ids) do DB()[id] = note ~= "" and note or DB()[id] or "" end
    Say("keeping " .. #ids .. (#ids == 1 and " item" or " items"))
    noteBox:SetText("")
    noteBox:ClearFocus()
    wipe(selected)
    f.Update()
  end)
  keep:SetPoint("LEFT", noteBox, "RIGHT", 8, 0)
  local unkeep = UI.Button(body, "Don't keep", 100, 22, function()
    local ids = Picked()
    if #ids == 0 then Say("select some items first") return end
    local n = 0
    for _, id in ipairs(ids) do
      if DB()[id] then DB()[id] = nil; n = n + 1 end
    end
    Say("no longer keeping " .. n .. (n == 1 and " item" or " items"))
    wipe(selected)
    f.Update()
  end)
  unkeep:SetPoint("LEFT", keep, "RIGHT", 6, 0)

  local bind = UI.Text(body, "Also: a key for \"Keep / unkeep hovered item\" in Key Bindings > "
    .. "TooltipExtras, or /tte keep <item> [note] in chat.", "GameFontHighlightSmall")
  bind:SetPoint("TOPLEFT", all, "BOTTOMLEFT", 0, -10)
  bind:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  bind:SetJustifyH("LEFT")

  function f.Count()
    local n = 0
    for _ in pairs(selected) do n = n + 1 end
    count:SetText(n > 0 and (n .. " selected") or "")
  end

  function f.Update()
    local bags = Scan(BagIDs(), {})
    local bank, seen = BankItems()
    local ids = {}
    for id in pairs(bags) do ids[id] = true end
    for id in pairs(bank) do ids[id] = true end
    for id in pairs(DB()) do ids[id] = true end
    local info = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local data = {}
    for id in pairs(ids) do
      local name, link, _, _, _, _, _, stack, _, _, _, _, _, bindType = GetItemInfo(id)
      local _, _, _, equipLoc, icon, classID = info(id)
      local b, k = bags[id], bank[id]
      local bound = (b and b.bound) or (k and k.bound) or bindType == 1 or bindType == 4
      local questItem = classID == 12 or bindType == 4
      local unique = stack == 1
      local kept = DB()[id]
      local lines, questLike = {}, false
      if ns.QuestStatus then lines, questLike = ns.QuestStatus(id, questItem, bound, unique) end
      local e = {
        id = id, name = name or ("item " .. id), link = link, icon = icon,
        bags = b and b.n or 0, bank = k and k.n or 0, status = lines[1],
      }
      local show
      if filter == "kept" then show = kept ~= nil
      elseif filter == "quest" then
        show = kept ~= nil or questLike or #lines > 0
          or (bound and (equipLoc == nil or equipLoc == "") and (unique or classID == KEY_CLASS))
      else show = true end
      if show and search ~= "" and not e.name:lower():find(search, 1, true) then show = false end
      if show then data[#data + 1] = e end
    end
    table.sort(data, function(a, c) return a.name < c.name end)
    -- drop selections that are filtered out, so Keep only touches rows you can see
    local visible = {}
    for _, e in ipairs(data) do visible[e.id] = true end
    for id in pairs(selected) do if not visible[id] then selected[id] = nil end end
    list:SetData(data)
    empty:SetShown(#data == 0)
    bankNote:SetText(atBank and "Bank: open now"
      or seen and ("Bank: as of your last visit, " .. date("%d %b %H:%M", seen))
      or "Bank: open it once to list it")
    f.Count()
  end
  f:HookScript("OnShow", function()
    wipe(selected)
    last = nil
    f.Update()
  end)

  f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  f:RegisterEvent("BAG_UPDATE_DELAYED")
  local pending
  f:SetScript("OnEvent", function(self)
    if not self:IsShown() or pending then return end
    -- item info arrives in bursts: one refresh for the lot
    pending = true
    C_Timer.After(0.2, function()
      pending = nil
      if self:IsShown() then self.Update() end
    end)
  end)
  return f
end

-- bank snapshot
local bankEvents = CreateFrame("Frame")
bankEvents:RegisterEvent("BANKFRAME_OPENED")
bankEvents:RegisterEvent("BANKFRAME_CLOSED")
bankEvents:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
bankEvents:RegisterEvent("BAG_UPDATE_DELAYED")
bankEvents:SetScript("OnEvent", function(_, event)
  if event == "BANKFRAME_OPENED" then
    atBank = true
    SaveBank()
  elseif event == "BANKFRAME_CLOSED" then
    atBank = false
  else
    SaveBank()
  end
  Refresh()
end)

function ns.OpenKeepList()
  window = window or Build()
  window:Show()
end

ns.slash = ns.slash or {}
ns.slash.keep = function(arg)
  arg = arg or ""
  local id = IDOf(arg)
  if not id then
    ns.OpenKeepList()
    return
  end
  -- whatever follows the link or ID is the note
  local note = arg:gsub("|c%x+|H.-|h.-|h|r", "", 1):gsub("^%s*%d+", "", 1)
  note = note:gsub("^%s+", ""):gsub("%s+$", "")
  Add(id, note)
end
ns.slash.unkeep = function(arg)
  local id = IDOf(arg)
  if id then Remove(id) else Say("/tte unkeep <item link or ID>") end
end
