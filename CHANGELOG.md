# Changelog

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
