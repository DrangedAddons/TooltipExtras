-- Neutral auction house prices (Booty Bay, Gadgetzan, Everlook) under Auctionator's Auction line.
-- AuctionatorSync 1.4.0+ keeps them apart from Auctionator's own list, in
-- AuctionatorSyncDB.neutral[realm].items[dbKey] = { p = price, t = seen (server time), a = listed },
-- keyed by Auctionator's database keys and realm. Opt in: off until ticked.
--
-- Auctionator adds its Auction line from Auctionator.Tooltip.AddAuctionTip, called by
-- ShowTipWithPricingDBKey (bag, chat, merchant, multi-item tooltips). The outer call is wrapped to
-- remember the item's keys and count, the inner one to add our line right after Auction's.
local ADDON, ns = ...

local MIN_SYNC = { 1, 4, 3 }

local MODULE = {
  key = "neutralah",
  category = "other",
  label = "Neutral auction prices",
  default = false,
  tip = "Under Auctionator's Auction line: the price at the neutral auction houses (Booty Bay, "
    .. "Gadgetzan, Everlook), from AuctionatorSync's neutral price list. "
    .. "Requires AuctionatorSync v1.4.3 or later.",
  options = { { key = "show", label = "Neutral AH line (requires AuctionatorSync v1.4.3 or later)",
    tip = "Requires AuctionatorSync v1.4.3 or later. Unknown means nobody synced has seen it "
      .. "on a neutral auction house yet.", default = true } },
}
ns.AddModule(MODULE)

local function Enabled()
  local db = ns.ModuleDB(MODULE)
  return db.enabled and db.show ~= false
end

-- AuctionatorSync loaded and at least MIN_SYNC
local syncOK
local function SyncOK()
  if syncOK == nil then
    local get = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local loaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
    local v = loaded and loaded("AuctionatorSync") and get and get("AuctionatorSync", "Version")
    syncOK = false
    if type(v) == "string" then
      local parts = { v:match("^(%d+)%.(%d+)%.?(%d*)") }
      for i = 1, 3 do
        local a, b = tonumber(parts[i]) or 0, MIN_SYNC[i]
        if a ~= b then syncOK = a > b break end
        if i == 3 then syncOK = true end
      end
    end
  end
  return syncOK
end

local function Realm()
  local s = Auctionator and Auctionator.State
  if s and s.CurrentRealm then return s.CurrentRealm end
  local v = Auctionator and Auctionator.Variables
  if v and v.GetConnectedRealmRoot then return v.GetConnectedRealmRoot() end
end

-- price and seen time of the first of dbKeys on the neutral list, like Auctionator's GetFirstPrice
local function NeutralPrice(dbKeys)
  local db = AuctionatorSyncDB
  local realm = Realm()
  local list = type(db) == "table" and type(db.neutral) == "table" and realm and db.neutral[realm]
  local items = type(list) == "table" and list.items
  if type(items) ~= "table" then return nil end
  for _, key in ipairs(dbKeys) do
    local it = items[tostring(key)]
    if type(it) == "table" and (tonumber(it.p) or 0) > 0 then return it.p, tonumber(it.t) end
  end
end

local function AgeText(seen)
  if not seen then return "" end
  local now = GetServerTime and GetServerTime() or time()
  local days = math.floor((now - seen) / 86400)
  if days >= 1 then return string.format(" |cff808080(%dd old)|r", days) end
  return ""
end

local current -- { keys, count } while ShowTipWithPricingDBKey runs

local function AddNeutral(tooltipFrame, countString, cannotAuction)
  -- the same skip as Auctionator's: it hides Auction when cannotAuction is anything but false/nil
  if not current or cannotAuction or not Enabled() or not SyncOK() then return end
  if not Auctionator.Config.Get(Auctionator.Config.Options.AUCTION_TOOLTIPS) then return end
  local price, seen = NeutralPrice(current.keys)
  countString = countString or ""
  local money
  if price then
    -- Auctionator shows a stack price exactly when it adds a count to the label
    if countString ~= "" and current.count then price = price * current.count end
    money = Auctionator.Utilities.CreatePaddedMoneyString(price)
  else
    money = (AUCTIONATOR_L_UNKNOWN or UNKNOWN or "Unknown") .. "  "
  end
  tooltipFrame:AddDoubleLine("Neutral AH" .. countString .. AgeText(seen), WHITE_FONT_COLOR:WrapTextInColorCode(money))
end

local function Wrap()
  local T = Auctionator and Auctionator.Tooltip
  if not (T and T.ShowTipWithPricingDBKey and T.AddAuctionTip) then return end
  local show, auction = T.ShowTipWithPricingDBKey, T.AddAuctionTip
  T.ShowTipWithPricingDBKey = function(tooltipFrame, dbKeys, itemLink, itemCount, ...)
    local outer = current
    current = { keys = type(dbKeys) == "table" and dbKeys or {}, count = itemCount }
    local ok, err = pcall(show, tooltipFrame, dbKeys, itemLink, itemCount, ...)
    current = outer
    if not ok then error(err, 0) end
  end
  T.AddAuctionTip = function(tooltipFrame, auctionPrice, countString, cannotAuction, ...)
    auction(tooltipFrame, auctionPrice, countString, cannotAuction, ...)
    pcall(AddNeutral, tooltipFrame, countString, cannotAuction)
  end
end

local login = CreateFrame("Frame")
login:RegisterEvent("PLAYER_LOGIN")
login:SetScript("OnEvent", Wrap)
