# TooltipExtras

A World of Warcraft addon for WoW Forever that adds profit lines to item tooltips, one profession at a time. Tick the professions you want on the settings page. Prices come from Auctionator, so you need it installed.

## Professions
- **Enchanting:** on a lesser essence (Magic, Astral, Mystic, Nether, Eternal, Planar, Cosmic, Celestial), **Combine to Greater** with the profit or loss from turning 3 into 1. On a greater, **Split to Lesser** with the profit or loss from turning 1 into 3.
  - **Disenchant value:** on green, blue and purple weapons and armour, what it can disenchant into: each material with its quantity range and price each, the chance of getting it, its expected value, and the expected total. Uses the original game's disenchant table, checked against Wowhead Forever. The expected value also fills Auctionator's own Disenchant line, under Vendor and Auction.
- **Mining:** on ore, **Smelt to Bar** with the profit or loss per bar from smelting instead of selling the ore. Covers Copper, Tin, Silver, Iron, Gold, Mithril, Truesilver, Dark Iron (8 ore), Thorium, Azerothium (2 ore + Coal) and Heavy Thorium. Extra reagents like Coal count at their auction price.
- **Blacksmithing:** on stone, **Make Grinding Stone** with the profit or loss per grinding stone from making it instead of selling the stone. Covers Rough, Coarse, Heavy, Solid and Dense.
- **Engineering:** on stone, **Make Blasting Powder** with the profit or loss per powder from making it instead of selling the stone. Covers Rough, Coarse, Heavy, Solid and Dense.
- **Tailoring:** on cloth, **Weave to Bolt** with the profit or loss per bolt from weaving instead of selling the cloth. Covers Linen, Wool, Silk, Mageweave and Runecloth.
- **Leatherworking:** on leather, **Upgrade to <next leather>** with the profit or loss per upgraded leather. Covers Ruined Leather Scraps to Light, then Light to Medium, Heavy, Thick and Rugged. On hides, **Cure Hide** with the profit or loss from curing, with the salt at its auction price (Light, Medium, Heavy, Thick and Rugged Hide).
- **Recipe reagents:** on a recipe linked in chat (every profession), the Reagents line becomes a priced list: each reagent's price, its cost for the recipe, and the total.
- **Fishing:** on a raw fish, the best zones to catch it with its catch % there and the skill each zone needs, the skill green if your skill catches it there, yellow if you need a lure, red if not even then. Fish that come from schools name the school.

Profit is green, loss is red. It takes off the 5% auction house cut by default (you can turn that off). When the other item's price (the greater, lesser, bar, bolt, upgraded leather, cured hide or salt) wasn't seen today, the line shows its age, e.g. "(3d old)".

## Events
- **Darkmoon Faire:** hover Yebb Neblegear, Kerri Hicks, Rinling or Chronos to see their ticket quests: what each costs to complete and how many tickets it gives, best value per ticket first, buying the items off the auction house. Below that, the best quest at each of the other three NPCs, marked when it's better value. Hand-ins you can craft are tagged and cost the materials when that's cheaper than buying them made. The cheapest is marked `<< best`. Open your profession window once so it knows your recipes.
  - Hovering Sayge lists which two answers give each of his +10% buffs.
  - At the ticket vendor (Gelvas Grimegate), items priced in tickets show how many tickets you have and the cheapest quests, from any of the four NPCs, to get the rest.

- **Green Hills of Stranglethorn:** hover Barnil Stonepot in Booty Bay to see what each chapter costs if you buy the pages you don't have off the auction house, and the total.

- **Cloth reputation:** hover a city's cloth quartermaster (or Belanaa Windveil for the High Order in Dalaran) to see how much Runecloth (and gold) it takes to reach each standing above yours with that faction, using the repeatable Additional Runecloth turn-in.

- **Mage scrolls:** untranslated Comprehension scrolls list what they can decipher into (random within the scroll's tier).

## Other
- **Chat links:** hover a link in chat (item, recipe, spell, quest, achievement, currency) to see its tooltip without clicking. Recipe reagent lists show on these hovers too. With Chattynator, its own hover tooltips are used and get the reagent lists.

- **Best way to sell:** of Auctionator's Vendor, Auction and Disenchant lines, the one worth the most turns green (after the 5% auction house cut, if that's on).

## Using it
`/tte` (or `/tooltipextras`), the addon list button or Options > AddOns > TooltipExtras opens the settings. Settings are account-wide.

Icon: inv_enchant_essenceeternallarge (Greater Eternal Essence), scaled up by `tools/make_icon.py`.
