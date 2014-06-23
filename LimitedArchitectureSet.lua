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

local timeLimit = 2

function LAS:OnInitialize()
	local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
  	self.glog = GeminiLogging:GetLogger({ level = GeminiLogging.DEBUG, pattern = "%d %n %c %l - %m", appender = "GeminiConsole" })
  	Apollo.RegisterSlashCommand("las", "OnSlashCommand", self)
  	
  	-- Okay, terrible way of overriding stuff
  	self.HousingButtons = {}
  	self.HousingButtons.Landscape = Apollo.GetAddon("HousingLandscape")	
  	self.HousingButtons.Remodel = Apollo.GetAddon("HousingRemodel")
  	self.HousingButtons.List = Apollo.GetAddon("HousingListWindow")
  	self.HousingButtons.Decorate = Apollo.GetAddon("Housing")
  	self.HousingActionBar = Apollo.GetAddon("ActionBarShortcut")

  	Landscape = self.HousingButtons.Landscape
  	Remodel = self.HousingButtons.Remodel
  	ListWindow = self.HousingButtons.List 
  	Decorate = self.HousingButtons.Decorate

  	SendVarToRover("LAS", self)

  	self:RegisterEvent("SystemKeyDown")
  	self:RegisterEvent("WindowKeyDown")

  	self:BlockMenuItems()
end

local lastKeyDown, lastKeyDownAt, stickyEdit


-- We can't actually take over the LAS in a straighforward manner. If the LAS contains actions,
-- then they will fire, if the 1-8 key is hit. If, however, we temporarily clear the LAS, hitting
-- 1-8 will actually activate ctrl-1 to ctrl-8, which is all the housing guff. And we don't 
-- want that either. So, we put buffers into all the commands, to check if we've just hit the 
-- 1-8 keys, and if so, ignore doing the ctrl-1 to ctrl-8 items.

function LAS:BlockMenuItems()
	self:RawHook(Landscape, "OnHousingButtonLandscape")
	self:RawHook(Remodel, "OnHousingButtonRemodel")
	self:RawHook(Decorate, "OnHousingButtonOpenCrate")
	self:RawHook(ListWindow, "OnHousingButtonList")
	self:Hook(HousingLib, "SetEditMode")
	self:RawHook(GameLib, "SupportStuck")
end

function LAS:OnHousingButtonLandscape(...)	
	if lastKeyDown == 49 and os.time() - lastKeyDownAt < timeLimit then return end
	return self.hooks[Landscape].OnHousingButtonLandscape(Landscape, ...)
end

function LAS:OnHousingButtonRemodel(...)
	if lastKeyDown == 50 and os.time() - lastKeyDownAt < timeLimit then return end
	return self.hooks[Remodel].OnHousingButtonRemodel(Remodel, ...)
end

function LAS:OnHousingButtonOpenCrate(...)
	local _, bIsVendor = ...
	if ((not bIsVendor and lastKeyDown == 51) or (bIsVendor and lastKeyDown == 52)) and os.time() - lastKeyDownAt < timeLimit then return end
	return (self.hooks[Decorate]).OnHousingButtonOpenCrate(...)
end

function LAS:OnHousingButtonList()
	if lastKeyDown == 53 and os.time() - lastKeyDownAt < timeLimit then return end
	return self.hooks[ListWindow].OnHousingButtonList(ListWindow)
end

function LAS:SetEditMode(...)	
	stickyEdit = ...
	self.edit = ...
--	if lastKeyDown == 54 and os.time() - lastKeydownAt < timeLimit then return end
--	return self.hooks[HousingLib].SetEditMode(...)
end

function LAS:SupportStuck(...)
	if lastKeyDown == 55 and os.time() - lastKeyDownAt < timeLimit then return end
	return self.hooks[GameLib].SupportStuck(...)
end


function LAS:SystemKeyDown(...)
	local name, strKeyName = ...	
	lastKeyDown = strKeyName
	if tonumber(strKeyName) < 57 and tonumber(strKeyName) > 48 then		
		lastKeyDownAt = os.time()		
	end
	self.glog:debug(strKeyName)

	if strKeyName == 54 then -- sticky Edit key
		HousingLib.SetEditMode(stickyEdit)
	end
end

function LAS:WindowKeyDown(...)
	self.debug(...)
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