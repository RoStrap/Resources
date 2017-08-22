-- @author Validark
-- @readme https://github.com/RoStrap/Resources

-- Services
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local FolderName = "Repository"
local ModuleRepositoryLocation = ServerStorage
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- Allows you to use Resources:GetEvent() instead of Resources:GetRemoteEvent()
}

-- Assertions
if script.Name ~= "Resources" then error("[Resources] Please change" .. script:GetFullName() .. "'s `Name` to \"Resources\"", 0) end
if script.ClassName ~= "ModuleScript" then error("[Resources] Resources must be a ModuleScript", 0) end
if script.Parent ~= ReplicatedStorage then error("[Resources] Resources must be a child of ReplicatedStorage", 0) end

-- Core variables
local Resources, LibraryCache, FindFirstChild, LocalResourcesLocation, GetFolder = {}, {}

-- Localized functions
local type = type
local pcall = pcall
local require = require

local gsub = string.gsub
local Instantiate = Instance.new
local GetChildren = game.GetChildren

-- Placeholder functions
local function GetLocalFolder() local Object = LocalResourcesLocation:FindFirstChild("Resources") or Instance.new("Folder", LocalResourcesLocation) Object.Name = "Resources" return Object end

-- Procedural function generator
local function CreateResourceFunction(self, FullName, Folder, Createable, Determined)
	if type(FullName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. type(FullName), 0) end
	local Name = gsub(FullName, "^Get", "")
	local Class, Local = gsub(Classes[Name] or Name, "^Local", "")
	local GetFolder, FindFirstChild, Contents = GetFolder, FindFirstChild

	if Local ~= 0 then -- Allow Peer to Instantiate Local Objects
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
					Object = Instantiate(Class, Folder)
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

-- Assemble `Libraries` table
local Libraries, Repository do
	if game:GetService("RunService"):IsServer() then
		FindFirstChild, LocalResourcesLocation = game.FindFirstChild, ServerStorage
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder", script, true, true), CreateResourceFunction(Resources, "GetLocalFolder", nil, true, true)
		local LibraryRepository = FindFirstChild(ModuleRepositoryLocation, FolderName) or FindFirstChild(LocalResourcesLocation, "Resources") and FindFirstChild(LocalResourcesLocation.Resources, "Libraries")

		if LibraryRepository then
			local ServerRepository, ServerStuff -- Repository folders			
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

			Modules = CollectionService:GetTagged("ServerThings")
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
							Modules[a].Parent = PlayerScripts
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
							Modules[a].Parent = Character
						end
					end
				end
			end

			LibraryRepository:Destroy()
		else
			warn(("%s:%d: Unable to locate %s.%s. Please see the configuration at the beginning of this file if this is the wrong location, otherwise LoadLibrary will error"):format(script:GetFullName(), debug.traceback():match("%d+"), ModuleRepositoryLocation.Name, FolderName))
		end
	else
		FindFirstChild, LocalResourcesLocation = game.WaitForChild, game:GetService("Players").LocalPlayer
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder", script, true, true), CreateResourceFunction(Resources, "GetLocalFolder", nil, true, true)
	end
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
