-----------------------------------------------------------------------------------------------
-- Client Lua Script for Limited Architecture Set
-- Copyright (c) Wobin. All rights reserved

require "Window"
 

-----------------------------------------------------------------------------------------------
-- EldanScrolls Module Definition
-----------------------------------------------------------------------------------------------
local bHasConfigureFunction = false	
local tDependencies = {"Gemini:GUI-1.0", "Lib:ApolloFixes-1.0"}	

LimitedArchitectureSet = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("LimitedArchitectureSet", bHasConfigureFunction, tDependencies, "Gemini:Hook-1.0", "Gemini:Event-1.0")

local LAS = LimitedArchitectureSet

local Landscape, Remodel, ListWindow, Decorate

function LAS:OnInitialize()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
  	self.glog = GeminiLogging:GetLogger({ level = GeminiLogging.DEBUG, pattern = "%d %n %c %l - %m", appender = "GeminiConsole" })
  	Apollo.RegisterSlashCommand("las", "OnSlashCommand", self)
  	
  	-- Okay, terrible way of overriding stuff
  	self.HousingButtons = {}
  	self.HousingButtons.Landscape = Apollo.GetAddon("HousingLandscape")	
  	self.HousingButtons.Remodel = Apollo.GetAddon("HousingRemodel")
  	self.HousingButtons.List = Apollo.GetAddon("HousingList")
  	self.HousingButtons.Decorate = Apollo.GetAddon("Housing")
  	self.HousingActionBar = Apollo.GetAddon("ActionBarShortcut")

  	Landscape = self.HousingButtons.Landscape
  	Remodel = self.HousingButtons.Remodel
  	ListWindow = self.HousingButtons.List 
  	Decorate = self.HousingButtons.Decorate

  	SendVarToRover("LAS", self)

  	self:RegisterEvent("SystemKeyDown")
end

function LAS:SystemKeyDown(...)
	-- Handle stuff here
end


function LAS:OnSlashCommand(cmd, argv)
	local args = {}

	local slash = {
	["save"] = function() self:SaveCurrentLAS() end,
	["restore"] = function() self:RestoreCurrentLAS() end,
	["show"] = function() self:ShowShortcutBar() end,
	["hide"] = function() self:HideShortcutBar() end
}

	for a in argv:gmatch("%S+") do
		table.insert(args, a)
	end
	if slash[args[1]] then slash[args[1]]() end
end

-- We want to both hide and disable this floating menu, because we want to have full control of 1-8
-- Also, if you try to call Enable(false) on both the Escape and empty slot, it crashes the client
-- So we set those slots to the previous button and disable them

local HousingBarId = 7
local ourDummyButton = 89 -- Actually the last usable button on the bar, Set Edit Mode
local startOfHousingBar = 83 -- The id before the first used for the housing bar

function LAS:HideShortcutBar()	
	for index, button in ipairs(self.HousingActionBar.tActionBars[HousingBarId]:FindChild("ActionBarContainer"):GetChildren()) do
		local action = button:FindChild("ActionBarShortcutBtn")
		SendVarToRover("action", action, 0)
		if index < 7 then 
			action:Enable(false)
		else			
			action:SetContentId(ourDummyButton)
			action:Enable(false)
		end		
	end
	-- And hide it
	self.HousingActionBar:ShowWindow(HousingBarId, false, 7)
end

-- And then re-enable them before setting them to the appropriate actual slot
function LAS:ShowShortcutBar()
	for index, button in ipairs(self.HousingActionBar.tActionBars[HousingBarId]:FindChild("ActionBarContainer"):GetChildren()) do
		local action = button:FindChild("ActionBarShortcutBtn")		
		if index < 7 then 
			action:Enable(true)
		else
			action:SetContentId(ourDummyButton)
			action:Enable(true)
			action:SetContentId(startOfHousingBar + index)			
		end		
	end
	self.HousingActionBar:ShowWindow(HousingBarId, true, 7)
end

function LAS:SaveCurrentLAS()
	self.CurrentLAS = ActionSetLib.GetCurrentActionSet()
	ActionSetLib.RequestActionSetChanges({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 })
end

function LAS:RestoreCurrentLAS()
	if self.CurrentLAS then
		ActionSetLib.RequestActionSetChanges(self.CurrentLAS)
	end
end