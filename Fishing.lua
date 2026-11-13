-- Fishing (WoW Forever): on a raw fish, the best zones to catch it, with the fish's share of all
-- catches in each zone and the zone's fishing skill. The skill is coloured by whether yours
-- catches it there (green), only with a lure (yellow) or not even then (red). Fish that come
-- from schools (pools) name the school.
-- Catch share = the fish's count / every catch in the zone's fishing loot table on Wowhead
-- Forever (read Nov 2026). Zones with under 200 recorded catches are left out, then up to 3
-- zones, best first, dropping any under a quarter of the best zone's share.
-- Zone skill is the skill that stops fish getting away, from the classic zone table, which
-- matches Wowhead's Forever fishing guide (starter 25, cities 75, STV/Dustwallow 225, Tanaris
-- 300). nil = not known (new Forever zones).
local ADDON, ns = ...

local ZONES = {
  [1] = { "Dun Morogh", 25 },        [12] = { "Elwynn Forest", 25 },
  [14] = { "Durotar", 25 },          [85] = { "Tirisfal Glades", 25 },
  [141] = { "Teldrassil", 25 },      [215] = { "Mulgore", 25 },
  [1497] = { "Undercity", 75 },      [1519] = { "Stormwind City", 75 },
  [1537] = { "Ironforge", 75 },      [1637] = { "Orgrimmar", 75 },
  [1638] = { "Thunder Bluff", 75 },  [1657] = { "Darnassus", 75 },
  [17] = { "The Barrens", 75 },      [38] = { "Loch Modan", 75 },
  [40] = { "Westfall", 75 },         [130] = { "Silverpine Forest", 75 },
  [148] = { "Darkshore", 75 },
  [10] = { "Duskwood", 150 },        [11] = { "Wetlands", 150 },
  [44] = { "Redridge Mountains", 150 }, [267] = { "Hillsbrad Foothills", 150 },
  [331] = { "Ashenvale", 150 },      [406] = { "Stonetalon Mountains", 150 },
  [8] = { "Swamp of Sorrows", 225 }, [15] = { "Dustwallow Marsh", 225 },
  [33] = { "Stranglethorn Vale", 225 }, [36] = { "Alterac Mountains", 225 },
  [45] = { "Arathi Highlands", 225 }, [400] = { "Thousand Needles", 225 },
  [405] = { "Desolace", 225 },
  [16] = { "Azshara", 300 },         [357] = { "Feralas", 300 },
  [440] = { "Tanaris", 300 },        [28] = { "Western Plaguelands", 300 },
  [493] = { "Moonglade", 300 },
  [16591] = { "Riverglades" },       [16593] = { "Zephras Isle" },
  -- only in the classic fallback rows; skill not confirmed for Forever
  [41] = { "Deadwind Pass" },        [618] = { "Winterspring" },
  [139] = { "Eastern Plaguelands" },
}

-- itemID -> { zones = { { zoneID, catch % }, ... } best first, school = pool name, season }
-- zones = false: Wowhead Forever has no catch data for it yet.
local FISH = {
  [6291] = { zones = { { 12, 60 }, { 1, 60 }, { 16593, 59 } } },       -- Raw Brilliant Smallfish
  [6303] = { zones = { { 14, 52 }, { 141, 48 }, { 17, 14 } } },        -- Raw Slitherskin Mackerel
  [6289] = { zones = { { 1657, 60 }, { 1638, 60 }, { 1637, 60 } } },   -- Raw Longjaw Mud Snapper
  [6308] = { zones = { { 10, 59 }, { 44, 55 }, { 406, 43 } } },        -- Raw Bristle Whisker Catfish
  [6317] = { zones = { { 38, 21 } } },                                 -- Raw Loch Frenzy
  [6361] = { zones = { { 11, 39 }, { 17, 21 }, { 148, 18 } } },        -- Raw Rainbow Fin Albacore
  [12238] = { zones = { { 148, 29 } } },                               -- Darkshore Grouper
  [251524] = { zones = { { 44, 3 } }, school = "School of Whimsyfin" }, -- Whimsyfin (new in Forever)
  [6358] = { zones = { { 40, 30 }, { 11, 21 }, { 17, 20 } }, school = "Oily Blackmouth School" },
  [6359] = { zones = { { 11, 18 }, { 33, 11 }, { 440, 11 } }, school = "Firefin Snapper School" },
  [6522] = { zones = { { 17, 16 } }, school = "School of Deviate Fish" },
  [21071] = { zones = { { 267, 34 }, { 38, 20 }, { 406, 14 } }, school = "Sagefish School" },
  [21153] = { zones = { { 36, 37 }, { 16591, 16 } }, school = "Greater Sagefish School" },
  [6362] = { zones = { { 8, 42 }, { 33, 34 }, { 15, 25 } } },          -- Raw Rockscale Cod
  [4603] = { zones = { { 440, 35 }, { 16, 23 }, { 33, 12 } } },        -- Raw Spotted Yellowtail
  [8365] = { zones = { { 400, 61 }, { 45, 53 }, { 405, 51 } } },       -- Raw Mithril Head Trout
  [7973] = { zones = { { 440, 9 }, { 16, 4 } } },                      -- Big-mouth Clam
  [13422] = { zones = { { 440, 12 }, { 16591, 11 }, { 16, 5 } } },     -- Stonescale Eel
  [13754] = { zones = { { 440, 8 }, { 16, 6 } } },                     -- Raw Glossy Mightfish
  [13755] = { zones = { { 440, 9 }, { 16, 7 } }, season = "winter" },  -- Raw Winter Squid
  -- No Forever catch data yet: classic Wowhead's item catch rates (classic = true). Summer Bass
  -- keeps Tanaris, which the Forever fishing guide names, though classic's share is diluted
  -- by out-of-season casts.
  [13756] = { zones = { { 139, 20 }, { 440, 2 } }, season = "summer", classic = true },
  [13889] = { zones = { { 41, 40 }, { 618, 39 }, { 139, 37 } }, classic = true }, -- Whitescale Salmon
  [13888] = { zones = { { 139, 45 }, { 16, 26 } }, classic = true },   -- Darkclaw Lobster
  [13893] = { zones = { { 139, 8 }, { 16, 5 } }, classic = true },     -- Large Raw Mightfish
  [13757] = { zones = { { 357, 5 }, { 28, 4 }, { 493, 3 } } },         -- Lightning Eel
  [13758] = { zones = { { 28, 56 }, { 493, 45 }, { 357, 38 } } },      -- Raw Redgill
  [13759] = { zones = { { 493, 20 }, { 28, 10 }, { 357, 8 } } },       -- Raw Nightfin Snapper
  [13760] = { zones = { { 357, 15 }, { 28, 14 }, { 493, 11 } } },      -- Raw Sunscale Salmon
}
-- Raw Spinefin Halibut (8959) is left out: a mob drop in classic, no catches in Forever.

