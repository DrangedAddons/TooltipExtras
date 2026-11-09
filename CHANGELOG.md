# Changelog

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
