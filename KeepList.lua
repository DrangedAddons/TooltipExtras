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

-- Forever has C_Item.GetItemInfo; the old global may be gone
local GetInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

local function Say(msg) print("|cff33ff99TooltipExtras|r " .. msg) end

local function IDOf(text)
  if type(text) ~= "string" then return nil end
  return tonumber(text:match("item:(%d+)")) or tonumber(text:match("^%s*(%d+)"))
end

local function Label(id)
  local name, link = GetInfo(id)
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
  -- the keyring, where keys like Lamora's Key and the Mallet of Zul'Farrak live
  local keyring = (Enum and Enum.BagIndex and Enum.BagIndex.Keyring) or KEYRING_CONTAINER
  if keyring then t[#t + 1] = keyring end
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
-- Window: your bags and bank as item tiles. Click tiles to select, then Keep / Don't keep.
-- A tile's border is its status colour, the same as the tooltip line.

local TILE, GAP = 38, 5
local WHITE = "Interface\\Buttons\\WHITE8X8"
local KEY_CLASS = 13

local function Border(tile, size)
  local t = {}
  for i, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local tx = tile:CreateTexture(nil, "OVERLAY")
    tx:SetTexture(WHITE)
    if i <= 2 then
      tx:SetPoint(side .. "LEFT")
      tx:SetPoint(side .. "RIGHT")
      tx:SetHeight(size)
    else
      tx:SetPoint("TOP" .. side)
      tx:SetPoint("BOTTOM" .. side)
      tx:SetWidth(size)
    end
    t[i] = tx
  end
  return t
end

local function Color(edges, r, g, b, a)
  for _, tx in ipairs(edges) do
    if r then tx:SetVertexColor(r, g, b, a or 1); tx:Show() else tx:Hide() end
  end
end

local function Build()
  local f = UI.Window({ name = "TooltipExtrasKeep", title = "Items to keep", width = 780, height = 620 })
  local body = f.body
  local filter, search, selected, last = "quest", "", {}, nil
  local data = {}

  local help = UI.Text(body, "Click items to select them (Shift-click for a range), then Keep or "
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

  -- tiles like a bag, or a list that has room for each item's note and status
  local function View() return TooltipExtrasDB and TooltipExtrasDB.keepView or "tiles" end
  local view = UI.Dropdown(body, 110, function()
    return { { value = "tiles", label = "Tiles" }, { value = "list", label = "List" } }
  end, View, function(v)
    TooltipExtrasDB = TooltipExtrasDB or {}
    TooltipExtrasDB.keepView = v
    f.Layout()
  end)
  view:SetPoint("LEFT", searchBox, "RIGHT", 16, 0)

  local bankNote = UI.Text(body, "", "GameFontHighlightSmall")
  bankNote:SetPoint("LEFT", view, "RIGHT", 14, 0)
  bankNote:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  bankNote:SetJustifyH("RIGHT")

  -- the grid
  local box = CreateFrame("Frame", nil, body, "BackdropTemplate")
  UI.Backdrop(box, 0.03, 0.03, 0.035, 0.95)
  box:SetPoint("TOPLEFT", 0, -56)
  box:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  box:SetHeight(390)
  local inner = CreateFrame("Frame", nil, box)
  inner:SetPoint("TOPLEFT", 6, -6)
  inner:SetPoint("BOTTOMRIGHT", -4, 6)
  local scroll, content = UI.ScrollArea(inner, 720)
  local empty = UI.Text(box, "Nothing here.", "GameFontDisable")
  empty:SetPoint("TOP", 0, -30)
  f.empty = empty

  local tiles, heads = {}, {}
  local ar, ag, ab = ns.AccentColor()

  local function Select(e)
    local at
    for i, d in ipairs(data) do if d == e then at = i break end end
    if IsShiftKeyDown() and last and at then
      local want = not selected[e.id]
      for i = math.min(last, at), math.max(last, at) do selected[data[i].id] = want or nil end
    else
      selected[e.id] = not selected[e.id] or nil
    end
    last = at
    f.Paint()
  end

  local function Tile(i)
    local t = tiles[i]
    if t then return t end
    t = CreateFrame("Button", nil, content)
    t:SetSize(TILE, TILE)
    t.bg = t:CreateTexture(nil, "BACKGROUND")
    t.bg:SetAllPoints()
    t.bg:SetColorTexture(0.1, 0.1, 0.11, 1)
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetPoint("TOPLEFT", 2, -2)
    t.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    t.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    t.sel = t:CreateTexture(nil, "OVERLAY")
    t.sel:SetAllPoints(t.icon)
    t.sel:SetTexture(WHITE)
    t.sel:SetVertexColor(ar, ag, ab, 0.35)
    t.status = Border(t, 2)
    t.selEdge = Border(t, 2)
    for _, tx in ipairs(t.selEdge) do tx:SetDrawLayer("OVERLAY", 2) end
    t.count = t:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    t.count:SetPoint("BOTTOMRIGHT", -3, 3)
    t.kept = t:CreateTexture(nil, "OVERLAY")
    t.kept:SetSize(14, 14)
    t.kept:SetPoint("TOPRIGHT", 1, 1)
    -- "Bank" on items that are only in the bank; not carried at all is greyed
    t.where = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.where:SetPoint("TOPLEFT", 2, -2)
    t.where:SetTextColor(0.8, 0.8, 0.8)
    t.where:SetFont(t.where:GetFont(), 8, "OUTLINE")
    t.kept:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    -- list view only
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    t.name:SetPoint("LEFT", t.icon, "RIGHT", 6, 0)
    t.name:SetJustifyH("LEFT")
    t.name:SetWordWrap(false)
    t.info = t:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    t.info:SetPoint("RIGHT", -6, 0)
    t.info:SetWidth(330)
    t.info:SetJustifyH("RIGHT")
    t.info:SetWordWrap(false)
    t.name:SetPoint("RIGHT", t.info, "LEFT", -8, 0)
    t:SetHighlightTexture(WHITE)
    t:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12)
    t:RegisterForClicks("LeftButtonUp")
    t:SetScript("OnClick", function(self) if self.e then Select(self.e) end end)
    t:SetScript("OnEnter", function(self)
      if not self.e then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.e.id)
      GameTooltip:Show()
    end)
    t:SetScript("OnLeave", GameTooltip_Hide)
    tiles[i] = t
    return t
  end

  local function Head(i)
    local h = heads[i]
    if not h then
      h = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      heads[i] = h
    end
    return h
  end

  function f.Paint()
    local n = 0
    for _, t in ipairs(tiles) do
      local e = t:IsShown() and t.e
      if e then
        local on = selected[e.id] == true
        t.sel:SetShown(on)
        Color(t.selEdge, on and 1 or nil, 1, 1, 1)
      end
    end
    for _ in pairs(selected) do n = n + 1 end
    f.count:SetText(n > 0 and (n .. " selected") or "")
  end

  -- sections by status, in order: { key, heading, colour }
  local SECTIONS = {
    { "kept", "Kept", "33ccff" },
    { "needed", "Needed for a quest", "33ccff" },
    { "waiting", "For a quest you haven't picked up", "99bfe6" },
    { "unused", "No quest uses it", "ff9933" },
    { "delete", "Safe to delete", "ff4040" },
    { "other", "Other items", "ffffff" },
  }

  function f.Layout()
    local width = content:GetWidth()
    local list = View() == "list"
    local cols = list and 1 or math.max(1, math.floor((width + GAP) / (TILE + GAP)))
    local ROW = 24
    local y, ti, hi = 0, 0, 0
    for _, sec in ipairs(SECTIONS) do
      local n = 0
      for _, e in ipairs(data) do
        if e.kind == sec[1] then n = n + 1 end
      end
      if n > 0 then
        hi = hi + 1
        local h = Head(hi)
        h:SetText("|cff" .. sec[3] .. sec[2] .. "|r |cff808080(" .. n .. ")|r")
        h:ClearAllPoints()
        h:SetPoint("TOPLEFT", 0, -y)
        h:Show()
        y = y + 20
        local col = 0
        for _, e in ipairs(data) do
          if e.kind == sec[1] then
            ti = ti + 1
            local t = Tile(ti)
            t.e = e
            t:ClearAllPoints()
            t.icon:ClearAllPoints()
            t.icon:SetTexture(e.icon or 134400)
            t.icon:SetDesaturated(e.where == "away")
            local total = e.bags + e.bank
            local st = e.status
            t.kept:SetShown(e.kept)
            if list then
              t:SetSize(width, ROW)
              t:SetPoint("TOPLEFT", 0, -y)
              t.sel:ClearAllPoints()
              t.sel:SetAllPoints(t)
              t.icon:SetPoint("LEFT", 2, 0)
              t.icon:SetSize(ROW - 4, ROW - 4)
              local where = {}
              if e.bags > 0 then where[#where + 1] = e.bags .. " in bags" end
              if e.bank > 0 then where[#where + 1] = e.bank .. " in bank" end
              if #where == 0 then where[1] = "not carried" end
              t.name:SetText((e.link or e.name) .. "  |cff808080" .. table.concat(where, ", ") .. "|r")
              t.info:SetText(st and st[1] or "")
              if st then t.info:SetTextColor(st[2], st[3], st[4]) end
              t.name:Show()
              t.info:Show()
              t.count:SetText("")
              t.where:SetText("")
              Color(t.status, nil)
              t.kept:ClearAllPoints()
              t.kept:SetPoint("CENTER", t.icon, "TOPRIGHT", -2, -2)
              y = y + ROW + 2
            else
              t:SetSize(TILE, TILE)
              t:SetPoint("TOPLEFT", col * (TILE + GAP), -y)
              t.sel:ClearAllPoints()
              t.sel:SetAllPoints(t.icon)
              t.icon:SetPoint("TOPLEFT", 2, -2)
              t.icon:SetPoint("BOTTOMRIGHT", -2, 2)
              t.name:Hide()
              t.info:Hide()
              t.count:SetText(total > 1 and total or "")
              t.where:SetText(e.where == "bank" and "Bank" or "")
              if st then Color(t.status, st[2], st[3], st[4], 1) else Color(t.status, nil) end
              t.kept:ClearAllPoints()
              t.kept:SetPoint("TOPRIGHT", 1, 1)
              col = col + 1
              if col >= cols then
                col = 0
                y = y + TILE + GAP
              end
            end
            t:Show()
          end
        end
        if not list and col > 0 then y = y + TILE + GAP end
        y = y + 8
      end
    end
    for i = ti + 1, #tiles do tiles[i]:Hide(); tiles[i].e = nil end
    for i = hi + 1, #heads do heads[i]:Hide() end
    scroll:SetContentHeight(math.max(y, 10))
    empty:SetShown(ti == 0)
    f.Paint()
  end

  -- actions
  f.count = UI.Text(body, "", "GameFontNormalSmall")
  f.count:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 2, -8)
  local legend = UI.Text(body, "Tick: on your keep list.  Bank: only in the bank.  Grey: not "
    .. "carried.", "GameFontHighlightSmall")
  legend:SetPoint("TOPRIGHT", box, "BOTTOMRIGHT", 0, -8)
  legend:SetJustifyH("RIGHT")

  local all = UI.Button(body, "Select all", 100, 22, function()
    for _, e in ipairs(data) do selected[e.id] = true end
    f.Paint()
  end)
  all:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -28)
  local none = UI.Button(body, "Select none", 100, 22, function()
    wipe(selected)
    f.Paint()
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

  local function Entry(id, bags, bank)
    local info = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    local name, link, _, _, _, _, _, stack, _, _, _, _, _, bindType = GetInfo(id)
    local _, _, _, equipLoc, icon, classID = info(id)
    local b, k = bags[id], bank[id]
    local bound = (b and b.bound) or (k and k.bound) or bindType == 1 or bindType == 4
    local unique = stack == 1
    local kept = DB()[id] ~= nil
    local lines, questLike = {}, false
    if ns.QuestStatus then
      local ok, l, q = pcall(ns.QuestStatus, id, classID == 12 or bindType == 4, bound, unique)
      if ok then lines, questLike = l or {}, q end
    end
    local e = {
      id = id, name = name or ("item " .. id), link = link, icon = icon, kept = kept,
      bags = b and b.n or 0, bank = k and k.n or 0, status = lines[1],
      where = b and "bags" or k and "bank" or "away",
    }
    -- section, from the status line's colour (QuestItems.lua's colours)
    local st = lines[1]
    if kept then e.kind = "kept"
    elseif not st then e.kind = "other"
    elseif st[2] < 0.3 then e.kind = "needed"     -- blue
    elseif st[2] < 0.7 then e.kind = "waiting"    -- pale blue
    elseif st[3] < 0.3 then e.kind = "delete"     -- red
    else e.kind = "unused" end                    -- orange
    local show
    if filter == "kept" then show = kept
    elseif filter == "quest" then
      show = kept or questLike or #lines > 0
        or (bound and (equipLoc == nil or equipLoc == "") and (unique or classID == KEY_CLASS))
    else show = true end
    if show and search ~= "" and not e.name:lower():find(search, 1, true) then show = false end
    return show and e or nil
  end

  local warned
  local function Update()
    local bags = Scan(BagIDs(), {})
    local bank, seen = BankItems()
    bankNote:SetText(atBank and "Bank: open now"
      or seen and ("Bank: as of your last visit, " .. date("%d %b %H:%M", seen))
      or "Bank: open it once to list it")
    local ids = {}
    for id in pairs(bags) do ids[id] = true end
    for id in pairs(bank) do ids[id] = true end
    for id in pairs(DB()) do ids[id] = true end
    data = {}
    for id in pairs(ids) do
      local e = Entry(id, bags, bank)
      if e then data[#data + 1] = e end
    end
    table.sort(data, function(a, c)
      if a.name ~= c.name then return a.name < c.name end
      return a.id < c.id
    end)
    -- drop selections that are filtered out, so Keep only touches what you can see
    local visible = {}
    for _, e in ipairs(data) do visible[e.id] = true end
    for id in pairs(selected) do if not visible[id] then selected[id] = nil end end
    f.Layout()
    local nb, nk = 0, 0
    for _ in pairs(bags) do nb = nb + 1 end
    for _ in pairs(bank) do nk = nk + 1 end
    f.empty:SetText(filter == "all" and "Nothing here." or ("Nothing here (" .. nb .. " kinds of item in "
      .. "your bags, " .. nk .. " in the bank). Try Everything."))
  end
  function f.Update()
    local ok, err = pcall(Update)
    if not ok and not warned then
      warned = true
      Say("keep window failed: " .. tostring(err))
    end
  end
  f:HookScript("OnShow", function()
    warned = nil
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
  -- opened from the /dranged window or Options: close that, so the two don't overlap
  if DrangedAddonsFrame and DrangedAddonsFrame:IsShown() then DrangedAddonsFrame:Hide() end
  if SettingsPanel and SettingsPanel:IsShown() then HideUIPanel(SettingsPanel) end
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
