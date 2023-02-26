
local PLUGIN = PLUGIN 

-- Datafile management panel. Allows one to remove/edit entries.
local PANEL = {} 

function PANEL:Init() 
	self:SetTitle("") 
	
	self:SetSize(700, 400) 
	self:Center() 

	self:MakePopup() 

	self.List = vgui.Create("DListView", self) 
	self.List:Dock(FILL) 
	self.List:SetSortable(false)
	self.List:SetMultiSelect(false)
	self.List:AddColumn("date") 
	self.List:AddColumn("category") 
	self.List:AddColumn("text") 
	self.List:AddColumn("points") 
	self.List:AddColumn("poster") 

	self.Delete = vgui.Create("ixDfButton", self) 
	self.Delete:SetText("Delete Entry") 
	self.Delete:SetMetroColor(Color(200, 50, 0, 255))
	self.Delete:Dock(BOTTOM) 
	self.Delete:DockMargin(0, 5, 0, 0) 

	-- Ensure the variable doesn't exist anymore.
	self.DoClose = function()
        PLUGIN.ManageFile = nil 
    end 
end 

function PANEL:Paint(w, h)
  surface.SetDrawColor(Color(40, 40, 40, 150)) 
  surface.DrawRect(0, 0, w, h) 

  surface.SetDrawColor(Color(255, 255, 255, 100)) 
  surface.DrawOutlinedRect(0, 0, w, h) 
end 

function PANEL:PopulateEntries(target, datafile)
	self:SetTitle(target:Name() .. "'s datafile") 

	for k, v in pairs(datafile) do
		self.List:AddLine(
			v.date,
			v.category,
			v.text,
			v.points,
			v.poster[1]
		)
	end 

	self.Delete.DoClick = function()
		local key = self.List:GetSelectedLine() 
		local line = self.List:GetLine(key)

		if (key) then
			local date = line:GetValue(1) 
			local category = line:GetValue(2) 
			local text = line:GetValue(3) 

			Datafile:RemoveEntry(target, key, date, category, text) 
			Datafile:RefreshManagefile(target) 
		end 
  	end 
end 

vgui.Register("ixDfManageFile", PANEL, "DFrame") 