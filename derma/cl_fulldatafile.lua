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
    
    self:SetSize(700, 570) 
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
    self.Entries = vgui.Create("ixDfEntriesPanel", self) 

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

    self.uMiddleButton = vgui.Create("ixDfButton", self.uButtons) 
    self.uMiddleButton:SetText("ADD CIVIL RECORD") 
    self.uMiddleButton:SetMetroColor(colours.red) 
    self.uMiddleButton:Dock(FILL) 

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
    self.dMiddleButton:Dock(FILL) 

    self.dRightButton = vgui.Create("ixDfButton", self.dButtons) 
    self.dRightButton:SetText("ADD BOL") 
    self.dRightButton:Dock(RIGHT) 

    self.DoClose = function()
        PLUGIN.Datafile = nil 
    end 
end 

-- Populate the datafile with the entries.
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

        elseif (datafile[k].category == "civil") then
            local entry = vgui.Create("ixDfEntry", self.Entries.Middle) 
            entry:SetEntryText(text, date, "~ " .. poster, points, color) 

        elseif (datafile[k].category == "med") then
            local entry = vgui.Create("ixDfEntry", self.Entries.Right) 
            entry:SetEntryText(text, date, "~ " .. poster, points, color) 
        end 
    end 
end 

-- Update the frame with all the relevant information.
function PANEL:PopulateGenericData(target, datafile, GenericData)
    local bIsCombine = target:IsCombine()
    local bIsAntiCitizen 
    local bHasBOL = GenericData.bol[1] 
    local civilStatus = GenericData.civilStatus 
    local lastSeen = GenericData.lastSeen
    local points = 0 

    self:SetTitle(target:Name() .. "'s Datafile") 

    -- The logic here can be done far better.
    if (bIsCombine) then
        points = GenericData.sc 

        self.InfoPanel.MiddleHeaderLabel:SetText("CREDITS") 
        self.InfoPanel:SetInfoText(civilStatus, points, lastSeen) 
    else
        points = GenericData.points 
        self.InfoPanel:SetInfoText(civilStatus, points, lastSeen) 
    end 

    if (GenericData.civilStatus == "Anti-Citizen") then
        bIsAntiCitizen = true 
    end 

    if (bHasBOL) then
        self.Status = "yellow" 
        self.dRightButton:SetText("REMOVE BOL") 
    else
        self.Status = "" 
        self.dRightButton:SetText("ADD BOL")
    end 

    if (bIsAntiCitizen) then
        self.Status = "red" 
    elseif (bIsCombine) then
        self.Status = "blue" 
    end 

    self.NameLabel:SetText(target:Name()) 

    self.dRightButton.DoClick = function()
        net.Start("SetBOL")
            net.WriteEntity(target)
        net.SendToServer()
        Datafile:Refresh(target) 
    end 

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

    self.uMiddleButton.DoClick = function()
        local entryPanel = vgui.Create("ixDfCivilEntry") 
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
        color = Color(0, 100, 200, 200) 
    else
        color = Color(170, 170, 170, 255) 
    end 

    surface.SetDrawColor(Color(40, 40, 40, 150)) 
    surface.DrawRect(0, 0, w, h) 

    surface.SetDrawColor(color) 
    surface.DrawOutlinedRect(0, 0, w, h) 
end 

vgui.Register("ixFullDatafile", PANEL, "DFrame") 


-- Top panel/darker panel.
local PANEL = {} 

function PANEL:Init()
    self:Dock(TOP) 
    self:SetTall(85) 
end 

function PANEL:Paint(w, h)
    surface.SetDrawColor(Color(40, 40, 40, 255)) 
    surface.DrawRect(0, 0, w, h) 
end 

vgui.Register("ixDfPanel", PANEL, "DPanel") 


-- Header panel. Shows what category each tab is in.
local PANEL = {} 

function PANEL:Init()
    self:Dock(TOP) 
    self:DockMargin(0, 3, 0, 0) 
    self:SetTall(35) 

    self.Header1 = vgui.Create("DLabel", self) 
    self.Header1:SetText("NOTES") 
    self.Header1:SetTextColor(colours.blue) 
    self.Header1:SetFont("MiddleLabels") 
    self.Header1:Dock(FILL) 
    self.Header1:DockMargin(7, 0, 0, 0) 
    self.Header1:SetContentAlignment(4) 

    self.Header2 = vgui.Create("DLabel", self) 
    self.Header2:SetText("CIVIL RECORD") 
    self.Header2:SetTextColor(colours.red) 
    self.Header2:SetFont("MiddleLabels") 
    self.Header2:Dock(FILL) 
    self.Header2:DockMargin(0, 0, 0, 0) 
    self.Header2:SetContentAlignment(5) 

    self.Header3 = vgui.Create("DLabel", self) 
    self.Header3:SetText("MEDICAL RECORD") 
    self.Header3:SetTextColor(colours.green) 
    self.Header3:SetFont("MiddleLabels") 
    self.Header3:Dock(FILL) 
    self.Header3:DockMargin(0, 0, 7, 0) 
    self.Header3:SetContentAlignment(6) 
