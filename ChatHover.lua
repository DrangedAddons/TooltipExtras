-- Chat links: hovering an item, recipe, spell, quest, achievement or currency link in a chat
-- window shows its tooltip, like clicking it, and the tooltip goes away when the mouse leaves.
-- It uses GameTooltip owned by the chat frame, so other modules can tell a chat hover apart from
-- a bag or profession-window hover (ns.IsChatHover).
local ADDON, ns = ...

local MODULE = {
  key = "chathover",
  category = "other",
  label = "Chat links",
  tip = "Hover a link in chat to see its tooltip without clicking it. "
    .. "Recipe reagent lists show on these too.",
  options = { { key = "hover", label = "Show chat links on hover", default = true } },
}
ns.AddModule(MODULE)

-- Link types GameTooltip:SetHyperlink can show. Player names, channels and the like are left out.
local KINDS = { item = true, enchant = true, spell = true, quest = true, achievement = true,
  currency = true, talent = true }

local hooked = {} -- chat frame -> true

function ns.IsChatHover(tooltip)
  return tooltip == GameTooltip and hooked[tooltip:GetOwner()] == true
end

local function Enabled()
  local db = ns.ModuleDB(MODULE)
  return db.enabled and db.hover ~= false
end

local function OnEnter(frame, link)
  if not Enabled() or type(link) ~= "string" then return end
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
