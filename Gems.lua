-- Gems.lua
-- Handles determining if items are missing gems 
local AddonName, TooManyAlts_env = ...

--Use GetItemInfo(itemLink) to get an items info, parsing each line to determine if it has a socket, counting how many sockets it has, as well as if it has a socket in it. 