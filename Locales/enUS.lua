
local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale("Aanye_XP", "enUS", true)
if not L then return end

L["Aanye_XP"] = true
-- LDB Display
L["Level"] = true
L["No Faction Selected"] = true
-- Tooltip: Experience Mode
L["Experience Summary"] = true
L["Character is currently at maximum possible level."] = true
L["XP gains are disabled for this Character."] = true
L["Current Experience:"] = true
L["Rest:"] = true
L["Remaining to Level:"] = true
-- Tooltip: Reputation Mode
L["Reputation Summary:"] = true
L["To track a faction reputation, select a faction from the"] = true
L["Reputation window and check \34Show as Experience Bar\34."] = true
L["Standing:"] = true
L["Current Reputation:"] = true
L["Remaining to X:"] = function(X) return "Remaining to "..X..":"; end
-- Tooltip: Heart of Azeroth Mode
L["Heart of Azeroth Summary"] = true
