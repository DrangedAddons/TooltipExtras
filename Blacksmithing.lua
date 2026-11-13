-- Blacksmithing: is stone worth more made into grinding stones? Line on the stone only, since
-- grinding stones can't be turned back. Recipes are Forever's (CraftRoute's BlacksmithingRecipes.lua).
local ADDON, ns = ...

ns.AddConverter({
  key = "blacksmithing",
  label = "Blacksmithing",
  tip = "On stone: whether making it into grinding stones sells for more than the stone itself, "
    .. "as profit or loss per grinding stone.",
  toLabel = "Make Grinding Stone",
  features = { { key = "grinding", label = "Stone to grinding stones" } },
  input = "stone",
  output = "grinding stone",
  -- stone, stones per grinding stone, grinding stone
  recipes = {
    { 2835, 2, 3470 },   -- Rough
    { 2836, 2, 3478 },   -- Coarse
    { 2838, 3, 3486 },   -- Heavy
    { 7912, 4, 7966 },   -- Solid
    { 12365, 4, 12644 }, -- Dense
  },
})
