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

function ns.AddConverter(c)
  local byInput = {} -- input itemID -> recipe
  for _, row in ipairs(c.recipes) do
    byInput[row[1]] = { input = row[1], count = row[2], output = row[3], extras = row[4] or {},
      makes = row[5] or 1 }
  end

  ns.AddModule({
    key = c.key,
    label = c.label,
    tip = c.tip,
    OnItem = function(tooltip, id)
      local r = byInput[id]
      if not r then return false end
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
      local label = Text(c.toLabel, r) .. RecipeNote(c, r) .. age
      tooltip:AddLine(" ")
      ns.ProfitLine(tooltip, label, profit)
      return true
    end,
  })
end
