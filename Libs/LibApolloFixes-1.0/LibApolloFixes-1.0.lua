local MAJOR, MINOR = "Lib:ApolloFixes-1.0", 1
-- Get a reference to the package information if any
local APkg = Apollo.GetPackage(MAJOR)
-- If there was an older version loaded we need to see if this is newer
if APkg and (APkg.nVersion > 0) then
	return -- no upgrades
end
-- Set a reference to the actual package or create an empty table
Lib = APkg and APkg.tPackage or {}

-------------------------------------------------------------------------------
--- Local Variables
-------------------------------------------------------------------------------

local tAddonList = {}
-- Read-Only proxy table for returning to requestors
local tAddonRO = setmetatable({}, { __index = tAddonList, __newindex = function(t,k,v) return end })

Lib.fnOldLoadForm = Lib.fnOldLoadForm or Apollo.LoadForm
Lib.tSubbedAddons = Lib.tSubbedAddons or {
	["ImprovedSalvageForm"] = "ImprovedSalvage",
	["ItemPreviewForm"] = "ItemPreview",
	["TradeskillContainerForm"] = "TradeskillContainer",
	["TradeskillSchematicsForm"] = "TradeskillSchematics",
	["TradeskillTalentsForm"] = "TradeskillTalents",
	["WarpartyRegistrationForm"] = "WarpartyRegister",
	["WarpartyBattleForm"] = "WarpartyBattle",
	["TutorialTesterForm"] = "TutorialPrompts",
	["PathSoldierMissionMain"] = "PathSoldierMissions",
	["PathSettlerrMissionMain"] = "PathSettlerMissions",
	["PathScientistExperimentationForm"] = "PathScientistExperimentation",
	["PathScientistCustomizeForm"] = "PathScientistCustomize",
	["PowerMapRangeFinder"] = "PathExplorerMissions",
	["InteractionOnUnit"] = "HUDInteract",
	["HousingRemodelWindow"] = "HousingRemodel",
	["HousingLandscapeWindow"] = "HousingLandscape",
	["HousingListWindow"] = "HousingListWindow",
	["DecorPreviewWindow"] = "DecorPreview",
	["PlugPreviewWindow"] = "PlugPreview",
	["MannequinWindow"] = "Mannequin",
	["HousingDatachronWindow"] = "HousingDatachron",
	["CircleRegistrationForm"] = "CircleRegistration",
	["GroupLeaderOptions"] = "GroupDisplayOptions",
	["FloaterPanel"] = "FloatTextPanel",
	["ChallengeLogForm"] = "ChallengeLog",
	["ChallengeRewardPanelForm"] = "ChallengeRewardPanel",
	["ArenaTeamRegistrationForm"] = "ArenaTeamRegister",
}

Lib.fnOldGetAddon = Lib.fnOldGetAddon or Apollo.GetAddon
Lib.tFoundAddons = Lib.tFoundAddons or {}
-------------------------------------------------------------------------------
--- Local Functions
-------------------------------------------------------------------------------

local function GetAddons()
	if #tAddonList > 0 then
		return tAddonRO -- Return a read-only version
	end
	local strDirPrev = string.match(Apollo.GetAssetFolder(), "(.-)[\\/][Aa][Dd][Dd][Oo][Nn][Ss]")
	local tAddonXML = XmlDoc.CreateFromFile(strDirPrev.."\\Addons.xml"):ToTable()
	for k,v in pairs(tAddonXML) do
		if v.__XmlNode == "Addon" then
			if v.Carbine == 1 then
				table.insert(tAddonList, v.Folder)
			else
				local tSubToc = XmlDoc.CreateFromFile(strDirPrev.."\\Addons\\"..v.Folder.."\\toc.xml")
				if tSubToc then
					local tTocTable = tSubToc:ToTable()
					table.insert(tAddonList, tSubToc.Name)
				end
			end
		end
	end
	return tAddonRO -- Return a read-only version
end

local function GetAddon(strAddonName)
	if Lib.tFoundAddons[strAddonName] then
		return Lib.tFoundAddons[strAddonName]
	else
		return Lib.fnOldGetAddon(strAddonName)
	end
end

local function debugLocals(nLevel)
	local tVars, nIdx = {}, 1
	while true do
		local ln, lv = debug.getlocal(nLevel, nIdx)
		if ln ~= nil then
			tVars[ln] = lv
		else
			break
		end
		nIdx = nIdx + 1
	end
	return tVars
end

local function HookedLoadForm(...)
	local strForm = select(2, ...)
	if Lib.tSubbedAddons[strForm] then
		local tDebugLocals = debugLocals(3)
		Lib.tFoundAddons[Lib.tSubbedAddons[strForm]] = tDebugLocals.self
		Lib.tSubbedAddons[strForm] = nil

		if not next(Lib.tSubbedAddons) then
			Apollo.LoadForm = Lib.fnOldLoadForm
		end
	end
	return Lib.fnOldLoadForm(...)
end
Apollo.LoadForm = HookedLoadForm

function Lib:OnLoad()
	Apollo.GetAddons = GetAddons
	Apollo.GetAddon = GetAddon
end

Apollo.RegisterPackage(Lib, MAJOR, MINOR, {})