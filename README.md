# TooltipExtras

A World of Warcraft addon for WoW Forever that adds profit lines to item tooltips, one profession at a time. Tick the professions you want on the settings page. Prices come from Auctionator, so you need it installed.

## Professions
- **Enchanting:** on a lesser essence (Magic, Astral, Mystic, Nether, Eternal, Planar, Cosmic, Celestial), **Combine to Greater** with the profit or loss from turning 3 into 1. On a greater, **Split to Lesser** with the profit or loss from turning 1 into 3.
- **Mining:** on ore, **Smelt to Bar** with the profit or loss per bar from smelting instead of selling the ore. Covers Copper, Tin, Silver, Iron, Gold, Mithril, Truesilver, Dark Iron (8 ore), Thorium, Azerothium (2 ore + Coal) and Heavy Thorium. Extra reagents like Coal count at their auction price.
- **Tailoring:** on cloth, **Weave to Bolt** with the profit or loss per bolt from weaving instead of selling the cloth. Covers Linen, Wool, Silk, Mageweave and Runecloth.
- **Leatherworking:** on leather, **Upgrade to <next leather>** with the profit or loss per upgraded leather. Covers Ruined Leather Scraps to Light, then Light to Medium, Heavy, Thick and Rugged.

Profit is green, loss is red. It takes off the 5% auction house cut by default (you can turn that off). When the other item's price (the greater, lesser, bar, bolt or upgraded leather) wasn't seen today, the line shows its age, e.g. "(3d old)".

## Using it
`/tte` (or `/tooltipextras`), the addon list button or Options > AddOns > TooltipExtras opens the settings. Settings are account-wide.

Icon: inv_enchant_essenceeternallarge (Greater Eternal Essence), scaled up by `tools/make_icon.py`.
