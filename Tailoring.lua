-- Tailoring: is cloth worth more as bolts? Recipes are Forever's (CraftRoute's TailoringRecipes.lua).
local ADDON, ns = ...

ns.AddConverter({
  key = "tailoring",
  label = "Tailoring",
  tip = "On cloth: whether weaving the cloth into bolts sells for more than the cloth itself, "
    .. "as profit or loss per bolt.",
  toLabel = "Weave to Bolt",
  features = { { key = "bolts", label = "Cloth to bolts" } },
  input = "cloth",
  output = "bolt",
  -- cloth, cloth per bolt, bolt
  recipes = {
    { 2589, 2, 2996 },   -- Linen
    { 2592, 3, 2997 },   -- Wool
    { 4306, 4, 4305 },   -- Silk
    { 4338, 5, 4339 },   -- Mageweave
    { 14047, 5, 14048 }, -- Runecloth
  },
})
