# Changelog

## 0.22.0
- **Bag item totals** (new, under Other, starts ticked): Alt+click items in your bags to mark them (a gold shade and a tick). A window adds up the marked items: all vendored, all auctioned, all disenchanted, and each sold its best way, with how many go each way. Auction and disenchant count the 5% auction house cut when that setting is on. Alt+click a marked item to unmark it; **Clear** or closing the window unmarks everything. Marks follow the items when EllesmereUI Bags redraws, and drop off items that are sold, moved or used.
- Works in EllesmereUI Bags, and in other bag addons once you've hovered the item. Not while the auction house is open, where Auctionator uses Alt+click.
- Adds the DrangedAddons window kit (Theme.lua, Widgets.lua, Window.lua) for the totals window.
- New files: restart the game client once (a /reload won't load them).

## 0.21.1
- No change in game. The disenchant table can now be checked against fresh Wowhead Forever counts and updated with `tools/disenchant` (see its README). The first check, 2026-11-14, found no rows that needed changing.

## 0.21.0
- Auctionator's **Disenchant** line, under Vendor and Auction, now shows the expected disenchant value on Forever gear. Auctionator only knows Warlords of Draenor and later gear, so TooltipExtras fills it in when Auctionator has none. Auctionator's files aren't touched. It follows the Enchanting **Disenchant value** tick box and needs Auctionator's "Show estimated disenchant item value" setting on.
- **Best way to sell** (new, under Other, starts ticked): of Auctionator's Vendor, Auction and Disenchant lines, the one worth the most turns green. Auction and disenchant count the 5% auction house cut when that setting is on, since vendoring has none.

## 0.20.0
- **Enchanting: Disenchant value** (new, starts ticked). On green, blue and purple weapons and armour: each material it can disenchant into with its quantity range and price each, the chance of getting it, its expected value (chance x average quantity x price), and the expected total. Auctionator's own disenchant line only covers Warlords of Draenor and later gear, so it shows nothing on Forever.
- The disenchant table is the original game's, checked against Wowhead Forever's disenchant counts for every material; they match. Forever has no Burning Crusade materials, so blues above level 65 give Large Brilliant Shards and purples above 60 give 1-2 Nexus Crystals.
- Essences count at the better of their own price and their combine/split value (3 lesser = 1 greater).
- New file: restart the game client once (a /reload won't load it).

## 0.19.1
- Chat links: with Chattynator loaded, TooltipExtras leaves hover tooltips to Chattynator instead of showing a second one. Recipe reagent lists still show on Chattynator's hovers.

## 0.19.0
- **Chat links** (new, under Other): hover an item, recipe, spell, quest, achievement or currency link in chat to see its tooltip without clicking. Starts ticked. Recipe reagent lists show on these hovers too; bag and profession-window hovers still keep the game's Reagents line.
- New file: restart the game client once (a /reload won't load it).

## 0.18.8
- Settings: the category notes wrap inside their column, so the Professions note no longer runs into Events. The Professions note is shorter too.
- Settings: **Recipe reagents** sits under its own **All professions** sub-heading below the professions, since it works on every profession's recipes rather than being one.

## 0.18.7
- Recipe reagents: a second thin gold line sits just below the Total row, so it's boxed in above and below.

## 0.18.6
- Recipe reagents: a thin gold line sits just above the Total row, so the total stands apart from the reagents without adding space.

## 0.18.5
- Recipe reagents: the "each" column is gone. Each reagent shows its single price in grey after the name, e.g. `8 x Soul Dust (4s 47c)`, and the cost column stays. A blank line separates the reagent list from the effect text.

## 0.18.4
- Recipe reagents: fixed the priced list not replacing the Reagents line. Forever splits that line with a `|n` line break, which was read as part of the first reagent's name.

## 0.18.3
- `/tte debug` turns on chat output for tracking down problems: what the recipe reagent hook sees on a linked recipe, and why it does or doesn't draw. If the reagent list hits an error, it's now printed once instead of failing silently.

## 0.18.2
- Recipe reagents: fixed the priced list never showing. The tooltip line hook was registered for every type instead of the plain line type the Reagents line uses, and the "Reagents:" match is more forgiving.

## 0.18.1
- Recipe reagents: only on recipes linked in chat. Hovered recipes and the profession window keep the game's own Reagents line.

## 0.18.0
- **Recipe reagents:** the priced reagent list now works for every profession, not just Enchanting: Alchemy, Blacksmithing, Cooking, Enchanting, Engineering, First Aid, Leatherworking, Mining and Tailoring (522 reagents from CraftRoute's Forever data). It has its own row under Professions, **Recipe reagents**, and starts ticked. The tick box under Enchanting from 0.17.0 is gone.

## 0.17.0
- **Enchanting:** enchant links and enchanting recipes (chat links, the profession window) swap the game's "Reagents:" line for a priced list. Each reagent gets a row with its count, the price each and the cost for the recipe, then the **Total**. Prices are the cheaper of the AH and the vendor price Auctionator has seen. The coins sit in aligned columns. Reagents you don't have enough of are red, as before. If a reagent has no price, its row says so and the total says "prices missing". It's a new tick box under Enchanting and starts ticked.

## 0.16.2
- Fishing: the catch % and the skill level each sit in their own column and line up down the tooltip. The header row labels them **catch** and **skill**. "your skill" is gone, and the zone rows show just the number.

## 0.16.1
- Fishing: added **Whimsyfin**, Forever's new fish (3% of catches in Redridge Mountains, from the School of Whimsyfin).

## 0.16.0
- Fishing: each zone now shows the fish's **catch %**, its share of everything caught in that zone (from Wowhead Forever's zone fishing tables), e.g. Raw Sagefish: Hillsbrad Foothills 34%, Loch Modan 20%, Stonetalon Mountains 14%. Up to 3 zones, best first. Zones under a quarter of the best one's share, or with under 200 recorded catches, are left out.
- Fishing: added Darkshore Grouper (29% in Darkshore) and the new Forever zones Riverglades and Zephras Isle (their skill shows as "?" until known).
- Fishing: Whitescale Salmon, Darkclaw Lobster, Large Raw Mightfish and Summer Bass have no Forever catches yet, so they use classic's rates and say "(classic data)". Spinefin Halibut is gone from the list (it's a mob drop, not a catch).

## 0.15.1
- Fishing: zone names stay white. Only the skill level is coloured green, yellow or red.

## 0.15.0
- **Fishing:** raw fish list the best zones to catch them, best first, with the fishing skill each zone needs so fish don't get away. Each zone is coloured by your fishing skill (pole and gear included): green if you catch it there now, yellow if you need a lure (the biggest one your skill can use), red if even a lure won't do it. Sagefish, Greater Sagefish, Oily Blackmouth, Firefin Snapper and Deviate Fish also name their school. Winter Squid and Summer Bass say which season. Zones come from Wowhead Forever's catch data. Whitescale Salmon, Spinefin Halibut, Darkclaw Lobster and Large Raw Mightfish have no Forever data yet and say so. Under Professions, with tick boxes for zones, colours and schools. All start ticked.

## 0.14.1
- Mage scrolls: lists checked against the method.gg guide. Dropped Imbue Spellbreak from the Comprehension 175 list (not in the game data). Tidied the Cryoblast, Confuse Beast and Rebuke Elemental lines. The heading now reads "Can decipher into:".

## 0.14.0
- **Mage scrolls:** untranslated Comprehension scrolls ("Scroll: TOPAZ YORAK" and the rest) list the scrolls they can turn into when deciphered, with a short effect for each. The result is random from the scroll's tier (Comprehension 1, 15, 50 or 175), read from its "Requires Comprehension" line. Under a new **Classes** heading in settings, starts ticked. Pools come from a Forever beta guide, so a few may be out of date.

## 0.13.0
- Settings: each profession and event has a **+** that opens its parts, each with its own tick box. The module's own box still turns all of it on or off, and open rows are remembered.
  - Darkmoon Faire: turn-in NPCs' quests, best deal at the other NPCs, ticket vendor, Sayge's fortunes.
  - Leatherworking: leather upgrades, curing hides.
  - Blacksmithing, Engineering, Enchanting, Mining, Tailoring, Green Hills and Cloth quartermasters have one part each for now.

## 0.12.3
- Settings page: modules are grouped under headings. **Professions** (Blacksmithing, Enchanting, Engineering, Leatherworking, Mining, Tailoring) on the left; **Events** (Darkmoon Faire), **Quests** (Green Hills of Stranglethorn) and **Reputation** (Cloth quartermasters, renamed from Cloth reputation) on the right. Your tick choices are kept.

## 0.12.2
- Cloth reputation: added **Belanaa Windveil**, the High Order cloth quartermaster in Dalaran. Same turn-in as the cities: Additional Runecloth, 20 Runecloth for 50 rep.

## 0.12.1
- Cloth reputation: shorter tooltip. The header is just "<Faction> reputation", and the "Additional Runecloth: 20 for 50 rep" note is gone.

## 0.12.0
- **Cloth reputation:** hovering a city's cloth quartermaster shows how much Runecloth you need to reach each standing above yours (Friendly, Honored, Revered, Exalted) with their faction, the number of turn-ins, and what the Runecloth costs on the AH. Covers Stormwind, Ironforge, Gnomeregan Exiles, Darnassus, Orgrimmar, Darkspear Trolls, Thunder Bluff and Undercity. Uses Forever's Additional Runecloth (20 Runecloth for 50 rep, +10% for Humans). The one-time donations aren't counted. It has its own tick box and starts ticked.

## 0.11.2
- Conversion lines name their profession in front, e.g. `Blacksmithing: Make Grinding Stone` and `Engineering: Make Blasting Powder`. Mining, Tailoring, Leatherworking and Enchanting essences get the same tag.

## 0.11.1
- Stone's grinding stone and blasting powder lines sit together, with no blank line between them.

## 0.11.0
- **Blacksmithing:** stone now also shows **Make Grinding Stone** with the profit or loss per grinding stone, against selling the stone. Rough and Coarse take 2 stone, Heavy 3, Solid and Dense 4. With Engineering ticked too, you can compare it with the blasting powder line. It has its own tick box and starts ticked.

## 0.10.0
- **Engineering:** stone now shows **Make Blasting Powder** with the profit or loss per powder, against selling the stone. Covers Rough, Coarse and Heavy (1 stone each), and Solid and Dense (2 stone each). Only on the stone, since powder can't be turned back. It has its own tick box and starts ticked.

## 0.9.0
- **Green Hills of Stranglethorn:** hovering Barnil Stonepot in Booty Bay shows what each chapter costs if you buy its pages off the AH, and the total. Pages you already carry (bags or bank) aren't counted. Chapters you've turned in or hold show as done, and the whole thing says done once the final quest is complete. Pages with no auction price are named. It has its own tick box and starts ticked.

## 0.8.1
- Sayge's tooltip is shorter: one line per buff, like `+10% Damage    pick 1 - 1` (first menu answer, then second).

## 0.8.0
- Darkmoon Faire: hovering **Sayge** lists each fortune buff (+10% Damage, Strength, Agility, Stamina, Intellect, Spirit, Armor, Magic Resistance) with the two answers to pick, numbered by their place in his menus.

## 0.7.2
- Ticket vendor: fixed the ticket section never showing. Forever's ticket is the Darkmoon Prize Ticket, a different item from classic's Darkmoon Faire Prize Ticket. Tickets are now recognised by name, and your count uses the real item.

## 0.7.1
- Ticket vendor: the ticket section now shows with any merchant window, including replacements of the default one. It finds the hovered item in the vendor's list instead of relying on the default window's buttons.

## 0.7.0
- Darkmoon Faire ticket vendor (Gelvas Grimegate): hovering an item priced in tickets shows its ticket price, how many tickets you have (bags and bank), and the cheapest quests to make up the difference, with each quest's cost and a total. The quests can come from any of the four turn-in NPCs and can be a mix, whichever adds up to the tickets you need for the least gold. Crafting is used where you know the recipe and it's cheaper, the same as on the NPCs.

## 0.6.0
- Darkmoon Faire: a **per ticket** column next to **cost**, with its own aligned coin columns. Both blocks share them, so they line up top to bottom. The order is still best value per ticket first.

## 0.5.5
- Darkmoon Faire: costs only show the coins they need. Copper-only costs show just copper, silver costs show silver and copper, and the leading coin isn't zero-padded. The coins still sit in their columns.

## 0.5.4
- Darkmoon Faire: the cost column now lines up exactly. Gold, silver and copper each sit in a fixed-width slot with the coin icons at fixed spots, so the icons form straight columns in both blocks. (0.5.3's padded text still drifted, because digits aren't all the same width.)

## 0.5.3
- Darkmoon Faire: the cost column lines up. Silver and copper always show two digits (`05`), and when any row in a block costs gold, every row in it shows gold too (`0`).

## 0.5.2
- Darkmoon Faire: each quest now shows what it costs to complete next to the tickets it gives, in place of the cost per ticket. The order is still best value per ticket first. The other NPCs' lines say `<< better value` (was `<< cheaper`), since a better deal can still cost more in total.

## 0.5.1
- Darkmoon Faire: under an NPC's own hand-ins, **Best at the other NPCs** lists the best hand-in at each of the other three, cheapest first. It's green and marked `<< cheaper` when it beats this NPC's best, so you can see where to go.

## 0.5.0
- **Darkmoon Faire:** hover a ticket turn-in NPC to see their hand-ins ranked by cost per ticket, buying the items off the AH. The cheapest is green and marked `<< best`. Items with no auction price go to the bottom.
  - Yebb Neblegear: beast parts (Small Furry Paws up to Evil Bat Eyes and Glowing Scorpid Blood).
  - Kerri Hicks: Blacksmithing (Coarse Weightstones up to Dense Grinding Stones).
  - Rinling: Engineering (Copper Modulators up to Thorium Widgets).
  - Chronos: Leatherworking (Embossed Leather Boots up to Rugged Armor Kits).
- Hand-ins this character can craft are tagged `[craft]` and cost the materials instead, bought at the cheaper of AH and vendor price (vendor prices come from Auctionator's merchant scans). If the item made is cheaper on the AH than its materials, the row says `[craftable, buying is cheaper]` and uses the AH price. Known recipes are saved per character when you open the profession window, so open it once after updating.
- The settings list is now **Professions and events**, with a Darkmoon Faire tick box (starts ticked).

## 0.4.1
- **Leatherworking:** hides now show **Cure Hide** with the profit or loss from curing instead of selling the hide. The salt counts at its auction price. Covers Light and Medium Hide (Salt), Heavy Hide (3 Salt), Thick Hide (Deeprock Salt) and Rugged Hide (Refined Deeprock Salt, makes 2 Cured Rugged Hides, so the profit is per craft).

## 0.4.0
- **Leatherworking:** leather now shows **Upgrade to <next leather>** with the profit or loss per upgraded leather, against selling what you have. Covers Ruined Leather Scraps to Light (3 per), Light to Medium (4), Medium to Heavy (5), Heavy to Thick (6) and Thick to Rugged (6). Rugged Leather gets no line. It has its own tick box under Professions and starts ticked.

## 0.3.1
- Mining and Tailoring lines now show only on ore and cloth. Bars and bolts can't be turned back, so they no longer get a line.

## 0.3.0
- **Tailoring:** cloth and bolts now show **Weave to Bolt** (on the cloth) or **Weave from Cloth** (on the bolt), with the profit or loss per bolt from weaving instead of selling the cloth. Covers Linen (2 per bolt), Wool (3), Silk (4), Mageweave (5) and Runecloth (5). It has its own tick box under Professions and starts ticked.

## 0.2.0
- **Mining:** ores and bars now show **Smelt to Bar** (on the ore) or **Smelt from Ore** (on the bar), with the profit or loss per bar from smelting instead of selling the ore. Covers Copper, Tin, Silver, Iron, Gold, Mithril, Truesilver, Dark Iron (8 ore per bar), Thorium, Azerothium (2 ore + Coal per bar) and Heavy Thorium. Coal counts at its auction price.
- The settings page now has a **Professions** list. Tick the ones you want tooltip lines for (Enchanting, Mining). Both start ticked.
- The 5% auction house cut box moved to the top of the page and applies to every profession. Your old setting carries over.

## 0.1.2
- Essence swap is down to one line. A lesser essence shows **Combine to Greater** and a greater shows **Split to Lesser**, each with the profit or loss (green or red). No more price rows, verdict line or flip line.
- The profit takes off the 5% AH cut when that option is on. If the other essence's price is out of date, the line says how old it is.

## 0.1.1
- Essence swap now says clearly what to do. Whichever of **3 lessers** or **1 greater** sells for more is green and tagged `<< better`. The other is greyed out.
- New verdict line: "Combine 3 into 1, sell the greater" or "Split 1 into 3, sell the lessers", with how much that gains on essences you already own (after the AH cut, if that option is on).
- The old profit line was an AH flip (buy one side, convert, sell the other). It read as a loss even when converting your own essences paid off. It's now labelled "Flip: ..." and only shows when the flip itself makes money.
- Trimmed to two price rows, 3 x lesser and the greater. Auctionator already shows single-item prices.

## 0.1.0
- First version. **Essence swap prices** on lesser and greater enchanting essences: the price of one lesser, three lessers and one greater (from Auctionator), and the profit or loss from combining 3 into 1 or splitting 1 into 3, after the 5% auction house cut (can be turned off). Old prices show their age.
- Settings in Options > AddOns > TooltipExtras, or `/tte`.
