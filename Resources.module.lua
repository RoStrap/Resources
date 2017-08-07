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
local ResourcesLocation = ReplicatedStorage -- Where the "Resources" folder is, it will be generated if needed
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- Allows you to use Resources:GetEvent() instead of Resources:GetRemoteEvent()
}

-- Assertions
if script.Name ~= "Resources" then error("[Resources] Please change" .. script:GetFullName() .. "'s `Name` to \"Resources\"") end
if script.ClassName ~= "ModuleScript" then error("[Resources] Resources must be a ModuleScript") end
if script.Parent ~= ReplicatedStorage then error("[Resources] Resources must be a child of ReplicatedStorage") end

-- Core variables
local Resources, FindFirstChild, LocalResourcesLocation, GetFolder = {}

-- Placeholder functions
local function GetLocalFolder() local Object = LocalResourcesLocation:FindFirstChild("Resources") or Instance.new("Folder", LocalResourcesLocation) Object.Name = "Resources" return Object end

-- Procedural function generator
local function CreateResourceFunction(self, FullName, Contents, Folder, Createable, Determined)
	if type(FullName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. type(FullName)) end
	local Name = FullName:gsub("^Get", "")
	local Class, Local = (Classes[Name] or Name):gsub("^Local", "")
	local GetFolder, FindFirstChild = GetFolder, FindFirstChild

	if Local ~= 0 then -- Allow Peer to Instantiate Local Objects
		GetFolder, FindFirstChild = GetLocalFolder, game.FindFirstChild
	end
	
	local function ResourceFunction(self, Name)
		if self ~= Resources then Name = self end -- Hybrid syntax ('.' or ':')

		if not Contents then
			Folder = GetFolder(Class:gsub("([bcdfghjklmnpqrstvwxz])y$", "%1ie") .. "s")
			Contents = Folder:GetChildren()
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
					Object = Instance.new(Class, Folder)
					Object.Name = Name
				elseif not Determined then
					Createable, Object = pcall(Instance.new, Class, Folder)
					Object.Name = Createable and Name or error(("[Resources] %s \"%s\" is not installed."):format(Class, Name))
					Determined = true
				else
					error(("[Resources] %s \"%s\" is not installed."):format(Class, Name))
				end
			end
			Contents[Name] = Object
		end

		return Object, Bool or false
	end

	self[FullName] = ResourceFunction
	return ResourceFunction
end

local Libraries, Repository do -- Assembles table `Libraries`
	if game:GetService("RunService"):IsServer() then
		FindFirstChild, LocalResourcesLocation = game.FindFirstChild, ServerStorage
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder", {}, script, true, true), CreateResourceFunction(Resources, "GetLocalFolder")
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

			local ServerModules = CollectionService:GetTagged("ServerLibraries")
			ModuleAmount = #ServerModules

			if ModuleAmount > 0 then
				ServerRepository = GetLocalFolder("Libraries")
				for a = 1, ModuleAmount do
					local Library = ServerModules[a]
					Library.Parent = ServerRepository
					Libraries[Library.Name] = Library
				end
			end

			local Miscellaneous = CollectionService:GetTagged("ServerThings")
			ModuleAmount = #Miscellaneous

			if ModuleAmount > 0 then
				ServerStuff = FindFirstChild(ServerScriptService, "Server") or Instance.new("Folder", ServerScriptService)
				ServerStuff.Name = "Server"
				for a = 1, ModuleAmount do
					Miscellaneous[a].Parent = ServerStuff
				end
			end

			LibraryRepository:Destroy()
		else
			warn(("%s:%d: Unable to locate %s.%s. Please see the configuration at the beginning of this file if this is the wrong location, otherwise LoadLibrary will error"):format(script:GetFullName(), debug.traceback():match("%d+"), ModuleRepositoryLocation.Name, FolderName))
		end
	else
		FindFirstChild, LocalResourcesLocation = game.WaitForChild, game:GetService("Players").LocalPlayer
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder", {}, script, true, true), CreateResourceFunction(Resources, "GetLocalFolder")
	end
end

local LibraryCache = {}
local GetLibrary = CreateResourceFunction(Resources, "GetLibrary", Libraries, Repository, false, true)

function Resources:LoadLibrary(Name) -- Custom `require` function
	Name = self ~= Resources and self or Name
	local Library = LibraryCache[Name]
	if Library == nil then
		Library = require(GetLibrary(Name))
		LibraryCache[Name] = Library or false -- caches "nil" as false
	end
	return Library
end

return setmetatable(Resources, {
	__call = Resources.LoadLibrary;
	__index = CreateResourceFunction;
	__metatable = "[Resources] Metatable is locked";
})
