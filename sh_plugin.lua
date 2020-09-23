local PLUGIN = PLUGIN 
Datafile = Datafile or {}

PLUGIN.name = "Datafile"
PLUGIN.author = "James"
PLUGIN.description = "Adds /Datafile."

ix.util.Include("cl_plugin.lua") 
ix.util.Include("cl_hooks.lua") 
ix.util.Include("sv_plugin.lua") 
ix.util.Include("sv_hooks.lua") 

-- All the categories possible. Yes, the names are quite annoying.
Datafile.Categories = {
	["med"] = true,     -- Medical note.
	["union"] = true,   -- Union (CWU, WI, UP) type note.
	["civil"] = true    -- Civil Protection/CTA type note.
} 

DATAFILE_PERMISSION_NONE = 0 
DATAFILE_PERMISSION_MINOR = 1 
DATAFILE_PERMISSION_MEDIUM = 2 
DATAFILE_PERMISSION_FULL = 3 
DATAFILE_PERMISSION_ELEVATED = 4 

-- Permissions for the numerous factions.
Datafile.Permissions = {
	[FACTION_CITIZEN] = DATAFILE_PERMISSION_FULL,
	[FACTION_MPF] = DATAFILE_PERMISSION_FULL,
} 

-- All the civil statuses. Just for verification purposes.
Datafile.CivilStatus = {
	"Anti-Citizen",
	"Citizen",
	"Black",
	"Brown",
	"Red",
	"Blue",
	"Green",
	"White",
	"Gold",
	"Platinum",
} 

Datafile.Default = {
	GenericData = {
        bol = {false, ""},
        restricted = {false, ""},
        civilStatus = "Citizen",
        lastSeen = os.date("%H:%M:%S - %d/%m/%Y", os.time()),
        points = 0,
        sc = 0,
	},
	CivilianData = {
        [1] = {
           	category = "union", -- med, union, civil
            text = "TRANSFERRED TO DISTRICT WORKFORCE.",
            date = os.date("%H:%M:%S - %d/%m/%Y", os.time()),
            points = "0",
            poster = {"Overwatch", "BOT"},
        },
	},
	CombineData = {
        [1] = {
           	category = "union", -- med, union, civil
            text = "INSTATED AS CIVIL PROTECTOR.",
            date = os.date("%H:%M:%S - %d/%m/%Y", os.time()),
            points = "0",
            poster = {"Overwatch", "BOT"},
        },
	},
} 

do
	local COMMAND = {}
	COMMAND.description = "View the datafile of someone."
	COMMAND.arguments = {ix.type.player}

	function COMMAND:OnRun(client, target)
		if (Datafile:IsRestrictedFaction(target)) then
			return "This datafile does not exist."
		else
			Datafile:HandleDatafile(client, target)
		end
	end

	ix.command.Add("Datafile", COMMAND)

	COMMAND = {}
	COMMAND.arguments = {ix.type.player}
	COMMAND.superAdminOnly = true

	function COMMAND:OnRun(client, target)
		Datafile:ClearDatafile(target)
	end

	ix.command.Add("ClearDatafile", COMMAND)

	COMMAND = {}
	COMMAND.description = "Manage the datafile of someone."
	COMMAND.arguments = {ix.type.player}

	function COMMAND:OnRun(client, target)
		local permission = PLUGIN:ReturnPermission(client)

		if (permission == DATAFILE_PERMISSION_ELEVATED) then
			PLUGIN:ReturnDatafile(target, nil, true, function(result)
				net.Start("CreateManagementPanel")
					net.WriteEntity(target)
					net.WriteTable(result)
				net.Send(client)
			end)
		else
			return "You are not authorized to access this datafile."
		end
	end

	ix.command.Add("ManageDatafile", COMMAND)

	COMMAND = {}
	COMMAND.description = "Make someone their datafile (un)restricted."
	COMMAND.arguments = {
		ix.type.player,
		bit.bor(ix.type.string, ix.type.optional)
	}

	function COMMAND:OnRun(client, target, reason)
		if (!reason or reason == "") then
			reason = nil
		end

		if (Datafile:ReturnPermission(client) >= DATAFILE_PERMISSION_FULL) then
			if (reason) then
				Datafile:SetRestricted(true, reason, target, client)

				return target:Name() .. "'s file has been restricted."
			else
				Datafile:SetRestricted(false, "", target, client)

				return target:Name() .. "'s file has been unrestricted."
			end
		else
			return "You do not have access to this datafile!"
		end
	end

	ix.command.Add("RestrictDatafile", COMMAND)
end	