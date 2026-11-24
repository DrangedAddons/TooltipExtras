-- Items to keep: a list you add to by hand, for items like the Mallet of Zul'Farrak that no
-- quest needs but you want to hang on to. A kept item's tooltip says so (in blue, with your
-- note) instead of the orange / red "leftover" lines from Quest items.
-- Saved account-wide in TooltipExtrasDB.keep = { [itemID] = note ("" for none) }.
--
-- Add one: the window (/tte keep, or the button in the settings), /tte keep <item> [note],
-- or hover the item and press the "Keep / unkeep hovered item" key binding.
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
-- Window

local ROW_H, ROWS = 22, 14

local function Build()
  local f = UI.Window({ name = "TooltipExtrasKeep", title = "Items to keep", width = 560, height = 520 })
  local body = f.body

  local help = UI.Text(body, "Kept items say so on their tooltip and never show as a leftover. "
    .. "Shift-click an item into the box (or type its ID), add a note if you like, then Add. "
    .. "Right-click a row to remove it.", "GameFontHighlightSmall")
  help:SetPoint("TOPLEFT", 0, 0)
  help:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  help:SetJustifyH("LEFT")
  help:SetWordWrap(true)

  local itemBox = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  itemBox:SetSize(200, 20)
  itemBox:SetAutoFocus(false)
  itemBox:SetPoint("TOPLEFT", 6, -42)
  local itemLabel = UI.Text(body, "Item", "GameFontNormalSmall")
  itemLabel:SetPoint("BOTTOMLEFT", itemBox, "TOPLEFT", -4, 2)

  local noteBox = CreateFrame("EditBox", nil, body, "InputBoxTemplate")
  noteBox:SetSize(190, 20)
  noteBox:SetAutoFocus(false)
  noteBox:SetMaxLetters(60)
  noteBox:SetPoint("LEFT", itemBox, "RIGHT", 14, 0)
  local noteLabel = UI.Text(body, "Note (optional)", "GameFontNormalSmall")
  noteLabel:SetPoint("BOTTOMLEFT", noteBox, "TOPLEFT", -4, 2)

  local pending -- item ID from a shift-clicked link
  local function Submit()
    local id = pending or IDOf(itemBox:GetText())
    if not id then
      Say("shift-click an item into the Item box, or type its ID")
      return
    end
    local note = noteBox:GetText():gsub("^%s+", ""):gsub("%s+$", "")
    Add(id, note)
    pending = nil
    itemBox:SetText("")
    noteBox:SetText("")
    itemBox:ClearFocus()
    noteBox:ClearFocus()
  end
  local add = UI.Button(body, "Add", 70, 22, Submit)
  add:SetPoint("LEFT", noteBox, "RIGHT", 10, 0)
  itemBox:SetScript("OnEnterPressed", function() noteBox:SetFocus() end)
  itemBox:SetScript("OnTextChanged", function(self)
    local id = IDOf(self:GetText())
    if id ~= pending then pending = nil end
  end)
  itemBox:SetScript("OnEscapePressed", itemBox.ClearFocus)
  noteBox:SetScript("OnEnterPressed", Submit)
  noteBox:SetScript("OnEscapePressed", noteBox.ClearFocus)

  -- Shift-clicking an item while the Item box has focus puts the link there
  hooksecurefunc("ChatEdit_InsertLink", function(link)
    if itemBox:HasFocus() and type(link) == "string" then
      local id = IDOf(link)
      if id then
        pending = id
        itemBox:SetText(link)
      end
    end
  end)

  local function Render(row, item)
    local _, _, _, _, icon = (C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant)(item.id)
    local text = Label(item.id)
    if item.note ~= "" then text = text .. "  |cff999999" .. item.note .. "|r" end
    UI.RenderRow(row, text, icon)
  end
  local list = UI.List(body, 524, ROW_H, ROWS, Render, function(_, item, mouse)
    if mouse == "RightButton" then Remove(item.id) end
  end)
  list:SetPoint("TOPLEFT", 0, -76)
  for _, r in ipairs(list.rows) do
    r:SetScript("OnEnter", function(self)
      if not self.item then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.item.id)
      GameTooltip:Show()
    end)
    r:SetScript("OnLeave", GameTooltip_Hide)
  end

  local empty = UI.Text(body, "Nothing kept yet.", "GameFontDisable")
  empty:SetPoint("TOP", list, "TOP", 0, -20)

  local bind = UI.Text(body, "Faster: set a key for \"Keep / unkeep hovered item\" in Key Bindings "
    .. "> TooltipExtras, then hover an item and press it.", "GameFontHighlightSmall")
  bind:SetPoint("TOPLEFT", list, "BOTTOMLEFT", 0, -10)
  bind:SetPoint("RIGHT", body, "RIGHT", 0, 0)
  bind:SetJustifyH("LEFT")
  bind:SetWordWrap(true)

  function f.Update()
    local data = {}
    for id, note in pairs(DB()) do
      data[#data + 1] = { id = id, note = type(note) == "string" and note or "",
        name = GetItemInfo(id) or ("~" .. id) }
    end
    table.sort(data, function(a, b) return a.name < b.name end)
    list:SetData(data)
    empty:SetShown(#data == 0)
  end
  f:HookScript("OnShow", f.Update)

  -- names that weren't cached yet
  f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  f:SetScript("OnEvent", function(self) if self:IsShown() then self.Update() end end)
  return f
end

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
