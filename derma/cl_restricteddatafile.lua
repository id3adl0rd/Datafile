local PLUGIN = PLUGIN 

local colours = {
	white = Color(180, 180, 180, 255),
	red = Color(231, 76, 60, 255),
	green = Color(39, 174, 96),
	blue = Color(41, 128, 185, 255),
} 

-- Main datafile panel.
local PANEL = {} 

function PANEL:Init()
	self:SetTitle("") 

	self:SetSize(475, 570) 
	self:Center() 

	self:MakePopup() 

	self.Status = "" 

	-- Creation of all elements, text is set in the population functions.
	self.TopPanel = vgui.Create("ixDfPanel", self) 
	
	-- TODO: Add the CID here!
	self.NameLabel = vgui.Create("DLabel", self.TopPanel) 
	self.NameLabel:SetTextColor(Color(255, 255, 255)) 
	self.NameLabel:SetFont("DermaLarge") 
	self.NameLabel:Dock(TOP) 
	self.NameLabel:DockMargin(5, 5, 0, 0) 
	self.NameLabel:SizeToContents(true) 

	self.InfoPanel = vgui.Create("ixDfInfoPanel", self.TopPanel) 

	self.HeaderPanel = vgui.Create("ixDfHeaderPanel", self) 
	self.HeaderPanel:MakeRestricted(true) 

	self.Entries = vgui.Create("ixDfEntriesPanel", self) 
	self.Entries:MakeRestricted(true) 

	-- Lower button panel.
	self.dButtons = vgui.Create("ixDfPanel", self) 
	self.dButtons:Dock(BOTTOM) 
	self.dButtons:SetTall(35) 

	-- Upper button panel.
	self.uButtons = vgui.Create("ixDfPanel", self) 
	self.uButtons:Dock(BOTTOM) 
	self.uButtons:SetTall(35) 

	-- Upper buttons. Population will be done below.
	self.uLeftButton = vgui.Create("ixDfButton", self.uButtons) 
	self.uLeftButton:SetText("ADD NOTE") 
	self.uLeftButton:SetMetroColor(colours.blue) 
	self.uLeftButton:Dock(LEFT) 

	self.uRightButton = vgui.Create("ixDfButton", self.uButtons) 
	self.uRightButton:SetText("ADD MEDICAL RECORD") 
	self.uRightButton:SetMetroColor(colours.green) 
	self.uRightButton:Dock(RIGHT) 

	-- Bottom buttons.
	self.dLeftButton = vgui.Create("ixDfButton", self.dButtons) 
	self.dLeftButton:SetText("UPDATE LAST SEEN") 
	self.dLeftButton:Dock(LEFT) 

	self.dMiddleButton = vgui.Create("ixDfButton", self.dButtons) 
	self.dMiddleButton:SetText("CHANGE CIVIL STATUS") 
	self.dMiddleButton:Dock(RIGHT) 

	self.DoClose = function()
        PLUGIN.Datafile = nil 
    end 
end 

function PANEL:PopulateDatafile(target, datafile)
	for k, v in pairs(datafile) do
		local text = datafile[k].text 
		local date = datafile[k].date 
		local poster = datafile[k].poster[1] 
		local points = tonumber(datafile[k].points) 
		local color = datafile[k].poster[3] 
        
        if (datafile[k].category == "union") then
            local entry = vgui.Create("ixDfEntry", self.Entries.Left) 
            entry:SetEntryText(text, date, "~ " .. poster, points, color) 
            
        elseif (datafile[k].category == "med") then
            local entry = vgui.Create("ixDfEntry", self.Entries.Right) 
            entry:SetEntryText(text, date, "~ " .. poster, points, color) 
        end     end 
end 

