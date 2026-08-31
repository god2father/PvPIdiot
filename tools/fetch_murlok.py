#!/usr/bin/env python3
import argparse
import collections
import datetime as dt
import json
import os
import random
import time
import urllib.error
import urllib.request

SPECS = [
    ("death-knight", "blood", 250, "Death Knight", "Blood"),
    ("death-knight", "frost", 251, "Death Knight", "Frost"),
    ("death-knight", "unholy", 252, "Death Knight", "Unholy"),
    ("demon-hunter", "havoc", 577, "Demon Hunter", "Havoc"),
    ("demon-hunter", "vengeance", 581, "Demon Hunter", "Vengeance"),
    ("demon-hunter", "devourer", 1480, "Demon Hunter", "Devourer"),
    ("druid", "balance", 102, "Druid", "Balance"),
    ("druid", "feral", 103, "Druid", "Feral"),
    ("druid", "guardian", 104, "Druid", "Guardian"),
    ("druid", "restoration", 105, "Druid", "Restoration"),
    ("evoker", "devastation", 1467, "Evoker", "Devastation"),
    ("evoker", "preservation", 1468, "Evoker", "Preservation"),
    ("evoker", "augmentation", 1473, "Evoker", "Augmentation"),
    ("hunter", "beast-mastery", 253, "Hunter", "Beast Mastery"),
    ("hunter", "marksmanship", 254, "Hunter", "Marksmanship"),
    ("hunter", "survival", 255, "Hunter", "Survival"),
    ("mage", "arcane", 62, "Mage", "Arcane"),
    ("mage", "fire", 63, "Mage", "Fire"),
    ("mage", "frost", 64, "Mage", "Frost"),
    ("monk", "brewmaster", 268, "Monk", "Brewmaster"),
    ("monk", "windwalker", 269, "Monk", "Windwalker"),
    ("monk", "mistweaver", 270, "Monk", "Mistweaver"),
    ("paladin", "holy", 65, "Paladin", "Holy"),
    ("paladin", "protection", 66, "Paladin", "Protection"),
    ("paladin", "retribution", 70, "Paladin", "Retribution"),
    ("priest", "discipline", 256, "Priest", "Discipline"),
    ("priest", "holy", 257, "Priest", "Holy"),
    ("priest", "shadow", 258, "Priest", "Shadow"),
    ("rogue", "assassination", 259, "Rogue", "Assassination"),
    ("rogue", "outlaw", 260, "Rogue", "Outlaw"),
    ("rogue", "subtlety", 261, "Rogue", "Subtlety"),
    ("shaman", "elemental", 262, "Shaman", "Elemental"),
    ("shaman", "enhancement", 263, "Shaman", "Enhancement"),
    ("shaman", "restoration", 264, "Shaman", "Restoration"),
    ("warlock", "affliction", 265, "Warlock", "Affliction"),
    ("warlock", "demonology", 266, "Warlock", "Demonology"),
    ("warlock", "destruction", 267, "Warlock", "Destruction"),
    ("warrior", "arms", 71, "Warrior", "Arms"),
    ("warrior", "fury", 72, "Warrior", "Fury"),
    ("warrior", "protection", 73, "Warrior", "Protection"),
]

SLOT_MAP = {
    "head": "HEAD", "neck": "NECK", "shoulders": "SHOULDER",
    "back": "BACK", "chest": "CHEST", "wrist": "WRIST",
    "hands": "HANDS", "waist": "WAIST", "legs": "LEGS",
    "feet": "FEET", "ring-1": "FINGER", "ring-2": "FINGER",
    "trinket-1": "TRINKET", "trinket-2": "TRINKET",
    "main-hand": "MAIN_HAND", "off-hand": "OFF_HAND",
}
ALL_SLOTS = list(dict.fromkeys(SLOT_MAP.values()))


def pick(obj, *names, default=None):
    if not isinstance(obj, dict):
        return default
    for name in names:
        if name in obj:
            return obj[name]
    lowered = {str(k).lower(): v for k, v in obj.items()}
    for name in names:
        if name.lower() in lowered:
            return lowered[name.lower()]
    return default


def to_int(value, default=0):
    try:
        if value is None:
            return default
        return int(float(value))
    except (TypeError, ValueError):
        return default


