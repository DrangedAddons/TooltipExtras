-- Mage Comprehension scrolls (WoW Forever): an untranslated scroll ("Scroll: TOPAZ YORAK")
-- deciphers into a random mage scroll from its tier's pool. The tier is the scroll's
-- "Requires Comprehension (N)" line, so this reads that line instead of keeping every item ID.
-- Pools are from the zockify.com Forever Comprehension guide (beta data).
local ADDON, ns = ...

-- Comprehension requirement -> { { result, short effect }, ... }
local POOLS = {
  [1] = {
    { "Imbue Lesser Flame", "staff: up to +4 Fire damage" },
    { "Imbue Chillknife", "dagger: chance to chill on hit" },
    { "Rat Familiar", "+2 Intellect, 1 hr" },
    { "Scroll of Minor Evocation", "300 mana over 4 sec" },
    { "Scroll of Comprehension", "+15 Comprehension, 1 hr" },
  },
  [15] = {
    { "Imbue Frost", "staff: up to +8 Frost damage" },
    { "Imbue Striking", "staff: spells may fire Arcane Missile" },
    { "Imbue Baleflame", "staff: target -2 Fire resistance" },
    { "Imbue Iceknife", "dagger: chance to freeze on hit" },
    { "Imbue Spark", "sword: hits on you may reset Fire Blast" },
    { "Frog Familiar", "+6 Intellect, 1 hr" },
    { "Confuse Beast", "beast deals 15% less to you, 20 sec" },
    { "Cryoblast", "115-129 Frost damage around you" },
    { "Scroll of the Saber", "Blade of Silverlaine to Coldflame Saber" },
  },
  [50] = {
    { "Imbue Accuracy", "staff: +0.5% spell hit" },
    { "Imbue Quickening", "staff: spells may speed up wand" },
    { "Imbue Balefrost", "staff: target -3 Frost resistance" },
    { "Imbue Flame", "staff: up to +12 Fire damage" },
    { "Imbue Manablade", "dagger: chance to restore mana on hit" },
    { "Cat Familiar", "+12 Intellect, 1 hr" },
    { "Rebuke Elemental", "elemental takes 15% more, 20 sec" },
    { "Khadgar's Unlocking", "opens locks up to 125" },
    { "Scroll of the Blade", "Hypnotic Blade to Narpas Sword" },
  },
  [175] = {
    { "Imbue Greater Flame", "staff: up to +20 Fire damage" },
    { "Imbue Greater Frost", "staff: up to +20 Frost damage" },
    { "Imbue Precision", "staff: +1% crit" },
    { "Imbue Spellbreak", "effect not known yet" },
    { "Greater Cryoblast", "448-568 Frost damage around you" },
  },
}

-- The N in "Requires Comprehension (N)" on this tooltip, or nil.
local function ComprehensionTier(tooltip)
  local name = tooltip:GetName()
  if not name then return nil end
  for i = 1, tooltip:NumLines() do
    local fs = _G[name .. "TextLeft" .. i]
    local text = fs and fs:GetText()
    local n = type(text) == "string" and text:match("Comprehension %((%d+)%)")
    if n then return tonumber(n) end
  end
  return nil
end

ns.AddModule({
  key = "magescrolls",
  category = "classes",
  label = "Mage scrolls",
  tip = "On an untranslated mage scroll (Comprehension): the scrolls it can turn into when you "
    .. "decipher it. The result is random from the scroll's tier.",
  options = { { key = "results", label = "Possible deciphered scrolls", default = true } },
  OnItem = function(tooltip, id, db)
    if db.results == false then return false end
    local tier = ComprehensionTier(tooltip)
    local pool = tier and POOLS[tier]
    if not pool then return false end
    tooltip:AddLine(" ")
    tooltip:AddLine("Deciphers into one of (random):", 1, 0.82, 0)
    for _, r in ipairs(pool) do
      tooltip:AddDoubleLine(r[1], r[2], 0.41, 0.8, 0.94, 0.8, 0.8, 0.8)
    end
    return true
  end,
})
