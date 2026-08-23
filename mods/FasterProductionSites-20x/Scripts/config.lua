-- config.lua
-- Configuration module for FasterProductionSites

local Config = {}

----------------------------------------------------------------
-- Default multiplier, used for any site type not listed below.
-- 2  = twice as fast
-- 5  = five times as fast
-- 10 = ten times as fast
-- 1 (or less) leaves that site type at vanilla speed.
----------------------------------------------------------------
Config.multiplier = 20

----------------------------------------------------------------
-- Per-site-type overrides. Keys are the DataTable row name (i.e.
-- AssignDefineDataId with its trailing "_<instance index>" stripped --
-- e.g. the 3rd Stone Pit you build is "StonePit_2" in-game, which maps to
-- the "StonePit" key here). Set a value to 1 to leave that specific site
-- type at vanilla speed while the others stay boosted (or delete its line
-- entirely to fall back to Config.multiplier above instead).
--
-- Values below are scaled to unlock progression (player level/tech tier
-- researched 2026-08-05): low multiplier for early-game sites, ramping up
-- for later/endgame ones, so the boost feels proportional to how long
-- you've had to wait to unlock each site rather than flat across the board.
--
-- Tried two per-row-computed recalibrations on 2026-08-08 (match-final-time-
-- within-tier, then a gently-rising-target-per-tier formula) -- both worked
-- but were judged overkill for what's fundamentally a simple QoL mod: bespoke
-- decimal multipliers per row (16.67x, 20.83x, ...) are hard to read/tune by
-- hand. Reverted to clean whole-number tier multipliers; only CopperPit_2 is
-- special-cased below since its vanilla baseline (1600) is far below its
-- tier-mate CopperPit's (8000), so the tier's flat multiplier made it
-- disproportionately fast.
----------------------------------------------------------------
Config.multipliers = {
    -- Tier 1 (~level 7): earliest sites
    StonePit         = 20, -- Stone Pit
    StationDeforest2 = 20, -- Logging Site (lower tier -- vanilla RequiredWorkAmount matches StonePit)

    -- Tier 2 (~level 24-38): early-mid
    CopperPit        = 20, -- Ore Mining Site
    CopperPit_2      = 20, -- Ore Mining Site II

    -- Tier 3 (~level 42-52): mid-late, mostly Ancient Technology / post-Tower unlocks
    StationDeforest3 = 20, -- Logging Site, upper tier (vanilla RequiredWorkAmount matches Coal/Sulfur/Oil below)
    CoalPit          = 20, -- Coal Quarry
    SulfurPit        = 20, -- Sulfur Quarry
    OilPump          = 20, -- Crude Oil Extractor
    OilPump02        = 20, -- High-Pressure Crude Oil Extractor
    QuartzPit        = 20, -- Quartz Mine

    -- Tier 4 (~level 62-72): endgame / Feybreak & Sky Island DLC content
    CrystalPit       = 20, -- Hexolite Quartz Mine
    SkyIslandOrePit  = 20, -- Soralite Quarry (Sky Islands / Sunreach)

    -- Tier 5 (tech level 78, latest-unlocking site in this mod): Ancient
    -- Material Synthesizer, confirmed row "AncientMultiProduct_Mining"
    -- (2026-08-08 live discovery log). Special-cased like CopperPit_2: its
    -- vanilla baseline (6666.7) is well below tier 4's (20000/25000), so the
    -- tier's flat 9x would finish it (740.7) FASTER than the earlier tier 4
    -- sites (2222.2/2777.8) -- backwards for the latest/hardest unlock. 3x
    -- instead lands it at 2222.2, matching CrystalPit.
    AncientMultiProduct_Mining = 20,
}

return Config
