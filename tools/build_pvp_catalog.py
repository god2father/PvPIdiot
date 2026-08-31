#!/usr/bin/env python3
"""Build a conservative PvP gear allow-list from public WoW client data."""

import argparse
import csv
import datetime as dt
import html
import io
import json
import re
import urllib.request


WAGO_DB2_URL = "https://wago.tools/db2"
WAGO_CSV_URL = "https://wago.tools/db2/ItemSparse/csv?build={build}&locale=enUS"

# Only vendor gear families whose names explicitly identify them as PvP gear.
# Keep this list deliberately narrow: an unlisted item is safer than a PvE false
# positive in a PvP-only recommendation.
PVP_NAME_TOKENS = ("Gladiator", "Aspirant", "Combatant", "Competitor")
CURRENT_EXPANSION_ID = 11  # Midnight


def fetch_text(url):
    request = urllib.request.Request(
        url,
        headers={"User-Agent": "PvPIdiot/0.1 (+https://github.com/god2father/PvPIdiot)"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read().decode("utf-8")


def fetch_current_build():
    page = html.unescape(html.unescape(fetch_text(WAGO_DB2_URL)))
    match = re.search(r'"currentVersion":"([^"]+)"', page)
    if not match:
        raise RuntimeError("Could not determine the current WoW client build from Wago DB2.")
    return match.group(1)


def matches_pvp_name(name):
    return any(re.search(r"\b" + re.escape(token) + r"\b", name, re.IGNORECASE) for token in PVP_NAME_TOKENS)


def write_json(path, build, expansion_id, item_ids):
    payload = {
        "schemaVersion": 1,
        "source": "wago.tools DB2 ItemSparse",
        "build": build,
        "expansionID": expansion_id,
        "generatedAt": dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "nameTokens": list(PVP_NAME_TOKENS),
        "itemIDs": item_ids,
    }
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")


def write_lua(path, build, expansion_id, item_ids):
    generated_at = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    with open(path, "w", encoding="utf-8") as handle:
        handle.write("-- Generated from Wago DB2 ItemSparse. Do not edit manually.\n")
        handle.write(f"-- Client build: {build}; expansion: {expansion_id}; generated: {generated_at}.\n")
        handle.write("PvPIdiot.PvPItemCatalog = {\n")
        for item_id in item_ids:
            handle.write(f"    [{item_id}] = true,\n")
        handle.write("}\n")


def main():
    parser = argparse.ArgumentParser(description="Build the strict PvP gear allow-list.")
    parser.add_argument("--build", default="", help="WoW client build; defaults to Wago's current build.")
    parser.add_argument("--expansion-id", type=int, default=CURRENT_EXPANSION_ID)
    parser.add_argument("--output-json", default="tools/pvp_item_catalog.json")
    parser.add_argument("--output-lua", default="PvPIdiot/Data/PvPItemCatalog.lua")
    args = parser.parse_args()

    build = args.build or fetch_current_build()
    rows = csv.DictReader(io.StringIO(fetch_text(WAGO_CSV_URL.format(build=build))))
    item_ids = sorted(
        int(row["ID"])
        for row in rows
        if row.get("ID", "").isdigit()
        and int(row.get("ExpansionID", -1)) == args.expansion_id
        and matches_pvp_name(row.get("Display_lang", ""))
    )
    if not item_ids:
        raise RuntimeError("PvP catalog is empty; refusing to generate a non-strict snapshot.")

    write_json(args.output_json, build, args.expansion_id, item_ids)
    write_lua(args.output_lua, build, args.expansion_id, item_ids)
    print(f"Wrote {len(item_ids)} confirmed PvP item IDs for expansion {args.expansion_id}, client build {build}.")


if __name__ == "__main__":
    main()