end 

function PANEL:MakeRestricted(bRestrict)
    if (bRestrict) then
        self.Header2:Remove() 
    end 
end 

function PANEL:Paint(w, h)
    surface.SetDrawColor(Color(40, 40, 40, 255)) 
    surface.DrawRect(0, 0, w, h) 
end 

vgui.Register("ixDfHeaderPanel", PANEL, "DPanel") 

-- Panel that will contain the entries & the 3 scroll bars.
local PANEL = {} 

function PANEL:Init()
    self:Dock(FILL) 

    self.Left = vgui.Create("ixDfScrollPanel", self) 
    self.Left:Dock(LEFT) 

    self.Middle = vgui.Create("ixDfScrollPanel", self) 
    self.Middle:Dock(FILL) 

    self.Right = vgui.Create("ixDfScrollPanel", self) 
    self.Right:Dock(RIGHT) 
end 

function PANEL:MakeRestricted(bRestrict)
    if (bRestrict) then
        self.Middle:Remove() 
    end 
end 

function PANEL:Paint(w, h)
    surface.SetDrawColor(Color(40, 40, 40, 255)) 
    surface.DrawRect(0, 0, w, h) 
end 

vgui.Register("ixDfEntriesPanel", PANEL, "DPanel") 

-- Darker scroll panel.
local PANEL = {} 

function PANEL:Init()
    self:SetWide(225) 
    self:DockMargin(5, 0, 5, 0)

    -- Can't figure out how to use the PAINT functions for this, if that's possible.
    self.SBar = self:GetVBar() 

    function self.SBar:Paint(w, h)
        surface.SetDrawColor(Color(38, 38, 38, 255)) 
        surface.DrawRect(0, 0, w, h) 
    end 
    
    function self.SBar.btnGrip:Paint(w, h)
        surface.SetDrawColor(Color(47, 47, 47, 255)) 
        surface.DrawRect(0, 0, w, h) 
    end 

    function self.SBar.btnUp:Paint(w, h)
        surface.SetDrawColor(Color(30, 30, 30, 255)) 
        surface.DrawRect(0, 0, w, h) 
    end 

    function self.SBar.btnDown:Paint(w, h)
        surface.SetDrawColor(Color(30, 30, 30, 255)) 
        surface.DrawRect(0, 0, w, h) 
    end 
end 

vgui.Register("ixDfScrollPanel", PANEL, "DScrollPanel") 

-- Darker buttons.
local PANEL = {} 

function PANEL:Init()
    self:SetTextColor(Color(180, 180, 180, 255)) 
    self:SetWide(225) 
    self:DockMargin(5, 2.5, 5, 2.5) 

    -- Reason why I'm doing the colours this way is because I don't want any filthy logic in my Paint function.
    self.MetroColor = colours.white 
    self.ButtonColor = Color(47, 47, 47, 255) 
end 

function PANEL:SetMetroColor(color)
    self.MetroColor = color 
end 

function PANEL:Paint(w, h)
    surface.SetDrawColor(self.ButtonColor) 
    surface.DrawRect(0, 0, w, h) 

    surface.SetDrawColor(self.MetroColor) 
    surface.DrawRect(0, h - 2, w, 2) 
end 

function PANEL:OnCursorEntered(w, h)
    self.ButtonColor = Color(38, 38, 38, 255) 
end 

function PANEL:OnCursorExited(w, h)
    self.ButtonColor = Color(47, 47, 47, 255) 
end 

vgui.Register("ixDfButton", PANEL, "DButton") 

-- Entry for one of the scroll panels.
local PANEL = {} 

function PANEL:Init()
    self:SetZPos(1) 
    self:SetTall(50) 
    self:Dock(TOP) 
    self:DockMargin(0, 5, 5, 0) 

    self.PosterColor = Color(180, 180, 180, 255) 

    self.Text = vgui.Create("DLabel", self) 
    self.Text:SetTextColor(Color(220, 220, 220, 255))
    self.Text:SetText("") 
    self.Text:SetWrap(true) 
    self.Text:Dock(FILL) 
    self.Text:DockMargin(5, 0, 0, 0) 
    self.Text:SetContentAlignment(5) 

    self.Date = vgui.Create("DLabel", self) 
    self.Date:SetTextColor(Color(150, 150, 150)) 
    self.Date:SetText("") 
    self.Date:SetWrap(true) 
    self.Date:Dock(TOP) 
    self.Date:DockMargin(5, 5, 0, 0) 
    self.Date:SetContentAlignment(7) 

    self.Poster = vgui.Create("DLabel", self) 
    self.Poster:SetWrap(true) 
    self.Poster:SetTextColor(self.PosterColor) 
    self.Poster:Dock(BOTTOM) 
    self.Poster:DockMargin(5, 0, 0, 5) 
    self.Poster:SetContentAlignment(1) 

    self.Points = vgui.Create("DLabel", self.Date) 
    self.Points:SetWrap(true) 
    self.Points:SetWide(20)
    self.Points:Dock(RIGHT) 
    self.Points:DockMargin(0, 0, 0, 0) 
    self.Points:SetContentAlignment(9) 