def fetch_json(url, attempts=6):
    retry_codes = {401, 408, 425, 429, 500, 502, 503, 504}
    last_error = None
    for attempt in range(1, attempts + 1):
        req = urllib.request.Request(
            url,
            headers={
                "User-Agent": "Mozilla/5.0 PvPIdiot/0.1 (+https://github.com/god2father/PvPIdiot)",
                "Accept": "application/json,text/plain,*/*",
                "Referer": "https://murlok.io/",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                return None
            last_error = exc
            if exc.code not in retry_codes or attempt == attempts:
                raise
        except (urllib.error.URLError, TimeoutError) as exc:
            last_error = exc
            if attempt == attempts:
                raise
        delay = min(10.0, 1.2 * (2 ** (attempt - 1))) + random.uniform(0.2, 0.8)
        print(f"  retry {attempt}/{attempts} after {last_error}; sleeping {delay:.1f}s", flush=True)
        time.sleep(delay)
    raise last_error


def extract_id(entry):
    if isinstance(entry, (int, float, str)):
        return to_int(entry)
    if not isinstance(entry, dict):
        return 0
    return to_int(pick(entry, "PvPTalentID", "TalentID", "TraitNodeID", "SpellID", "ID", "Id", default=0))


def extract_pvp_talent_ids(char):
    value = pick(char, "PvPTalents", "PvpTalents", "PVPTalents", "PvpTalentIDs", default=[]) or []
    if not isinstance(value, list):
        value = [value]
    return {tid for tid in (extract_id(entry) for entry in value) if tid}


def extract_talent_ids(char, field):
    value = pick(char, field, default=[]) or []
    if isinstance(value, dict):
        for key in ("Talents", "Nodes", "Entries", "Items"):
            nested = pick(value, key, default=None)
            if nested is not None:
                value = nested
                break
        else:
            value = list(value.values())
    if not isinstance(value, list):
        value = [value]
    return {tid for tid in (extract_id(entry) for entry in value) if tid}


def empty_spec(class_slug, spec_slug, class_name, spec_name, reason="no-data"):
    return {
        "meta": {
            "sampleSize": 0,
            "maxRating": 0,
            "minRating": 0,
            "avgRating": 0,
            "classSlug": class_slug,
            "specSlug": spec_slug,
            "className": class_name,
            "specName": spec_name,
            "sourceUpdatedAt": "",
            "dataAvailable": False,
            "unavailableReason": reason,
        },
        "builds": [],
        "talents": {"class": [], "spec": [], "hero": []},
        "pvpTalents": [],
        "pvpTalentCombos": [],
        "gear": {slot: [] for slot in ALL_SLOTS},
        "gems": [],
        "enchants": {},
        "stats": {},
        "statsRaw": {},
        "statPriority": [],
    }


def aggregate_spec(payload, class_slug, spec_slug, spec_id, class_name, spec_name, debug=False):
    chars = pick(payload, "Characters", "characters", default=[]) or []
    updated_at = pick(payload, "UpdatedAt", "updatedAt", "updated_at", default=None)
    n = len(chars)
    if not n:
        return empty_spec(class_slug, spec_slug, class_name, spec_name), updated_at

    if debug:
        first = chars[0]
        print("Sample character keys:", sorted(first.keys()), flush=True)
        for key in ("PvPTalents", "ClassTalents", "SpecializationTalents", "HeroTalents"):
            value = pick(first, key, default=None)
            print(f"Sample {key}: type={type(value).__name__} value={repr(value)[:1200]}", flush=True)
        print("Sample stats:", {
            k: pick(first, k, default=None) for k in (
                "Haste", "HasteValue", "HasteBonus", "CritValue", "Mastery", "MasteryValue",
                "MasteryBonus", "Versatility", "VersatilityBonus", "RatingSoloShuffle"
            )
        }, flush=True)

    ratings = [
        to_int(pick(c, "RatingSoloShuffle", "ratingSoloShuffle", "RatingSolo", "Rating", default=0))
        for c in chars
    ]
    ratings = [r for r in ratings if r > 0]

    build_counts = collections.Counter()
    talent_counts = {
        "class": collections.Counter(),
        "spec": collections.Counter(),
        "hero": collections.Counter(),
    }
    gear_counts = collections.defaultdict(collections.Counter)
    gear_bonus = collections.defaultdict(dict)
    gem_players = collections.Counter()
    enchant_players = collections.defaultdict(collections.Counter)
    enchant_source = collections.defaultdict(dict)
    pvp_talent_players = collections.Counter()
    stat_totals = collections.Counter()

    for char in chars:
        code = pick(char, "TalentsCode", "talentsCode", "TalentCode", default="") or ""
        if code:
            build_counts[str(code)] += 1

        for tid in extract_talent_ids(char, "ClassTalents"):
            talent_counts["class"][tid] += 1
        for tid in extract_talent_ids(char, "SpecializationTalents"):
            talent_counts["spec"][tid] += 1
        for tid in extract_talent_ids(char, "HeroTalents"):
            talent_counts["hero"][tid] += 1
        for tid in extract_pvp_talent_ids(char):
            pvp_talent_players[tid] += 1

        for stat_key, api_names in {
            "haste": ("Haste", "HasteBonus", "haste"),
            "crit": ("Crit", "CritBonus", "crit"),
            "mastery": ("Mastery", "MasteryBonus", "mastery"),
            "versatility": ("Versatility", "VersatilityBonus", "versatility"),
        }.items():
            stat_totals[stat_key] += to_int(pick(char, *api_names, default=0))

        char_gems = set()
        char_enchants = collections.defaultdict(set)
        equipment = pick(char, "Equipment", "equipment", default={}) or {}
        items = pick(equipment, "Items", "items", default=[]) or []
        for item in items:
            raw_slot = str(pick(item, "Slot", "slot", default="") or "").lower()
            slot = SLOT_MAP.get(raw_slot)
            item_id = to_int(pick(item, "ItemID", "itemID", "itemId", default=0))
            if slot and item_id:
                gear_counts[slot][item_id] += 1
                gear_bonus[slot][item_id] = pick(item, "BonusList", "bonusList", "BonusIDs", default=[]) or []

            for gem in pick(item, "Gems", "gems", default=[]) or []:
                gem_id = to_int(pick(gem, "ItemID", "itemID", "ID", default=0) if isinstance(gem, dict) else gem)
                if gem_id:
                    char_gems.add(gem_id)

            for ench in pick(item, "Enchantments", "enchantments", default=[]) or []:
                if not isinstance(ench, dict) or not slot:
                    continue
                enchant_id = to_int(pick(ench, "ID", "Id", "EnchantID", default=0))
                source_item = to_int(pick(ench, "ItemID", "itemID", default=0))
                key = enchant_id or source_item
                if key:
                    char_enchants[slot].add(key)
                    enchant_source[slot][key] = {
                        "enchantID": enchant_id or key,
                        "sourceItemID": source_item,
                    }

        for gem_id in char_gems:
            gem_players[gem_id] += 1
        for slot, ids in char_enchants.items():
            for eid in ids:
                enchant_players[slot][eid] += 1

    def usage(count):
        return round(count / n, 4) if n else 0

    builds = [
        {"talentString": code, "count": count, "usage": usage(count)}
        for code, count in build_counts.most_common(3)
    ]

    talents = {}
    for group, counter in talent_counts.items():
        talents[group] = [
            {"id": talent_id, "count": count, "usage": usage(count)}
            for talent_id, count in counter.most_common()
        ]

    gear = {slot: [] for slot in ALL_SLOTS}
    for slot, counter in gear_counts.items():
        for item_id, count in counter.most_common(5):
            gear[slot].append({
                "itemID": item_id,
                "count": count,
                "usage": usage(count),
                "bonusList": gear_bonus[slot].get(item_id) or [],
            })

    gems = [
        {"itemID": item_id, "count": count, "usage": usage(count)}
        for item_id, count in gem_players.most_common(5)
    ]

    enchants = {}
    for slot, counter in enchant_players.items():
        rows = []
        for eid, count in counter.most_common(3):
            src = enchant_source[slot].get(eid, {})
            source_item = to_int(src.get("sourceItemID"))
            row = {
                "enchantID": to_int(src.get("enchantID"), eid),
                "count": count,
                "usage": usage(count),
            }
            if source_item:
                row["source"] = {"type": "item", "id": source_item}
            else:
                row["source"] = {"type": "enchant", "id": row["enchantID"]}
            rows.append(row)
        enchants[slot] = rows

    pvp_talents = [
        {"id": tid, "count": count, "usage": usage(count)}
        for tid, count in pvp_talent_players.most_common()
    ]

    avg_stats = {k: round(v / n, 2) if n else 0 for k, v in stat_totals.items()}
    stat_total = sum(max(0, value) for value in avg_stats.values())
    stats = {
        key: round(max(0, value) / stat_total, 4)
        for key, value in avg_stats.items()
    } if stat_total else {}
    stat_priority = sorted(avg_stats.keys(), key=lambda k: avg_stats[k], reverse=True)

    return {
        "meta": {
            "sampleSize": n,
            "maxRating": max(ratings) if ratings else 0,
            "minRating": min(ratings) if ratings else 0,
            "avgRating": round(sum(ratings) / len(ratings)) if ratings else 0,
            "classSlug": class_slug,
            "specSlug": spec_slug,
            "className": class_name,
            "specName": spec_name,
            "sourceUpdatedAt": updated_at or "",
            "dataAvailable": True,
        },
        "builds": builds,
        "talents": talents,
        "pvpTalents": pvp_talents,
        "pvpTalentCombos": [],
        "gear": gear,
        "gems": gems,
        "enchants": enchants,
        "stats": stats,
        "statsRaw": avg_stats,
        "statPriority": stat_priority,
    }, updated_at


def lua_string(value):
    return '"' + str(value).replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def lua_dump(value, indent=0):
    pad = "    " * indent
    child = "    " * (indent + 1)
    if value is None:
        return "nil"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, (int, float)):
        if isinstance(value, float) and value.is_integer():
            return str(int(value))
        return str(value)
    if isinstance(value, str):
        return lua_string(value)
    if isinstance(value, list):
        if not value:
            return "{}"
        return "{\n" + "\n".join(child + lua_dump(v, indent + 1) + "," for v in value) + "\n" + pad + "}"
    if isinstance(value, dict):
        if not value:
            return "{}"
        lines = []
        for key, val in value.items():
            if isinstance(key, int):
                k = f"[{key}]"
            elif isinstance(key, str) and key.replace("_", "a").isalnum() and not key[0].isdigit():
                k = key
            else:
                k = f"[{lua_string(key)}]"
            lines.append(child + k + " = " + lua_dump(val, indent + 1) + ",")
        return "{\n" + "\n".join(lines) + "\n" + pad + "}"
    raise TypeError(type(value))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", default="solo")
    parser.add_argument("--output", default="Data/MurlokData.lua")
    parser.add_argument("--allow-partial", action="store_true")
    parser.add_argument("--delay", type=float, default=0.8)
    args = parser.parse_args()

    specs_data = {}
    spec_index = {}
    failures = []
    timestamps = []

    for i, (class_slug, spec_slug, spec_id, class_name, spec_name) in enumerate(SPECS, 1):
        url = f"https://murlok.io/api/guides/{class_slug}/{spec_slug}/{args.mode}"
        print(f"[{i:02d}/{len(SPECS)}] {class_name} {spec_name}: {url}", flush=True)
        spec_index[spec_id] = {
            "classSlug": class_slug,
            "specSlug": spec_slug,
            "className": class_name,
            "specName": spec_name,
        }
        try:
            payload = fetch_json(url)
            if payload is None:
                data = empty_spec(class_slug, spec_slug, class_name, spec_name, reason="murlok-404")
                updated = None
                print("  -> no current Murlok Solo data (404); stored empty spec", flush=True)
            else:
                data, updated = aggregate_spec(
                    payload, class_slug, spec_slug, spec_id, class_name, spec_name,
                    debug=(class_slug == "warrior" and spec_slug == "arms"),
                )
            specs_data[spec_id] = data
            if updated:
                timestamps.append(str(updated))
            print(f"  -> {data['meta']['sampleSize']} characters, {len(data['builds'])} builds, {sum(len(v) for v in data['gear'].values())} gear rows", flush=True)
        except Exception as exc:
            failures.append((class_name, spec_name, str(exc)))
            if args.allow_partial:
                specs_data[spec_id] = empty_spec(class_slug, spec_slug, class_name, spec_name, reason=f"fetch-failed: {exc}")
                print(f"  !! FAILED after retries; stored empty spec: {exc}", flush=True)
            else:
                print(f"  !! FAILED: {exc}", flush=True)
        time.sleep(args.delay + random.uniform(0.0, 0.35))

    if failures and not args.allow_partial:
        print("\nFailures:")
        for c, s, e in failures:
            print(f"- {c} {s}: {e}")
        raise SystemExit(2)

    generated_at = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    root = {
        "version": 2,
        "isMock": False,
        "source": "murlok.io",
        "sourceMode": "solo",
        "sourceScope": "Top 50 across US/EU/KR/TW",
        "updatedAt": max(timestamps) if timestamps else generated_at,
        "generatedAt": generated_at,
        "specIndex": spec_index,
        "fetchFailures": [f"{c} {s}: {e}" for c, s, e in failures],
        "seasons": [{
            "id": 1,
            "name": "Midnight Season 2",
            "brackets": {
                "shuffle": {
                    "specs": specs_data,
                }
            },
        }],
    }

    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    header = (
        "-- Generated snapshot from Murlok.io JSON API.\n"
        "-- One-time validation data; not the long-term official PvPIdiot data source.\n"
        "-- Scope: Solo Shuffle, Top 50 per specialization, US/EU/KR/TW.\n"
        "-- Do not edit manually.\n"
    )
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(header)
        f.write("_G.PvPIdiotData = ")
        f.write(lua_dump(root))
        f.write("\n")

    print(f"\nWrote {args.output} with {len(specs_data)}/{len(SPECS)} spec entries")
    if failures:
        print(f"Snapshot contains {len(failures)} fetch-failure placeholders")


if __name__ == "__main__":
    main()
