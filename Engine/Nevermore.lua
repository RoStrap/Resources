-- @author Validark
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

-- Configuration
local DEBUG_MODE = false -- Helps identify which modules fail to load
local FolderName = "Modules" -- Name of Module Folder in ServerScriptService
local ResourcesLocation -- Where the "Resources" folder is, it will be generated if needed
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- You can use Nevermore:GetEvent() instead of GetRemoteEvent()
	Function = "RemoteFunction";
}

-- Optimizations
local NewInstance = Instance.new
local gsub = string.gsub
local type, assert, require = type, assert, require
local Destroy, FindFirstChild, GetService, GetChildren, WaitForChild = game.Destroy, game.FindFirstChild, game.GetService, game.GetChildren, game.WaitForChild

-- Services
local RunService = GetService(game, "RunService")
local ServerStorage = GetService(game, "ServerStorage")
local ReplicatedStorage = GetService(game, "ReplicatedStorage")
local ServerScriptService = GetService(game, "ServerScriptService")

-- Assertions
assert(script.Name ~= "ModuleScript", "[Nevermore] Nevermore was never given a name")
assert(script.ClassName == "ModuleScript", "[Nevermore] Nevermore must be a ModuleScript")
assert(script.Parent == ReplicatedStorage, "[Nevermore] Nevermore must be parented to ReplicatedStorage")

-- Helper functions
local function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
	local Object, Bool = FindFirstChild(Parent, Name)

	if not Object then
		Object = NewInstance(Class, Parent)
		Object.Name = Name
		Bool = true
	end

	return Object, Bool
end
local GetFirstChild = Retrieve

-- Module Data
local self = {
	__metatable = "[Nevermore] Nevermore's metatable is locked";
	Retrieve = Retrieve;
	GetFirstChild = Retrieve;
}

local LocalResourcesLocation
if not RunService:IsServer() then
	LocalResourcesLocation = GetService(game, "Players").LocalPlayer
	Retrieve = WaitForChild -- Clients wait for assets to be created by the server
else
	LocalResourcesLocation = ServerStorage
end

-- First-time use only
local function GetFolder() return  Retrieve(ResourcesLocation or ReplicatedStorage, "Resources", "Folder") end
local function GetLocalFolder() return GetFirstChild(LocalResourcesLocation, "Resources", "Folder") end

-- Generation function
local function CreateResourceManager(self, Name) -- Using several strings for the same method (e.g. Event and GetRemoteEvent) is slightly less efficient
	assert(type(Name) == "string", "[Nevermore] Method must be a string")
	local FullName = Name
	Name, Local = gsub(gsub(Name, "^Get", ""), "^Local", "")
	local Retrieve = Retrieve
	local GetFolder = GetFolder

	if Local > 0 then
		Retrieve = GetFirstChild
		GetFolder = GetLocalFolder
	end

	local Class = Classes[Name] or Name
	local Table = {}
	local Folder = GetFolder(Name == "Accessory" and "Accessories" or Class .. "s")
	local function Function(Nevermore, Name, Parent)
		if Nevermore ~= self then -- Enables functions to support calling by '.' or ':'
			Name, Parent = Nevermore, Name
		end
		local Object, Bool = Table[Name]
		if not Object then
			Object, Bool = Retrieve(Parent or Folder, Name, Class)
			if not Parent then
				Table[Name] = Object
			end
		end
		return Object, Bool
	end
	self[FullName] = Function
	return Function
end
self.__index = CreateResourceManager
GetFolder = CreateResourceManager(self, "GetFolder")
GetLocalFolder = CreateResourceManager(self, "GetLocalFolder") -- Generates Local Folder manager

-- Assemble table LibraryCache
local LibraryCache = {} do
	local IsClient = RunService:IsClient()
	local Repository = GetFolder("Modules") -- Grabs Module folder
	local ServerModules = FindFirstChild(ServerScriptService, FolderName or "Nevermore")
	local Descendants = {ServerModules or Repository}
	local Count, NumDescendants, ServerRepository = 0, 1

	if not IsClient then
		ServerRepository = GetLocalFolder("Modules")
	end

	repeat
		Count = Count + 1
		local GrandChildren = GetChildren(Descendants[Count])
		local NumGrandChildren = #GrandChildren
		for a = 1, NumGrandChildren do
			local Descendant = GrandChildren[a]
--			GrandChildren[a] = nil
			local Name = Descendant.Name
			Descendants[NumDescendants + a] = Descendant
			if Descendant.ClassName == "ModuleScript" then
				assert(not LibraryCache[Name], "[Nevermore] Duplicate Module with name \"" .. Name .. "\"")
				LibraryCache[Name] = Descendant
				Descendant.Parent = Name:lower():find("server") and ServerRepository or Repository
			end
		end
		NumDescendants = NumDescendants + NumGrandChildren
	until Count == NumDescendants

	if not IsClient then
		Destroy(ServerModules)
	end
end

-- Custom Require function
function self.GetModule(Nevermore, Name)
	Name = Nevermore ~= self and Nevermore or Name
	return type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(LibraryCache[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
end

if DEBUG_MODE then
	local GetModule = self.GetModule
	local DebugID, RequestDepth = 0, 0

	function self.GetModule(Nevermore, Name)
		Name = Nevermore ~= self and Nevermore or Name
		DebugID = DebugID + 1
		local LocalDebugID = DebugID
		print(string.rep("\t", RequestDepth), LocalDebugID, "Loading:", Name)
		RequestDepth = RequestDepth + 1
		local Library = GetModule(Name)
		RequestDepth = RequestDepth - 1
		print(string.rep("\t", RequestDepth), LocalDebugID, "Done loading:", Name)
		return Library
	end
end

self.__call = self.GetModule
return setmetatable(self, self)
