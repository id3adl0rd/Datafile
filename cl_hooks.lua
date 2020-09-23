local PLUGIN = PLUGIN

-- Open the datafile, start the population functions. Restricted: means it is limited.
net.Receive("CreateRestrictedDatafile", function()
	local target = net.ReadEntity()
	local GenericData = net.ReadTable()
	local datafile = net.ReadTable()

	PLUGIN.Datafile = vgui.Create("ixRestrictedDatafile")
	PLUGIN.Datafile:PopulateDatafile(target, datafile)
	PLUGIN.Datafile:PopulateGenericData(target, datafile, GenericData)
end)

-- Create the full datafile.
net.Receive("CreateFullDatafile", function()
	local target = net.ReadEntity()
	local GenericData = net.ReadTable()
	local datafile = net.ReadTable()

	PLUGIN.Datafile = vgui.Create("ixFullDatafile")
	PLUGIN.Datafile:PopulateDatafile(target, datafile)
	PLUGIN.Datafile:PopulateGenericData(target, datafile, GenericData)
end)

-- Management panel, for removing entries.
net.Receive("CreateManagementPanel", function()
	local target = net.ReadEntity()
	local datafile = net.ReadTable()

	PLUGIN.Managefile = vgui.Create("ixDfManageFile");
	PLUGIN.Managefile:PopulateEntries(target, datafile);
end)
