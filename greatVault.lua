-- greatVault.lua
-- Handles getting characters great vault data
local AddonName, TooManyAlts_env = ...

--[[
    function that calls 
        activities = C_WeeklyRewards.GetActivities([type])      (https://wowpedia.fandom.com/wiki/API_C_WeeklyRewards.GetActivities)
    
        saves in table
            progress to x/8 threshold for m+
            progress for x/6 threshold for raid
            level progress and reward teir we are at currently.


--