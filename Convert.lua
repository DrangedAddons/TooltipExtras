-- Shared "is it worth converting?" module for one-way crafts like ore -> bar or cloth -> bolt.
-- One tooltip line on the input and on the output: profit or loss per output from converting
-- what you already have instead of selling it. Prices come from Auctionator.
--
--   ns.AddConverter{ key, label, tip,
--     toLabel = "Smelt to Bar", fromLabel = "Smelt from Ore", input = "ore", output = "bar",
--     recipes = { { inputID, inputsPerOutput, outputID, { {extraID, count}, ... } }, ... } }
--
-- Extra reagents (Coal) are bought for the craft, so they count at full auction price.
local ADDON, ns = ...

-- " (5 cloth per bolt)" / " (2 ore + Coal per bar)"; "" for a plain 1:1.
local function RecipeNote(c, r)
  if r.count == 1 and #r.extras == 0 then return "" end
  local parts = { r.count .. " " .. c.input }
  for _, x in ipairs(r.extras) do
    local name = ns.ItemName(x[1]) or (c.names and c.names[x[1]]) or "?"
    parts[#parts + 1] = (x[2] > 1 and (x[2] .. " ") or "") .. name
  end
  return " |cff808080(" .. table.concat(parts, " + ") .. " per " .. c.output .. ")|r"
end

function ns.AddConverter(c)
  local byItem = {} -- itemID -> { recipe, isOutput }
  for _, row in ipairs(c.recipes) do
    local r = { input = row[1], count = row[2], output = row[3], extras = row[4] or {} }
    byItem[r.input] = { recipe = r, isOutput = false }
    byItem[r.output] = { recipe = r, isOutput = true }
  end

  ns.AddModule({
    key = c.key,
    label = c.label,
    tip = c.tip,
    OnItem = function(tooltip, id)
      local e = byItem[id]
      if not e then return false end
      local r = e.recipe
      local ip, op = ns.Price(r.input), ns.Price(r.output)
      -- You sell either the inputs or the output, so the AH cut hits both.
      local profit
      if ip and op then
        profit = (op - ip * r.count) * ns.Keep()
        for _, x in ipairs(r.extras) do
          local xp = ns.Price(x[1])
          if not xp then profit = nil break end
          profit = profit - xp * x[2]
        end
      end
      local age = ""
      if profit then
        -- Auctionator already shows the hovered item's age; flag the others.
        local others = { e.isOutput and r.input or r.output }
        for _, x in ipairs(r.extras) do others[#others + 1] = x[1] end
        age = ns.Age(unpack(others))
      end
      local label = (e.isOutput and c.fromLabel or c.toLabel) .. RecipeNote(c, r) .. age
      tooltip:AddLine(" ")
      ns.ProfitLine(tooltip, label, profit)
      return true
    end,
  })
end
