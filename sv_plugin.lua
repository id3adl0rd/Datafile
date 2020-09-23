local PLUGIN = PLUGIN

ix.log.AddType("datafile_entryadd", function(player, ...)
	local arg = {...}
	return Format('%s has added an entry to %s'.."'s datafile with category: %s", player:Name(), arg[1], arg[2])
end, FLAG_WARNING)

ix.log.AddType("datafile_entryrem", function(player, ...)
	local arg = {...}
	return Format('%s has removed an entry of %s'.."'s datafile with category: %s", player:Name(), arg[1], arg[2])
end, FLAG_WARNING)

ix.log.AddType("datafile_civilstatus", function(player, ...)
	local arg = {...}
	return Format('%s has changed %s'.."'s Civil Status to: %s", player:Name(), arg[1], arg[2])
end, FLAG_WARNING)

-- Update the player their datafile.
function Datafile:UpdateDatafile(player, GenericData, datafile)
	/* Datafile structure:
		table to JSON encoded with CW function:
		GenericData = {
			bol = {false, ""},
			restricted = {false, ""},
			civilStatus = "",
			lastSeen = "",
			points = 0,
			sc = 0,
		} 
		Datafile = {
			entries[k] = {
				category = "", -- med, union, civil
				hidden = boolean,
				text = "",
				date = "",
				points = "",
				poster = {charName, steamID, color},
			},
		} 
	*/

	if (IsValid(player)) then
		local schemaFolder = Schema.folder
		local character = player:GetCharacter()

		-- Update all the values of a player.
		local updateObj = mysql:Update("ix_datafile") 
			updateObj:Where("CharacterID", character:GetID())
			updateObj:Where("SteamID", player:SteamID()) 
			updateObj:Where("Schema", schemaFolder) 
			updateObj:Update("CharacterName", character:GetName()) 
			updateObj:Update("GenericData", util.TableToJSON(GenericData)) 
			updateObj:Update("Datafile", util.TableToJSON(datafile))
		updateObj:Execute() 

		self:LoadDatafile(player) 
	end 
end 

-- Add a new entry. bCommand is used to prevent logging when /AddEntry is used.
function Datafile:AddEntry(category, text, points, player, poster, bCommand)
	if (!self.Categories[category]) then return false end 
	if ((self:ReturnPermission(poster) <= DATAFILE_PERMISSION_MINOR and category == "civil") or self:ReturnPermission(poster) == DATAFILE_PERMISSION_NONE) then return  end 

	local GenericData = self:ReturnGenericData(player) 
	local datafile = self:ReturnDatafile(player) 

	-- If the player isCombine, add SC instead.
	if (player:IsCombine()) then
		GenericData.sc = GenericData.sc + points 
	else
		GenericData.points = GenericData.points + points 
	end 

	-- Add a new entry with all the following values.
	datafile[#datafile + 1] = {
		category = category,
		hidden = false,
		text = text,
		date = os.date("%H:%M:%S - %d/%m/%Y", os.time()),
		points = points,
		poster = {
			poster:GetCharacter():GetName(),
			poster:SteamID(),
			team.GetColor(poster:Team()),
		},
	} 

	-- Update the player their file with the new entry and possible points addition.
	self:UpdateDatafile(player, GenericData, datafile) 

	ix.log.Add(poster, "datafile_entryadd", player:Name(), category)
end 

-- Set a player their Civil Status.
function Datafile:SetCivilStatus(player, poster, civilStatus)
	if (!table.HasValue(PLUGIN.CivilStatus, civilStatus)) then return  end 
	if (self:ReturnPermission(poster) < DATAFILE_PERMISSION_MINOR) then return  end 

	local GenericData = self:ReturnGenericData(player) 
	local datafile = self:ReturnDatafile(player) 
	GenericData.civilStatus = civilStatus 

	self:AddEntry("union", poster:GetCharacter():GetName() .. " has changed " .. player:GetCharacter():GetName() .. "'s Civil Status to: " .. civilStatus, 0, player, poster) 
	self:UpdateDatafile(player, GenericData, datafile) 

	ix.log.Add(poster, "datafile_civilstatus", player:Name(), Datafile.CivilStatus[civilStatus])
end 

-- Clear a character's datafile.
function Datafile:ClearDatafile(player)
	if (player:IsCombine()) then
		self:UpdateDatafile(player, Datafile.Default.GenericData, Datafile.Default.CombineData) 
	else
		self:UpdateDatafile(player, Datafile.Default.GenericData, Datafile.Default.CivilianData) 
	end 
end 

