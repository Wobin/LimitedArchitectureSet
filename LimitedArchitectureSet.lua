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

function LAS:OnInitialize()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
  	self.glog = GeminiLogging:GetLogger({ level = GeminiLogging.DEBUG, pattern = "%d %n %c %l - %m", appender = "GeminiConsole" })
  	Apollo.RegisterSlashCommand("las", "OnSlashCommand", self)
  	
  	-- Okay, terrible way of overriding stuff
  	self.HousingButtons = {}
  	self.HousingButtons.Landscape = Apollo.GetAddon("HousingLandscape")	
  	self.HousingButtons.Remodel = Apollo.GetAddon("HousingRemodel")
  	self.HousingButtons.Crate = Apollo.GetAddon("HousingListWindow")
  	self.HousingButtons.Decorate = Apollo.GetAddon("Housing")
  	self.HousingButtons.List = Apollo.GetAddon("HousingListWindow")


  	SendVarToRover("LAS", self)

  	self:RegisterEvent("SystemKeyDown")

  	self:BlockMenuItems()
end

local lastKeyDown, lastKeyDownAt


function LAS:BlockMenuItems()
	self:RawHook(self.HousingButtons.Landscape, "OnHousingButtonLandscape")
end

function LAS:OnHousingButtonLandscape(...)
	if lastKeyDown == 49 and os.time() - lastKeyDownAt < 1 then return end
	self.hooks[self.HousingButtons.Landscape].OnHousingButtonLandscape(...)
end



function LAS:SystemKeyDown(...)
	local name, strKeyName = ...
	self.glog:debug(strKeyName)
	if tonumber(strKeyName) < 57 and tonumber(strKeyName) > 48 then
		lastKeyDown = strKeyName
		lastKeyDownAt = os.time()
	end
end



function LAS:OnSlashCommand(cmd, argv)
	local args = {}
	for a in argv:gmatch("%S+") do
		table.insert(args, a)
	end
	if args[1] == "save" then
		return self:SaveCurrentLAS()
	end
	if args[1] == "restore" then
		return self:RestoreCurrentLAS()
	end
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