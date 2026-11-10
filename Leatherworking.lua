-- Leatherworking: is it worth more after the craft? Two kinds of line, both on the item you have:
--   leather -> the next grade (Light -> Medium, ...): "Upgrade to Medium Leather"
--   hide + salt -> cured hide: "Cure Hide"
-- Recipes are Forever's (CraftRoute's LeatherworkingRecipes.lua). Salt is bought, so it counts
-- at its full auction price.
local ADDON, ns = ...

local SCRAPS = 2934
local SALT, DEEPROCK_SALT, REFINED_DEEPROCK_SALT = 4289, 8150, 15409
local HIDES = { [783] = true, [4232] = true, [4235] = true, [8169] = true, [8171] = true }

-- until the item names load
local NAMES = {
  [2318] = "Light Leather",
  [2319] = "Medium Leather",
  [4234] = "Heavy Leather",
  [4304] = "Thick Leather",
  [8170] = "Rugged Leather",
  [SALT] = "Salt",
  [DEEPROCK_SALT] = "Deeprock Salt",
  [REFINED_DEEPROCK_SALT] = "Refined Deeprock Salt",
}

ns.AddConverter({
  key = "leatherworking",
  label = "Leatherworking",
  tip = "On leather: whether upgrading it to the next grade (Light to Medium, up to Thick to Rugged) "
    .. "sells for more than the leather itself. On hides: whether curing them sells for more, "
    .. "with the salt at its auction price.",
  toLabel = function(r)
    if HIDES[r.input] then return "Cure Hide" end
    return "Upgrade to " .. (ns.ItemName(r.output) or NAMES[r.output] or "next leather")
  end,
  input = function(r)
    if HIDES[r.input] then return "hide" end
    return r.input == SCRAPS and "scraps" or "leather"
  end,
  output = function(r)
    if HIDES[r.input] then return r.makes > 1 and "cured hides" or "cured hide" end
    return "upgrade"
  end,
  names = NAMES,
  -- item, how many per craft, result, extra reagents, results per craft
  recipes = {
    { SCRAPS, 3, 2318 }, -- Ruined Leather Scraps -> Light
    { 2318, 4, 2319 },   -- Light -> Medium
    { 2319, 5, 4234 },   -- Medium -> Heavy
    { 4234, 6, 4304 },   -- Heavy -> Thick
    { 4304, 6, 8170 },   -- Thick -> Rugged

    { 783, 1, 4231, { { SALT, 1 } } },                     -- Light Hide
    { 4232, 1, 4233, { { SALT, 1 } } },                    -- Medium Hide
    { 4235, 1, 4236, { { SALT, 3 } } },                    -- Heavy Hide
    { 8169, 1, 8172, { { DEEPROCK_SALT, 1 } } },           -- Thick Hide
    { 8171, 1, 15407, { { REFINED_DEEPROCK_SALT, 1 } }, 2 }, -- Rugged Hide, makes 2 (Tanning Rack)
  },
})
