
local PLUGIN = PLUGIN

util.AddNetworkString("UpdateLastSeen")
util.AddNetworkString("UpdateCivilStatus")
util.AddNetworkString("AddDatafileEntry")
util.AddNetworkString("SetBOL")
util.AddNetworkString("RequestPoints")
util.AddNetworkString("RemoveDatafileLine")
util.AddNetworkString("RefreshDatafile")
util.AddNetworkString("RefreshManagefile")
util.AddNetworkString("CreateRestrictedDatafile")
util.AddNetworkString("CreateFullDatafile")
util.AddNetworkString("CreateManagementPanel")

hook.Add("DatabaseConnected", "Datafile", function()
	Datafile:Setup()
end)

hook.Add("OnWipeTables", "Datafile", function()
	Datafile:Wipe()
end)

-- Check if the player has a datafile or not. If not, create one.
hook.Add("PlayerLoadedCharacter", "Datafile", function(player, character)
	local bHasDatafile = Datafile:HasDatafile(character)

	-- Nil because the bHasDatafile is not in every player their character data.
	if (!bHasDatafile and !Datafile:IsRestrictedFaction(player)) then
		Datafile:CreateDatafile(player)
	end

	-- load the datafile again with the new changes.
	Datafile:LoadDatafile(player)
end)

-- Check if the player has a datafile or not. If not, create one.
hook.Add("CharacterDeleted", "Datafile", function(player, id, isCurrentChar)
	local query = mysql:Select("ix_datafile")
		query:Where("id", id)
		query:Where("SteamID", player:SteamID64())
		query:Callback(function(result)
			local Tquery = mysql:Delete("ix_datafile")
				Tquery:Where("id", id)
			Tquery:Execute()
		end)
	query:Execute()
end)

function Datafile:Setup()
	local query = mysql:Create("ix_datafile")
		query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("CharacterID", "VARCHAR(50) NOT NULL")
		query:Create("CharacterName", "VARCHAR(150) NOT NULL")
		query:Create("SteamID", "VARCHAR(60) NOT NULL")
		query:Create("Schema", "TEXT NOT NULL")
		query:Create("GenericData", "TEXT NOT NULL")
		query:Create("Datafile", "TEXT NOT NULL")
		query:PrimaryKey("id")
	query:Execute()
end

function Datafile:Wipe()
	mysql:Drop("ix_datafile"):Execute()
end

