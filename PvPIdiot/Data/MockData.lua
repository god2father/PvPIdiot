local ADDON_NAME, PvPIdiot = ...

-- Mock values intentionally mirror the future generated data shape.
-- Item/talent IDs are placeholders for UI development and are not live recommendations.
PvPIdiot.MockData = {
    version = 1,
    isMock = true,
    updatedAt = "2026-08-31T08:00:00Z",
    seasons = {
        {
            id = 1,
            name = "Current Season",
            brackets = {
                shuffle = {
                    specs = {
                        [71] = {
                            meta = {
                                sampleSize = 50,
                                maxRating = 2987,
                                minRating = 2314,
                                avgRating = 2578,
                            },
                            builds = {
                                { talentString = "MOCK-ARMS-BUILD-A", count = 21, usage = 0.42, heroTalentID = 60 },
                                { talentString = "MOCK-ARMS-BUILD-B", count = 14, usage = 0.28, heroTalentID = 60 },
                                { talentString = "MOCK-ARMS-BUILD-C", count = 8, usage = 0.16, heroTalentID = 60 },
                            },
                            talents = {
                                class = {
                                    { id = 123001, count = 49, usage = 0.98 },
                                    { id = 123002, count = 46, usage = 0.92 },
                                    { id = 123003, count = 41, usage = 0.82 },
                                },
                                spec = {
                                    { id = 124001, count = 48, usage = 0.96 },
                                    { id = 124002, count = 44, usage = 0.88 },
                                    { id = 124003, count = 38, usage = 0.76 },
                                },
                                hero = {
                                    { id = 125001, count = 35, usage = 0.70 },
                                    { id = 125002, count = 31, usage = 0.62 },
                                },
                            },
                            pvpTalents = {
                                { id = 3533, count = 49, usage = 0.98 },
                                { id = 5374, count = 44, usage = 0.88 },
                                { id = 28, count = 37, usage = 0.74 },
                                { id = 34, count = 26, usage = 0.52 },
                                { id = 41, count = 19, usage = 0.38 },
                            },
                            pvpTalentCombos = {},
                            gear = {
                                HEAD = {
                                    { itemID = 237617, count = 36, usage = 0.72, bonusList = {} },
                                    { itemID = 237618, count = 9, usage = 0.18, bonusList = {} },
                                    { itemID = 237619, count = 5, usage = 0.10, bonusList = {} },
                                },
                                NECK = {
                                    { itemID = 237620, count = 31, usage = 0.62, bonusList = {} },
                                    { itemID = 237621, count = 12, usage = 0.24, bonusList = {} },
                                    { itemID = 237622, count = 7, usage = 0.14, bonusList = {} },
                                },
                                SHOULDER = {
                                    { itemID = 237623, count = 34, usage = 0.68, bonusList = {} },
                                    { itemID = 237624, count = 11, usage = 0.22, bonusList = {} },
                                    { itemID = 237625, count = 5, usage = 0.10, bonusList = {} },
                                },
                                CHEST = {
                                    { itemID = 237626, count = 37, usage = 0.74, bonusList = {} },
                                    { itemID = 237627, count = 8, usage = 0.16, bonusList = {} },
                                    { itemID = 237628, count = 5, usage = 0.10, bonusList = {} },
                                },
                                WRIST = {
                                    { itemID = 237629, count = 30, usage = 0.60, bonusList = {} },
                                    { itemID = 237630, count = 13, usage = 0.26, bonusList = {} },
                                    { itemID = 237631, count = 7, usage = 0.14, bonusList = {} },
                                },
                                HANDS = {
                                    { itemID = 237632, count = 33, usage = 0.66, bonusList = {} },
                                    { itemID = 237633, count = 10, usage = 0.20, bonusList = {} },
                                    { itemID = 237634, count = 7, usage = 0.14, bonusList = {} },
                                },
                                WAIST = {
                                    { itemID = 237635, count = 29, usage = 0.58, bonusList = {} },
                                    { itemID = 237636, count = 14, usage = 0.28, bonusList = {} },
                                    { itemID = 237637, count = 7, usage = 0.14, bonusList = {} },
                                },
                                LEGS = {
                                    { itemID = 237638, count = 38, usage = 0.76, bonusList = {} },
                                    { itemID = 237639, count = 7, usage = 0.14, bonusList = {} },
                                    { itemID = 237640, count = 5, usage = 0.10, bonusList = {} },
                                },
                                FEET = {
                                    { itemID = 237641, count = 32, usage = 0.64, bonusList = {} },
                                    { itemID = 237642, count = 12, usage = 0.24, bonusList = {} },
                                    { itemID = 237643, count = 6, usage = 0.12, bonusList = {} },
                                },
                                BACK = {
                                    { itemID = 237644, count = 28, usage = 0.56, bonusList = {} },
                                    { itemID = 237645, count = 15, usage = 0.30, bonusList = {} },
                                    { itemID = 237646, count = 7, usage = 0.14, bonusList = {} },
                                },
                                FINGER = {
                                    { itemID = 237647, count = 27, usage = 0.54, bonusList = {} },
                                    { itemID = 237648, count = 21, usage = 0.42, bonusList = {} },
                                    { itemID = 237649, count = 17, usage = 0.34, bonusList = {} },
                                    { itemID = 237650, count = 11, usage = 0.22, bonusList = {} },
                                    { itemID = 237651, count = 8, usage = 0.16, bonusList = {} },
                                },
                                TRINKET = {
                                    { itemID = 237652, count = 41, usage = 0.82, bonusList = {} },
                                    { itemID = 237653, count = 34, usage = 0.68, bonusList = {} },
                                    { itemID = 237654, count = 15, usage = 0.30, bonusList = {} },
                                    { itemID = 237655, count = 9, usage = 0.18, bonusList = {} },
                                    { itemID = 237656, count = 5, usage = 0.10, bonusList = {} },
                                },
                                MAIN_HAND = {
                                    { itemID = 237657, count = 39, usage = 0.78, bonusList = {} },
                                    { itemID = 237658, count = 8, usage = 0.16, bonusList = {} },
                                    { itemID = 237659, count = 3, usage = 0.06, bonusList = {} },
                                },
                                OFF_HAND = {},
                            },
                            gems = {
                                { itemID = 213743, count = 34, usage = 0.68 },
                                { itemID = 213744, count = 21, usage = 0.42 },
                                { itemID = 213745, count = 13, usage = 0.26 },
                                { itemID = 213746, count = 8, usage = 0.16 },
                                { itemID = 213747, count = 5, usage = 0.10 },
                            },
                            enchants = {
                                WEAPON = {
                                    { enchantID = 10001, count = 39, usage = 0.78, source = { type = "item", id = 223759 } },
                                    { enchantID = 10002, count = 8, usage = 0.16, source = { type = "item", id = 223760 } },
                                    { enchantID = 10003, count = 3, usage = 0.06, source = { type = "item", id = 223761 } },
                                },
                                RING = {
                                    { enchantID = 10011, count = 35, usage = 0.70, source = { type = "item", id = 223762 } },
                                    { enchantID = 10012, count = 10, usage = 0.20, source = { type = "item", id = 223763 } },
                                    { enchantID = 10013, count = 5, usage = 0.10, source = { type = "item", id = 223764 } },
                                },
                            },
                            stats = {
                                versatility = 0.281,
                                haste = 0.214,
                                mastery = 0.167,
                                crit = 0.093,
                            },
                        },
                    },
                },
            },
        },
    },
}
