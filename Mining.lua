-- Mining: is ore worth more smelted into bars? Smelts are Forever's (CraftRoute's MiningRecipes.lua).
local ADDON, ns = ...

local COAL = 3857

ns.AddConverter({
  key = "mining",
  label = "Mining",
  tip = "On ore: whether smelting the ore into bars sells for more than the ore itself, "
    .. "as profit or loss per bar. Extra reagents like Coal count at their auction price.",
  toLabel = "Smelt to Bar",
  features = { { key = "smelt", label = "Smelting ore to bars" } },
  input = "ore",
  output = "bar",
  names = { [COAL] = "Coal" }, -- until the item name loads
  -- ore, ores per bar, bar, extra reagents
  recipes = {
    { 2770, 1, 2840 },     -- Copper
    { 2771, 1, 3576 },     -- Tin
    { 2775, 1, 2842 },     -- Silver
    { 2772, 1, 3575 },     -- Iron
    { 2776, 1, 3577 },     -- Gold
    { 3858, 1, 3860 },     -- Mithril
    { 7911, 1, 6037 },     -- Truesilver
    { 11370, 8, 11371 },   -- Dark Iron (Black Forge)
    { 10620, 1, 12359 },   -- Thorium
    { 249426, 2, 249726, { { COAL, 1 } } }, -- Azerothium
    { 248815, 1, 251291 }, -- Heavy Thorium (Molten Foundry)
  },
})