-- Fishing rank and bonus (pole, gear, active lure), or nil when not learned.
local function FishingSkill()
  if GetProfessions and GetProfessionInfo then
    local _, _, _, fishing = GetProfessions()
    if fishing then
      local _, _, rank, _, _, _, _, modifier = GetProfessionInfo(fishing)
      if rank then return rank, modifier or 0 end
    end
  end
  if GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local name, header, _, rank, _, modifier = GetSkillLineInfo(i)
      if not header and name == (PROFESSIONS_FISHING or "Fishing") then
        return rank, modifier or 0
      end
    end
  end
  return nil
end

-- Biggest lure this rank can use: Aquadynamic Fish Attractor (100 skill), Nightcrawlers (50),
-- Shiny Bauble (any).
local function BestLure(rank)
  if rank >= 100 then return 100 end
  if rank >= 50 then return 50 end
  return 25
end

local GREEN, YELLOW, RED = { 0.2, 1, 0.2 }, { 1, 0.82, 0 }, { 1, 0.33, 0.33 }
local PLAIN, GREY, HEADER = { 0.9, 0.9, 0.9 }, { 0.5, 0.5, 0.5 }, { 0.6, 0.6, 0.6 }
-- Column widths: the widest thing each column can hold (header included).
local COLUMNS = { { "catch", "100%" }, { "skill", "300" } }

ns.AddModule({
  key = "fishing",
  category = "professions",
  label = "Fishing",
  tip = "On a raw fish: the best zones to catch it, with its share of all catches there, the "
    .. "fishing skill each zone needs, and the school (pool) it comes from. The skill is green "
    .. "when you catch it there, yellow when you need a lure, red when not even then.",
  options = {
    { key = "zones", label = "Best zones and catch %", default = true,
      tip = "Catch % is the fish's share of everything caught in that zone, from Wowhead Forever's data." },
    { key = "colour", label = "Colour the skill by yours", default = true,
      tip = "Green, yellow (needs a lure) or red (out of reach), using your fishing skill with your pole and gear." },
    { key = "school", label = "Fishing schools", default = true },
  },
  OnItem = function(tooltip, id, db)
    local fish = FISH[id]
    if not fish then return false end
    local showZones, showSchool = db.zones ~= false, db.school ~= false and fish.school
    if not showZones and not showSchool then return false end

    local rank, modifier
    if db.colour ~= false then rank, modifier = FishingSkill() end

    tooltip:AddLine(" ")
    local head = ns.ProfessionTag("Fishing") .. (showZones and "best zones" or "")
    if showZones and fish.classic then head = head .. " |cff808080(classic data)|r" end

    if showZones and fish.zones then
      -- Header labels the two columns; every row uses the same samples so the % and the skill
      -- each right-align to a fixed edge.
      ns.TextLine(tooltip, head, { "catch", "skill" }, COLUMNS, 1, 0.82, 0, { HEADER, HEADER })
      local season = fish.season and (" (" .. fish.season .. ")") or ""
      for _, entry in ipairs(fish.zones) do
        local z = ZONES[entry[1]]
        if z then
          local need = z[2]
          local c = need and PLAIN or GREY
          if rank and need then
            local skill = rank + modifier
            if skill >= need then c = GREEN
            elseif skill + BestLure(rank) >= need then c = YELLOW
            else c = RED end
          end
          ns.TextLine(tooltip, "  " .. z[1] .. season,
            { entry[2] and (entry[2] .. "%") or "", tostring(need or "?") },
            COLUMNS, 0.9, 0.9, 0.9, { PLAIN, c })
        end
      end
    else
      tooltip:AddLine(head, 1, 0.82, 0)
    end
    if showSchool then
      tooltip:AddLine("  Schools: " .. fish.school, 0.41, 0.8, 0.94)
    end
    return true
  end,
})
