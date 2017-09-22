-- RoStrap's Core Bootstrapper
-- @readme https://github.com/RoStrap/Resources
-- @author Validark

-- Services
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local FOLDER_NAME = "Repository"
local REPOSITORY_LOCATION = ServerStorage
local ABBREVIATION_TABLE = { -- Allows for abbreviations
	GetEvent = "GetRemoteEvent"; -- Allows you to use Resources:GetEvent() instead of Resources:GetRemoteEvent()
}

-- Assertions
if script.Name ~= "Resources" then error("[Resources] Please change" .. script:GetFullName() .. "'s `Name` to \"Resources\"", 0) end
if script.ClassName ~= "ModuleScript" then error("[Resources] Resources must be a ModuleScript", 0) end
if script.Parent ~= ReplicatedStorage then error("[Resources] Resources must be a child of ReplicatedStorage", 0) end

-- Core variables
local Resources = {}
local LibraryCache = {}

local GetFolder, Libraries, Repository, GetLocalFolder

local FindFirstChild = game.FindFirstChild
local LocalResourcesLocation = ServerStorage

if not game:GetService("RunService"):IsServer() then
	FindFirstChild = game.WaitForChild
	repeat LocalResourcesLocation = game:GetService("Players").LocalPlayer until LocalResourcesLocation or not wait()
end

-- Localized functions
local type = type
local pcall = pcall
local require = require

local gsub = string.gsub
local Generate = Instance.new
local GetChildren = game.GetChildren

-- Procedural function generator
local function CreateResourceFunction(self, FullName, Folder, Createable, Determined)
	if type(FullName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(FullName), 0) end
	local Name = gsub(ABBREVIATION_TABLE[FullName] or FullName, "^Get", "")
	local Class, Local = gsub(Name, "^Local", "")
	local GetFolder, FindFirstChild, Contents = GetFolder, FindFirstChild

	if Local ~= 0 then -- Allow Peer to generate Local Objects
		GetFolder, FindFirstChild = GetLocalFolder, game.FindFirstChild
	end

	local function ResourceFunction(self, Name)
		if self ~= Resources then Name = self end -- Hybrid syntax ('.' or ':')

		if not Contents then
			Folder = Folder or GetFolder(gsub(Class, "([bcdfghjklmnpqrstvwxz])y$", "%1ie") .. "s")
			Contents = GetChildren(Folder)
			for a = 1, #Contents do
				local Child = Contents[a]
				Contents[Child.Name], Contents[a] = Child
			end
		end

		local Object, Bool = Contents[Name]

		if not Object then -- Get Object if it doesn't exist
			Object = FindFirstChild(Folder, Name)
			if not Object then
				Bool = true
				if Createable then
					Object = Generate(Class, Folder)
					Object.Name = Name
				elseif not Determined then
					Createable, Object = pcall(Instance.new, Class, Folder)
					Object.Name = Createable and Name or error(("[Resources] %s \"%s\" is not installed."):format(Class, Name), 0)
					Determined = true
				else
					error(("[Resources] %s \"%s\" is not installed."):format(Class, Name), 0)
				end
			end
			Contents[Name] = Object
		end

		return Object, Bool or false
	end

	self[FullName] = ResourceFunction
	return ResourceFunction
end

-- GetFolder functions are used internally
GetFolder = CreateResourceFunction(Resources, "GetFolder", script, true, true)

function GetLocalFolder(...)
	local LocalResourcesFolder = LocalResourcesLocation:FindFirstChild("Resources") or Instance.new("Folder", LocalResourcesLocation)
	LocalResourcesFolder.Name = "Resources"
	GetLocalFolder = CreateResourceFunction(Resources, "GetLocalFolder", LocalResourcesFolder, true, true)
	return GetLocalFolder(...)
end

local LibraryRepository = REPOSITORY_LOCATION:FindFirstChild(FOLDER_NAME) or LocalResourcesLocation:FindFirstChild("Resources") and FindFirstChild(LocalResourcesLocation.Resources, "Libraries")

