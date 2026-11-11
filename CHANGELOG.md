# Changelog

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
