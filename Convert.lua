-- Shared "is it worth converting?" module for one-way crafts like ore -> bar or cloth -> bolt.
-- One tooltip line on the input only (the output can't be turned back): profit or loss per
-- output from converting what you already have instead of selling it. Prices from Auctionator.
--
--   ns.AddConverter{ key, label, tip,
--     toLabel = "Smelt to Bar", input = "ore", output = "bar",
--     recipes = { { inputID, inputsPerCraft, outputID, { {extraID, count}, ... }, makes }, ... } }
--
-- makes (default 1) is how many outputs one craft gives; profit is then per craft.
-- toLabel, input and output can also be function(recipe) -> string, for text that changes per
-- recipe (Leatherworking names the next leather).
-- Extra reagents (Coal) are bought for the craft, so they count at full auction price.
--
-- features = { { key, label, tip }, ... } are the module's sub-options on the settings page
-- (default one, "convert"). featureOf(recipe) -> key says which one a recipe belongs to
-- (default the first).
local ADDON, ns = ...

local function Text(v, r)
  if type(v) == "function" then return v(r) end
  return v
end

-- " (5 cloth per bolt)" / " (2 ore + Coal per bar)" / " (1 hide + Salt per 2 cured hides)";
-- "" for a plain 1:1.
local function RecipeNote(c, r)
  if r.count == 1 and #r.extras == 0 and r.makes == 1 then return "" end
  local parts = { r.count .. " " .. Text(c.input, r) }
  for _, x in ipairs(r.extras) do
    local name = ns.ItemName(x[1]) or (c.names and c.names[x[1]]) or "?"
    parts[#parts + 1] = (x[2] > 1 and (x[2] .. " ") or "") .. name
  end
  return " |cff808080(" .. table.concat(parts, " + ") .. " per " .. (r.makes > 1 and (r.makes .. " ") or "") .. Text(c.output, r) .. ")|r"
end

-- The last converter line added, so a second converter on the same item (stone: grinding stone
-- and blasting powder) sits right under the first instead of after another blank line.
local last = {}

function ns.AddConverter(c)
  local byInput = {} -- input itemID -> recipe
  for _, row in ipairs(c.recipes) do
    byInput[row[1]] = { input = row[1], count = row[2], output = row[3], extras = row[4] or {},
      makes = row[5] or 1 }
  end

  local features = c.features or { { key = "convert", label = Text(c.toLabel, {}) } }
  local options = {}
  for _, f in ipairs(features) do
    options[#options + 1] = { key = f.key, label = f.label, tip = f.tip, default = true }
  end

  ns.AddModule({
    key = c.key,
    label = c.label,
    category = c.category or "professions",
    tip = c.tip,
    options = options,
    OnItem = function(tooltip, id, db)
      local r = byInput[id]
      if not r then return false end
      local feature = c.featureOf and c.featureOf(r) or features[1].key
      if db[feature] == false then return false end
      local ip, op = ns.Price(r.input), ns.Price(r.output)
      -- You sell either the inputs or the output, so the AH cut hits both.
      local profit
      if ip and op then
        profit = (op * r.makes - ip * r.count) * ns.Keep()
        for _, x in ipairs(r.extras) do
          local xp = ns.Price(x[1])
          if not xp then profit = nil break end
          profit = profit - xp * x[2]
        end
      end
      local age = ""
      if profit then
        -- Auctionator already shows the hovered item's age; flag the others.
        local others = { r.output }
        for _, x in ipairs(r.extras) do others[#others + 1] = x[1] end
        age = ns.Age(unpack(others))
      end
      local label = ns.ProfessionTag(c.label) .. Text(c.toLabel, r) .. RecipeNote(c, r) .. age
      if not (last.tooltip == tooltip and last.id == id and last.lines == tooltip:NumLines()) then
        tooltip:AddLine(" ")
      end
      ns.ProfitLine(tooltip, label, profit)
      last.tooltip, last.id, last.lines = tooltip, id, tooltip:NumLines()
      return true
    end,
  })
end
