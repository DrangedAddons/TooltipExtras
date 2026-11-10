-- Leatherworking: is leather worth more upgraded to the next grade? Each leather's line is for
-- its own upgrade (Light -> Medium, ...). Recipes are Forever's (CraftRoute's LeatherworkingRecipes.lua).
local ADDON, ns = ...

local SCRAPS = 2934

-- until the item names load
local NAMES = {
  [2318] = "Light Leather",
  [2319] = "Medium Leather",
  [4234] = "Heavy Leather",
  [4304] = "Thick Leather",
  [8170] = "Rugged Leather",
}

ns.AddConverter({
  key = "leatherworking",
  label = "Leatherworking",
  tip = "On leather: whether upgrading it to the next grade (Light to Medium, up to Thick to Rugged) "
    .. "sells for more than the leather itself, as profit or loss per upgraded leather.",
  toLabel = function(r) return "Upgrade to " .. (ns.ItemName(r.output) or NAMES[r.output] or "next leather") end,
  input = function(r) return r.input == SCRAPS and "scraps" or "leather" end,
  output = "upgrade",
  -- leather, how many per upgrade, upgraded leather
  recipes = {
    { SCRAPS, 3, 2318 }, -- Ruined Leather Scraps -> Light
    { 2318, 4, 2319 },   -- Light -> Medium
    { 2319, 5, 4234 },   -- Medium -> Heavy
    { 4234, 6, 4304 },   -- Heavy -> Thick
    { 4304, 6, 8170 },   -- Thick -> Rugged
  },
})