end 

function PANEL:Paint(w, h)
    surface.SetDrawColor(Color(47, 47, 47, 255)) 
    surface.DrawRect(0, 0, w, h) 

    surface.SetDrawColor(self.PosterColor) 
    surface.DrawRect(0, h - 2, w, 2) 
end 

function PANEL:SetEntryText(noteText, dateText, posterText, pointsText, posterColor)
    if (posterColor) then
        self.PosterColor = posterColor 
        self.Poster:SetTextColor(self.PosterColor) 
    end 

    self.Text:SetText(noteText) 
    self.Date:SetText(dateText) 
    self.Poster:SetText(posterText) 
    self.Points:SetText(pointsText) 

    if (pointsText < 0) then
        self.Points:SetTextColor(Color(255, 100, 100, 255))
    elseif (pointsText > 0) then
        self.Points:SetTextColor(Color(150, 255, 50, 255))
    else
        self.Points:SetText("") 
        self.Points:SetTextColor(Color(220, 220, 220, 255))
    end 

    self:SetTall(60 + (string.len(self.Text:GetText()) / 28) * 11) 
end     

vgui.Register("ixDfEntry", PANEL, "DPanel") 

-- Info panel. Panel below the name of the player.
local PANEL = {} 

function PANEL:Init()
    self:Dock(TOP) 
    self:SetTall(50) 

    self.LeftHeaderLabel = vgui.Create("DLabel", self) 
    self.LeftHeaderLabel:SetText("CIVIL STATUS") 
    self.LeftHeaderLabel:SetContentAlignment(4)
    self.LeftHeaderLabel:SetTextColor(Color(0, 150, 150, 255)) 
    self.LeftHeaderLabel:SetFont("TopBoldLabel") 
    self.LeftHeaderLabel:Dock(FILL) 
    self.LeftHeaderLabel:DockMargin(5, 5, 0, 0) 

    self.MiddleHeaderLabel = vgui.Create("DLabel", self) 
    self.MiddleHeaderLabel:SetText("POINTS") 
    self.MiddleHeaderLabel:SetContentAlignment(5)
    self.MiddleHeaderLabel:SetTextColor(Color(231, 76, 60, 255)) 
    self.MiddleHeaderLabel:SetFont("TopBoldLabel") 
    self.MiddleHeaderLabel:Dock(FILL) 
    self.MiddleHeaderLabel:DockMargin(5, 5, 0, 0) 

    self.RightHeaderLabel = vgui.Create("DLabel", self) 
    self.RightHeaderLabel:SetText("LAST SEEN") 
    self.RightHeaderLabel:SetContentAlignment(6)
    self.RightHeaderLabel:SetTextColor(Color(150, 150, 96, 255)) 
    self.RightHeaderLabel:SetFont("TopBoldLabel") 
    self.RightHeaderLabel:Dock(FILL) 
    self.RightHeaderLabel:DockMargin(0, 5, 5, 0) 

    self.TextPanel = vgui.Create("DPanel", self) 
    self.TextPanel:Dock(BOTTOM) 
    self.TextPanel:SetTall(25)
    self.TextPanel.Paint = function() return false end 

    self.LeftTextLabel = vgui.Create("DLabel", self.TextPanel) 
    self.LeftTextLabel:SetTextColor(Color(220, 220, 220, 255)) 
    self.LeftTextLabel:SetContentAlignment(4)
    self.LeftTextLabel:Dock(FILL) 
    self.LeftTextLabel:DockMargin(5, 5, 5, 5) 

    self.MiddleTextLabel = vgui.Create("DLabel", self.TextPanel) 
    self.MiddleTextLabel:SetTextColor(Color(0, 0, 0, 255)) 
    self.MiddleTextLabel:SetContentAlignment(5)
    self.MiddleTextLabel:Dock(FILL) 
    self.MiddleTextLabel:DockMargin(5, 5, 5, 5) 

    self.RightTextLabel = vgui.Create("DLabel", self.TextPanel) 
    self.RightTextLabel:SetTextColor(Color(220, 220, 220, 255)) 
    self.RightTextLabel:SetContentAlignment(6)
    self.RightTextLabel:Dock(FILL) 
    self.RightTextLabel:DockMargin(5, 5, 5, 5) 
end 

function PANEL:SetInfoText(leftBottom, middleBottom, rightBottom)
    self.LeftTextLabel:SetText(leftBottom) 
    self.MiddleTextLabel:SetText(middleBottom) 
    self.RightTextLabel:SetText(rightBottom) 

    if (tonumber(middleBottom) < 0) then
        self.MiddleTextLabel:SetTextColor(Color(255, 100, 100, 255))
    elseif (tonumber(middleBottom) > 0) then
        self.MiddleTextLabel:SetTextColor(Color(150, 255, 50, 255))
    else
        self.MiddleTextLabel:SetTextColor(Color(220, 220, 220, 255))
    end 
end 

function PANEL:Paint()
    return false 
end 

vgui.Register("ixDfInfoPanel", PANEL, "DPanel") 