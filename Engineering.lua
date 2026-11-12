-- Engineering: is stone worth more ground into blasting powder? Line on the stone only, since
-- powder can't be turned back. Recipes are Forever's (CraftRoute's EngineeringRecipes.lua).
local ADDON, ns = ...

ns.AddConverter({
  key = "engineering",
  label = "Engineering",
  tip = "On stone: whether making it into blasting powder sells for more than the stone itself, "
    .. "as profit or loss per powder.",
  toLabel = "Make Blasting Powder",
  input = "stone",
  output = "powder",
  -- stone, stones per powder, blasting powder
  recipes = {
    { 2835, 1, 4357 },   -- Rough
    { 2836, 1, 4364 },   -- Coarse
    { 2838, 1, 4377 },   -- Heavy
    { 7912, 2, 10505 },  -- Solid
    { 12365, 2, 15992 }, -- Dense
  },
})