if LibraryRepository then
	local ServerRepository, ServerStuff -- Repository folders

	-- Assemble `Libraries` table
	Libraries = CollectionService:GetTagged("ReplicatedLibraries")
	local ModuleAmount = #Libraries

	if ModuleAmount > 0 then
		Repository = GetFolder("Libraries")
		for a = 1, ModuleAmount do
			local Library = Libraries[a]
			Library.Parent = Repository
			Libraries[Library.Name], Libraries[a] = Library
		end
	end

	local Modules = CollectionService:GetTagged("ServerLibraries")
	ModuleAmount = #Modules

	if ModuleAmount > 0 then
		ServerRepository = GetLocalFolder("Libraries")
		for a = 1, ModuleAmount do
			local Library = Modules[a]
			Library.Parent = ServerRepository
			Libraries[Library.Name] = Library
		end
	end

	Modules = CollectionService:GetTagged("ServerStuff")
	ModuleAmount = #Modules

	if ModuleAmount > 0 then
		ServerStuff = FindFirstChild(ServerScriptService, "Server") or Instance.new("Folder", ServerScriptService)
		ServerStuff.Name = "Server"
		for a = 1, ModuleAmount do
			Modules[a].Parent = ServerStuff
		end
	end

	Modules = CollectionService:GetTagged("StarterPlayerScripts")
	ModuleAmount = #Modules

	if ModuleAmount > 0 then
		local StarterPlayerScripts = game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterPlayerScripts")
		local Playerlist = game:GetService("Players"):GetPlayers()
		for a = 1, ModuleAmount do
			Modules[a].Parent = StarterPlayerScripts
		end
		
		-- Make sure that Characters already loaded in receive this
		for a = 1, #Playerlist do
			local PlayerScripts = Playerlist[a]:FindFirstChild("PlayerScripts")
			if PlayerScripts then
				for a = 1, ModuleAmount do
					local Clone = Modules[a]:Clone()
					Clone.Disabled = true
					Clone.Parent = PlayerScripts
					delay(0, function()
						Clone.Disabled = false
					end)
				end
			end
		end
	end

	Modules = CollectionService:GetTagged("StarterCharacterScripts")
	ModuleAmount = #Modules

	if ModuleAmount > 0 then
		local StarterCharacterScripts = game:GetService("StarterPlayer"):FindFirstChildOfClass("StarterCharacterScripts")
		local Playerlist = game:GetService("Players"):GetPlayers()
		for a = 1, ModuleAmount do
			Modules[a].Parent = StarterCharacterScripts
		end
		
		-- Make sure that Characters already loaded in receive this
		for a = 1, #Playerlist do
			local Character = Playerlist[a].Character
			if Character then
				for a = 1, ModuleAmount do					
					local Clone = Modules[a]:Clone()
					Clone.Disabled = true
					Clone.Parent = Character
					delay(0, function()
						Clone.Disabled = false
					end)
				end
			end
		end
	end

	LibraryRepository:Destroy()
end

-- Custom `require` function
function Resources:LoadLibrary(Name)
	Name = self ~= Resources and self or Name
	local Library = LibraryCache[Name]
	if Library == nil then
		if not Libraries then
			Repository = GetFolder("Libraries")
			Libraries = GetChildren(Repository)
			for a = 1, #Libraries do
				local Library = Libraries[a]
				Libraries[Library.Name], Libraries[a] = Library
			end
		end

		Library = Libraries[Name]

		if not Library then
			Library = FindFirstChild(Repository, Name) or error(("[Resources] Library \"%s\" is not installed."):format(Name), 0)
			Libraries[Name] = Library
		end

		Library = require(Library)
		LibraryCache[Name] = Library or false -- caches "nil" as false
	end
	return Library
end

function Resources:LoadTaggedLibraries(Tag)
	local Libraries = CollectionService:GetTagged(self ~= Resources and self or Tag)
	
	for a = 1, #Libraries do
		local Library = Libraries[a]
		local Name = Library.Name
		if LibraryCache[Name] == nil then
			LibraryCache[Name] = require(Library) or false -- caches "nil" as false
		end
	end
end

return setmetatable(Resources, {
	__call = Resources.LoadLibrary;
	__index = CreateResourceFunction;
	__metatable = "[Resources] Metatable is locked";
})
