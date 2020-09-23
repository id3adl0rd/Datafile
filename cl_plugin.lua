local PLUGIN = PLUGIN 

surface.CreateFont("MiddleLabels", {
    font = "DermaLarge",
    size = 21,
    weight = 0,
})

surface.CreateFont("TopBoldLabel", {
    font = "DermaLarge",
    size = 21,
    weight = 500,
    antialias = true,
})

surface.CreateFont("TopLabel", {
    font = "Helvetica",
    size = 23,
    weight = 0,
    antialias = true,
})

local colours = {
    white = Color(180, 180, 180, 255),
    red = Color(231, 76, 60, 255),
    green = Color(39, 174, 96),
    blue = Color(41, 128, 185, 255),
} 

-- Remove an entry, send extra data for validation purposes.
function Datafile:RemoveEntry(target, key, date, category, text)
	net.Start("RemoveDatafileLine")
        net.WriteEntity(target)
        net.WriteUInt(key, 8)
        net.WriteString(date)
        net.WriteString(date)
        net.WriteString(date)
    net.SendToServer()
end

-- Update a player their Civil Status.
function Datafile:UpdateCivilStatus(target, tier)
	net.Start("UpdateCivilStatus")
        net.WriteEntity(target)
        net.WriteString(tier)
    net.SendToServer()
	self:Refresh(target)
end

-- A small delay is added for callback reasons. Really disgusting solution.
function Datafile:Refresh(target)
	timer.Simple(0.05, function()
		PLUGIN.Datafile:Close()
		net.Start("RefreshDatafile")
            net.WriteEntity(target)
        net.SendToServer()
	end)
end