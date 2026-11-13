-- Fishing (WoW Forever): on a raw fish, the best zones to catch it, coloured by whether your
-- fishing skill catches it there (green), only with a lure (yellow) or not even then (red),
-- plus the school (pool) it comes from when there is one.
-- Zones and their order come from Wowhead Forever's "Fished in" data (Nov 2026): zones ranked by
-- catches / zone samples, zones with under 3000 samples or under a tenth of the best zone's rate
-- dropped. Zone skill is the skill that stops fish getting away, from the classic zone table,
-- which matches Wowhead's Forever fishing guide (starter 25, cities 75, STV/Dustwallow 225,
-- Tanaris 300).
local ADDON, ns = ...

-- Skill that catches every fish (no getaways).
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
  [16] = { "Azshara", 300 },         [47] = { "The Hinterlands", 300 },
  [357] = { "Feralas", 300 },        [440] = { "Tanaris", 300 },
  [28] = { "Western Plaguelands", 300 }, [493] = { "Moonglade", 300 },
}

-- itemID -> { zones = { zoneID, ... } best first, school = pool name, season = note }
-- zones = false: Wowhead Forever has no catch data for it yet.
local FISH = {
  [6291] = { zones = { 85, 1, 12 } },                 -- Raw Brilliant Smallfish
  [6303] = { zones = { 141, 14, 148 } },              -- Raw Slitherskin Mackerel
  [6289] = { zones = { 1638, 85, 1657 } },            -- Raw Longjaw Mud Snapper
  [6308] = { zones = { 44, 10, 406 } },               -- Raw Bristle Whisker Catfish
  [6317] = { zones = { 38 } },                        -- Raw Loch Frenzy
  [6361] = { zones = { 148, 130, 40 } },              -- Raw Rainbow Fin Albacore
  [6358] = { zones = { 40, 148, 130 }, school = "Oily Blackmouth School" },
  [6359] = { zones = { 406, 267, 11 }, school = "Firefin Snapper School" },
  [6522] = { zones = { 17 }, school = "School of Deviate Fish" },
  [21071] = { zones = { 267, 38, 130 }, school = "Sagefish School" },
  [21153] = { zones = { 36, 33 }, school = "Greater Sagefish School" },
  [6362] = { zones = { 33, 15, 45 } },                -- Raw Rockscale Cod
  [4603] = { zones = { 33, 440, 15 } },               -- Raw Spotted Yellowtail
  [8365] = { zones = { 400, 45, 36 } },               -- Raw Mithril Head Trout
  [7973] = { zones = { 440 } },                       -- Big-mouth Clam
  [13422] = { zones = { 440, 33 } },                  -- Stonescale Eel
  [13754] = { zones = { 440 } },                      -- Raw Glossy Mightfish
  [13755] = { zones = { 440 }, season = "winter" },   -- Raw Winter Squid
  [13756] = { zones = { 440 }, season = "summer" },   -- Raw Summer Bass (Wowhead guide)
  [13757] = { zones = { 357, 493, 28 } },             -- Lightning Eel
  [13758] = { zones = { 493, 357, 28 } },             -- Raw Redgill
  [13759] = { zones = { 493, 357, 28 } },             -- Raw Nightfin Snapper
  [13760] = { zones = { 357, 493, 28 } },             -- Raw Sunscale Salmon
  [13889] = { zones = false },                        -- Raw Whitescale Salmon
  [8959] = { zones = false },                         -- Raw Spinefin Halibut
  [13888] = { zones = false },                        -- Darkclaw Lobster
  [13893] = { zones = false },                        -- Large Raw Mightfish
}

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

local GREEN = { 0.2, 1, 0.2 }
local YELLOW = { 1, 0.82, 0 }
local RED = { 1, 0.33, 0.33 }
local PLAIN = { 0.9, 0.9, 0.9 }

ns.AddModule({
  key = "fishing",
  category = "professions",
  label = "Fishing",
  tip = "On a raw fish: the best zones to catch it, the school (pool) it comes from, and the "
    .. "fishing skill each zone needs. Green: you catch it there. Yellow: only with a lure. "
    .. "Red: not even with a lure.",
  options = {
    { key = "zones", label = "Best zones", default = true },
    { key = "colour", label = "Colour zones by your skill", default = true,
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
    if rank then
      tooltip:AddDoubleLine(head, "your skill " .. (rank + modifier), 1, 0.82, 0, 0.6, 0.6, 0.6)
    else
      tooltip:AddLine(head, 1, 0.82, 0)
    end

    if showZones then
      if not fish.zones then
        tooltip:AddLine("  No Forever catch data yet", 0.5, 0.5, 0.5)
      else
        local season = fish.season and (" (" .. fish.season .. ")") or ""
        for _, zid in ipairs(fish.zones) do
          local z = ZONES[zid]
          if z then
            local c = PLAIN
            if rank then
              local skill = rank + modifier
              if skill >= z[2] then c = GREEN
              elseif skill + BestLure(rank) >= z[2] then c = YELLOW
              else c = RED end
            end
            tooltip:AddDoubleLine("  " .. z[1] .. season, "skill " .. z[2], c[1], c[2], c[3], c[1], c[2], c[3])
          end
        end
      end
    end
    if showSchool then
      tooltip:AddLine("  Schools: " .. fish.school, 0.41, 0.8, 0.94)
    end
    return true
  end,
})
