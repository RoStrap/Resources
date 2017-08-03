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

-- Instance Retrievers
local function GetFirstChild(Parent, Name, Class) -- This is what allows the client / server to run the same code :D
	local Object, Bool = Parent:FindFirstChild(Name), false

	if not Object then
		Object = Instance.new(Class, Parent)
		Object.Name = Name
		Bool = true
	end

	return Object, Bool
end

local function Error(Parent, Name, Class)
	return Parent:FindFirstChild(Name) or error(("[Resources] %s \"%s\" is not installed."):format(Class, Name))
end

local Retrieve, LocalResourcesLocation = GetFirstChild

-- Core table
local Resources = {GetFirstChild = GetFirstChild}

-- Placeholder functions
local function GetFolder()
	return GetFirstChild(ResourcesLocation, "Resources", "Folder")
end

local function GetLocalFolder()
	return Retrieve(LocalResourcesLocation, "Resources", "Folder")
end

-- Procedural function generator
local function CreateResourceFunction(self, FullName, Contents, Folder)
	if type(FullName) == "string" then
		local Name = FullName:gsub("^Get", "")
		local Class, Local = (Classes[Name] or Name):gsub("^Local", "")
		local GetFolder, GetFirstChild = GetFolder, GetFirstChild

		-- Decide which is the correct retrieval method (Instance.new, error, or WaitForChild)
		if Local ~= 0 then
			GetFolder, GetFirstChild = GetLocalFolder, Retrieve
		end

		if GetFirstChild == Retrieve then
			local Success, Object = pcall(Instance.new, Class)
			if Success then
				Object:Destroy()
			else
				GetFirstChild = Error
			end
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
				if not Folder then
					Folder = GetFolder(Class:gsub("([bcdfghjklmnpqrstvwxz])y$", "%1ie") .. "s")
				end
				Object, Bool = GetFirstChild(Folder, Name, Class)
				Contents[Name] = Object
			end

			return Object, Bool or false
		end

		self[FullName] = ResourceFunction
		return ResourceFunction
	else
		error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. type(FullName))
	end
end

local Libraries, Repository do -- Assembles table `Libraries`
	if game:GetService("RunService"):IsServer() then
		LocalResourcesLocation = ServerStorage
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder"), CreateResourceFunction(Resources, "GetLocalFolder")
		local LibraryRepository = ModuleRepositoryLocation:FindFirstChild(FolderName) or LocalResourcesLocation:FindFirstChild("Resources") and LocalResourcesLocation.Resources:FindFirstChild("Libraries")
		
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

			ServerModules = CollectionService:GetTagged("ServerLibraries")
			ModuleAmount = #ServerModules

			if ModuleAmount > 0 then
				ServerRepository = GetLocalFolder("Libraries")
				for a = 1, ModuleAmount do
					local Library = ServerModules[a]
					Library.Parent = ServerRepository
					Libraries[Library.Name] = Library
				end
			end

			Miscellaneous = CollectionService:GetTagged("ServerThings")
			ModuleAmount = #Miscellaneous

			if ModuleAmount > 0 then
				ServerStuff = Retrieve(ServerScriptService, "Server", "Folder")
				for a = 1, ModuleAmount do
					Miscellaneous[a].Parent = ServerStuff
				end
			end

			LibraryRepository:Destroy()
		else
			warn(("%s:%d: Unable to locate %s.%s. Please see the configuration at the beginning of this file if this is the wrong location, otherwise LoadLibrary will error"):format(script:GetFullName(), debug.traceback():match("%d+"), ModuleRepositoryLocation.Name, FolderName))
		end
	else
		LocalResourcesLocation = game:GetService("Players").LocalPlayer
		GetFirstChild = game.WaitForChild
		GetFolder, GetLocalFolder = CreateResourceFunction(Resources, "GetFolder"), CreateResourceFunction(Resources, "GetLocalFolder")
	end
end

local LibraryCache = {}
local GetLibrary = CreateResourceFunction(Resources, "GetLibrary", Libraries, Repository)

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
