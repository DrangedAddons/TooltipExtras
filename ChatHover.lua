-- Chat links: hovering an item, recipe, spell, quest, achievement or currency link in a chat
-- window shows its tooltip, like clicking it, and the tooltip goes away when the mouse leaves.
-- It uses GameTooltip owned by the chat frame, so other modules can tell a chat hover apart from
-- a bag or profession-window hover (ns.IsChatHover).
--
-- Chattynator replaces the chat windows and shows hover tooltips itself, so with it loaded this
-- module shows nothing and only recognises Chattynator's hovers for ns.IsChatHover.
local ADDON, ns = ...

local MODULE = {
  key = "chathover",
  category = "other",
  label = "Chat links",
  tip = "Hover a link in chat to see its tooltip without clicking it. "
    .. "Recipe reagent lists show on these too. With Chattynator, its own hover tooltips are "
    .. "used instead and get the reagent lists.",
  options = { { key = "hover", label = "Show chat links on hover", default = true } },
}
ns.AddModule(MODULE)

-- Link types GameTooltip:SetHyperlink can show. Player names, channels and the like are left out.
local KINDS = { item = true, enchant = true, spell = true, quest = true, achievement = true,
  currency = true, talent = true }

local hooked = {} -- chat frame -> true

local function Enabled()
  local db = ns.ModuleDB(MODULE)
  return db.enabled and db.hover ~= false
end

-- Chattynator's link frame; its chat windows are children of it.
local function Chattynator()
  return ChattynatorHyperlinkHandler
end

local function MouseOver()
  if GetMouseFoci then return (GetMouseFoci())[1] end
  return GetMouseFocus and GetMouseFocus()
end

-- True while the mouse is over a Chattynator chat window and GameTooltip has the owner
-- Chattynator gives its link tooltips (the link frame's parent).
local function IsChattynatorHover()
  local handler = Chattynator()
  if not handler or GameTooltip:GetOwner() ~= handler:GetParent() then return false end
  local f = MouseOver()
  while f do
    if f == handler then return true end
    f = f.GetParent and f:GetParent()
  end
  return false
end

function ns.IsChatHover(tooltip)
  if tooltip ~= GameTooltip or not Enabled() then return false end
  if hooked[tooltip:GetOwner()] then return true end
  return IsChattynatorHover()
end

local function OnEnter(frame, link)
  if not Enabled() or Chattynator() or type(link) ~= "string" then return end
  local kind = link:match("^(%a+):")
  if not KINDS[kind] then return end
  GameTooltip:SetOwner(frame, "ANCHOR_CURSOR")
  if pcall(GameTooltip.SetHyperlink, GameTooltip, link) then
    GameTooltip:Show()
  else
    GameTooltip:Hide()
  end
end

local function OnLeave(frame)
  if GameTooltip:GetOwner() == frame then GameTooltip:Hide() end
end

local function Hook(frame)
  if not frame or hooked[frame] then return end
  hooked[frame] = true
  frame:HookScript("OnHyperlinkEnter", OnEnter)
  frame:HookScript("OnHyperlinkLeave", OnLeave)
end

local function HookAll()
  for i = 1, NUM_CHAT_WINDOWS or 10 do Hook(_G["ChatFrame" .. i]) end
  for _, name in ipairs(CHAT_FRAMES or {}) do Hook(_G[name]) end
end

HookAll()
-- Whisper tabs and other temporary windows are made later.
if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", HookAll) end