-- Update the time a player has last been seen.
function Datafile:UpdateLastSeen(player)
	local GenericData = self:ReturnGenericData(player) 
	local datafile = self:ReturnDatafile(player) 
	GenericData.lastSeen = os.date("%H:%M:%S - %d/%m/%Y", os.time()) 

	self:UpdateDatafile(player, GenericData, datafile) 
end 

-- Enable or disable a BOL on the player.
function Datafile:SetBOL(bBOL, text, player, poster)
	if (self:ReturnPermission(poster) <= DATAFILE_PERMISSION_MINOR) then return  end 

	local GenericData = self:ReturnGenericData(player) 
	local datafile = self:ReturnDatafile(player) 

	if (bBOL) then
		-- add the BOL with the text
		GenericData.bol[1] = true 
		GenericData.bol[2] = text 

		self:AddEntry("union", poster:GetCharacter():GetName() .. " has put a bol on " .. player:GetCharacter():GetName(), 0, player, poster) 

	else
		-- remove the BOL, get rid of the text
		GenericData.bol[1] = false 
		GenericData.bol[2] = "" 

		self:AddEntry("union", poster:GetCharacter():GetName() .. " has removed a bol on " .. player:GetCharacter():GetName(), 0, player, poster) 
	end 

	self:UpdateDatafile(player, GenericData, datafile) 
end 

-- Make the file of a player restricted or not.
function Datafile:SetRestricted(bRestricted, text, player, poster)
	local GenericData = self:ReturnGenericData(player) 
	local datafile = self:ReturnDatafile(player) 

	if (bRestricted) then
		-- make the file restricted with the text
		GenericData.restricted[1] = true 
		GenericData.restricted[2] = text 

		self:AddEntry("civil", poster:GetCharacter():GetName() .. " has made " .. player:GetCharacter():GetName() .. "'s file restricted.", 0, player, poster) 
	else
		-- make the file unrestricted, set text to ""
		GenericData.restricted[1] = false 
		GenericData.restricted[2] = "" 

		self:AddEntry("civil", poster:GetCharacter():GetName() .. " has removed the restriction on " .. player:GetCharacter():GetName() .. "'s file.", 0, player, poster) 
	end 

	self:UpdateDatafile(player, GenericData, datafile) 
end 

-- Remove an entry by checking for the key & validating it is the entry.
function Datafile:RemoveEntry(player, target, key, date, category, text)
	local GenericData = self:ReturnGenericData(target) 
	local datafile = self:ReturnDatafile(target) 

	if (datafile[key].date == date and datafile[key].category == category and datafile[key].text == text) then
		table.remove(datafile, key) 

		self:UpdateDatafile(target, GenericData, datafile) 

		ix.log.Add(player, "datafile_civilstatus", target:Name(), category)
	end 
end 

-- Return the amount of points someone has.
function Datafile:ReturnPoints(player)
	local GenericData = self:ReturnGenericData(player) 

	if (player:IsCombine()) then
		return GenericData.sc 
	else
		return GenericData.points 
	end 
end 

function Datafile:ReturnCivilStatus(player)
	local GenericData = self:ReturnGenericData(player) 

	return GenericData.civilStatus 
end 

-- Return GenericData in normal table format.
function Datafile:ReturnGenericData(player)
	return player.Datafile.GenericData 
end 

-- Return Datafile in normal table format.
function Datafile:ReturnDatafile(player)
	return player.Datafile.Datafile 
end 

-- Return the BOL of a player.
function Datafile:ReturnBOL(player)
	local GenericData = self:ReturnGenericData(player) 
	local bHasBOL = GenericData.bol[1] 
	local BOLText = GenericData.bol[2] 

	if (bHasBOL) then
		return true, BOLText 
	else
		return false, "" 
	end 
end 

-- Return the permission of a player. The higher, the more privileges.
function Datafile:ReturnPermission(player)
	local faction = player:Team()
	local permission = DATAFILE_PERMISSION_NONE 

	if (self.Permissions[faction]) then
		permission = self.Permissions[faction] 
	end 

	return permission 
end 

-- Returns if the player their file is restricted or not, and the text if it is.
function Datafile:IsRestricted(player)
	local GenericData = self:ReturnGenericData(player) 
	local bIsRestricted = GenericData.restricted[1] 
	local restrictedText = GenericData.restricted[2] 

	return bIsRestricted, restrictedText 
end 

-- If the player is apart of any of the factions allowing a datafile, return false.
function Datafile:IsRestrictedFaction(player)
	local factionTable = ix.faction.indices[player:Team()]

	if (factionTable.bAllowDatafile) then
		return false 
	end 

	return true 
end 