function PANEL:PopulateGenericData(target, datafile, GenericData)
	local bIsCombine = target:IsCombine()
	local bIsAntiCitizen 
	local bHasBOL = GenericData.bol[1] 
	local civilStatus = GenericData.civilStatus 
	local lastSeen = GenericData.lastSeen

	if (bIsCombine) then
        points = GenericData.sc 
        self.InfoPanel:SetInfoText(civilStatus, points, lastSeen) 
    else
        points = GenericData.points 
        self.InfoPanel:SetInfoText(civilStatus, points, lastSeen) 
    end 

	if (GenericData.civilStatus == "Anti-Citizen") then
        bIsAntiCitizen = true 
    end 

    if (bHasBol) then
        self.Status = "yellow" 
        self.dRightButton:SetText("REMOVE BOL") 
    elseif (bIsAntiCitizen) then
        self.Status = "red" 
    elseif (bIsCombine) then
        self.Status = "blue" 
    end 

    self.NameLabel:SetText(target:Name()) 

 	self.dLeftButton.DoClick = function()
		net.Start("UpdateLastSeen")
            net.WriteEntity(target)
        net.SendToServer()
		Datafile:Refresh(target) 
	end 

    self.uLeftButton.DoClick = function()
        local entryPanel = vgui.Create("ixDfNoteEntry") 
        entryPanel:SendInformation(target) 
    end 

    self.uRightButton.DoClick = function()
        local entryPanel = vgui.Create("ixDfMedicalEntry") 
        entryPanel:SendInformation(target) 
    end 

     self.dMiddleButton.DoClick = function()
        self.Menu = DermaMenu() 

        self.Menu:AddOption("Anti-Citizen", function()
            Datafile:UpdateCivilStatus(target, "Anti-Citizen") 
        end):SetImage("icon16/box.png") 

        self.Menu:AddSpacer() 

        self.Menu:AddOption("Citizen", function()
            Datafile:UpdateCivilStatus(target, "Citizen") 
        end):SetImage("icon16/user.png") 

        self.Menu:AddSpacer() 

        self.Menu:AddOption("Black", function()
            Datafile:UpdateCivilStatus(target, "Black") 
        end):SetImage("icon16/user_gray.png") 

        self.Menu:AddOption("Brown", function()
            Datafile:UpdateCivilStatus(target, "Brown") 
        end):SetImage("icon16/briefcase.png") 

        self.Menu:AddOption("Red", function()
            Datafile:UpdateCivilStatus(target, "Red") 
        end):SetImage("icon16/flag_red.png") 

        self.Menu:AddOption("Blue", function()
            Datafile:UpdateCivilStatus(target, "Blue") 
        end):SetImage("icon16/flag_blue.png") 

        self.Menu:AddOption("Green", function()
            Datafile:UpdateCivilStatus(target, "Green") 
        end):SetImage("icon16/flag_green.png") 

        self.Menu:AddOption("White", function()
            Datafile:UpdateCivilStatus(target, "White") 
        end):SetImage("icon16/award_star_silver_3.png") 

        self.Menu:AddOption("Gold", function()
            Datafile:UpdateCivilStatus(target, "Gold") 
        end):SetImage("icon16/award_star_gold_3.png") 

        self.Menu:AddOption("Platinum", function()
            Datafile:UpdateCivilStatus(target, "Platinum") 
        end):SetImage("icon16/shield.png") 

        self.Menu:Open() 
    end 
end 

function PANEL:Paint(w, h)
    local sineToColor = math.abs(math.sin(RealTime() * 1.5) * 255) 
    local color 

    if (self.Status == "yellow") then
        color = Color(sineToColor, sineToColor, 0, 200) 

    elseif (self.Status == "red") then
        color = Color(sineToColor, 0, 0, 200) 

    elseif (self.Status == "blue") then
        color = Color(0, 200, 200, 200)
    else
        color = Color(170, 170, 170, 255) 
    end 

	surface.SetDrawColor(Color(40, 40, 40, 150)) 
	surface.DrawRect(0, 0, w, h) 

	surface.SetDrawColor(color) 
	surface.DrawOutlinedRect(0, 0, w, h)
end 

vgui.Register("ixRestrictedDatafile", PANEL, "DFrame") 