-- Function to load the datafile on the player"s character. Used after updating something in the MySQL.
function Datafile:LoadDatafile(player)
	if (IsValid(player)) then
		local schemaFolder = Schema.folder
		local character = player:GetCharacter()

		if character then
			local queryObj = mysql:Select("ix_datafile")
				queryObj:Where("CharacterID", character:GetID())
				queryObj:Where("SteamID", player:SteamID())
				queryObj:Where("Schema", schemaFolder)
				queryObj:Callback(function(result, status, lastID)
					if (!IsValid(player)) then return end

					if (istable(result) and #result >= 1) then
						player.Datafile = {
							GenericData = util.JSONToTable(result[1].GenericData),
							Datafile = util.JSONToTable(result[1].Datafile)
						}
					end
				end)
			queryObj:Execute()
		end
	end
end

-- Create a datafile for the player.
function Datafile:CreateDatafile(player)
	if (IsValid(player)) then
		local schemaFolder = Schema.folder
		local character = player:GetCharacter()
		local steamID = player:SteamID()

		local defaultDatafile = self.Default.CivilianData

		if (player:IsCombine()) then
			defaultDatafile = self.Default.CombineData
		end

		-- Set all the values.
		local insertObj = mysql:Insert("ix_datafile")
			insertObj:Insert("CharacterID", character:GetID())
			insertObj:Insert("CharacterName", character:GetName())
			insertObj:Insert("SteamID", steamID)
			insertObj:Insert("Schema", schemaFolder)
			insertObj:Insert("GenericData", util.TableToJSON(self.Default.GenericData))
			insertObj:Insert("Datafile", util.TableToJSON(defaultDatafile))
			insertObj:Callback(function(result)
				Datafile:SetHasDatafile(character, true)
			end)
		insertObj:Execute()
	end
end

-- Sets whether as character has a datafile.
function Datafile:SetHasDatafile(character, bhasDatafile)
	character:SetData("HasDatafile", bhasDatafile) 
end 

-- Returns true if the player has a datafile.
function Datafile:HasDatafile(character)
	return character:GetData("HasDatafile", false) 
end 

-- Datafile handler. Decides what to do when a player types /Datafile John Doe.
function Datafile:HandleDatafile(player, target)
	local playerValue = self:ReturnPermission(player) 
	local targetValue = self:ReturnPermission(target) 
	local bTargetIsRestricted, restrictedText = self:IsRestricted(player) 

	if (playerValue >= targetValue) then
		if (playerValue == DATAFILE_PERMISSION_NONE) then
			player:Notify("You are not authorized to access this datafile.") 

			return false 
		end 

		local GenericData = self:ReturnGenericData(target) 
		local datafile = self:ReturnDatafile(target) 

		if (playerValue == DATAFILE_PERMISSION_MINOR) then
			if (bTargetIsRestricted) then
				player:Notify("This datafile has been restricted  access denied. REASON: " .. restrictedText) 

				return false 
			end 

			for k, v in pairs(datafile) do
				if (v.category == "civil") then
					table.remove(datafile, k) 
				end 
			end

			net.Start("CreateRestrictedDatafile")
				net.WriteEntity(target)
				net.WriteTable(GenericData)
				net.WriteTable(datafile)
			net.Send(player)
		else
			net.Start("CreateFullDatafile")
				net.WriteEntity(target)
				net.WriteTable(GenericData)
				net.WriteTable(datafile)
			net.Send(player)
		end 

	elseif (playerValue < targetValue) then
		player:Notify("You are not authorized to access this datafile.") 

		return false 
	end 
end 

-- Update the last seen.
net.Receive("UpdateLastSeen", function (len, player)
	local target = net.ReadEntity()

	Datafile:UpdateLastSeen(target)
end)

-- Update the civil status.
net.Receive("UpdateCivilStatus", function (len, player)
	local target = net.ReadEntity()
	local civilStatus = net.ReadString()

	Datafile:SetCivilStatus(target, player, civilStatus)
end)

-- Add a new entry.
net.Receive("AddDatafileEntry", function (len, player)
	local target = net.ReadEntity()
	local category = net.ReadString()
	local text = net.ReadString()
	local points = net.ReadString()

	Datafile:AddEntry(category, text, points, target, player, false)
end)

-- Add/remove a BOL.
net.Receive("SetBOL", function (len, player)
	local target = net.ReadEntity()
	local bHasBOL = Datafile:ReturnBOL(player)

	if (bHasBOL) then
		Datafile:SetBOL(false, "", target, player)
	else
		Datafile:SetBOL(true, "", target, player)
	end
end)

-- Send the points of the player back to the user.
net.Receive("RequestPoints", function (len, player)
	local target = net.ReadEntity()

	if (Datafile:ReturnPermission(player) == DATAFILE_PERMISSION_MINOR and (Datafile:ReturnPermission(target) == DATAFILE_PERMISSION_NONE or Datafile:ReturnPermission(target) == DATAFILE_PERMISSION_MINOR)) then
		net.Start("SendPoints")
			net.WriteString(Datafile:ReturnPoints(target))
		net.Send(player)
	end
end)

-- Remove a line from someone their datafile.
net.Receive("RemoveDatafileLine", function (len, player)
	local target = net.ReadEntity()
	local key = net.ReadUInt(8)
	local date = net.ReadString()
	local category = net.ReadString()
	local text = net.ReadString()

	Datafile:RemoveEntry(player, target, key, date, category, text)
end)

-- Refresh the active datafile panel of a player.
net.Receive("RefreshDatafile", function (len, player)
	local target = net.ReadEntity()

	Datafile:HandleDatafile(player, target)
end)

net.Receive("RefreshManagefile", function (len, player)
	local target = net.ReadEntity()
	local result = Datafile:ReturnDatafile(player) 

	net.Start("CreateManagementPanel")
		net.WriteEntity(target)
		net.WriteTable(result)
	net.Send(player)
end)