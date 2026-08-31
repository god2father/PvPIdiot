# PvP Idiot

World of Warcraft PvP talent and gear recommendation addon.

> PvP 笨蛋 —— 笨蛋也会配装。

## v0.1 scope

- Retail WoW addon
- Solo Shuffle
- Arms Warrior mock dataset
- Build Top 3
- PvP talent recommendations
- Gear recommendations and current gear comparison
- Gems and enchants
- Secondary-stat distribution
- `/pvpi` and `/pvpidiot`
- Saved window position, size and selected tab
- zhCN / enUS addon UI text

The addon UI does not read the raw data table directly. All data access goes through `PvPIdiotDB`, so a future generated `PvPIdiotData.lua` can replace the mock source without rewriting the UI.

## Install

Copy the `PvPIdiot` folder to:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Restart or reload the game, enable **PvP Idiot**, then run:

```text
/pvpi
```

## Mock data

v0.1 ships with mock data for UI and architecture validation. It is explicitly marked **Mock Data** in the addon header and must not be interpreted as live PvP recommendations.

## Future data

Data will be generated using Blizzard Battle.net API outside the game and converted into a static Lua data file. The addon itself will not access the internet.

Not affiliated with or endorsed by Blizzard Entertainment.
