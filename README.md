# PvP Idiot

World of Warcraft PvP talent and gear recommendation addon.

> PvP 笨蛋 —— 笨蛋也会配装。

## v0.1 scope

- Retail WoW addon
- Solo Shuffle
- Arms Warrior mock dataset
- Build Top 3
- PvP talent recommendations
- PvP-only gear recommendations and current gear comparison
- Gems and enchants
- Secondary-stat distribution
- `/pvpi` and `/pvpidiot`
- Saved window position, size and selected tab
- zhCN / enUS addon UI text

The addon UI does not read the raw data table directly. All data access goes through `PvPIdiotDB`, so a future generated `PvPIdiotData.lua` can replace the mock source without rewriting the UI.

## Install

Copy the `PvPIdiot/PvPIdiot` folder to:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

The final layout must be:

```text
World of Warcraft/_retail_/Interface/AddOns/PvPIdiot/PvPIdiot.toc
```

Do not copy the GitHub download folder (for example `PvPIdiot-main`) directly
into `AddOns`; WoW identifies an addon from the `.toc` file whose name matches
its containing folder.

Restart or reload the game, enable **PvP Idiot**, then run:

```text
/pvpi
```

## Mock data

v0.1 ships with mock data for UI and architecture validation. It is explicitly marked **Mock Data** in the addon header and must not be interpreted as live PvP recommendations.

## Future data

Data is generated outside the game and converted into static Lua files. The addon itself will not access the internet. Gear recommendations use a conservative public-client-data allow-list: only items explicitly identified as PvP equipment are shown; uncertain items are omitted rather than treated as PvP gear.

Not affiliated with or endorsed by Blizzard Entertainment.
