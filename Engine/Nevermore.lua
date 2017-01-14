-- @author Validark
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

-- Configuration
local DEBUG_MODE = false -- Helps identify which modules fail to load
local FolderName = "Modules" -- Module Folder in ServerScriptService
local ResourcesLocation = script -- Where the "Resources" folder is, or will be created
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- You can use Nevermore:GetEvent() instead of GetRemoteEvent()
	Function = "RemoteFunction";
}

-- Optimizations
local NewInstance = Instance.new
local find, gsub, lower = string.find, string.gsub, string.lower
local type, error, assert, select, require = type, error, assert, select, require
local Destroy, FindFirstChild, GetService, GetChildren, WaitForChild = game.Destroy, game.FindFirstChild, game.GetService, game.GetChildren, game.WaitForChild

-- Services
local RunService = GetService(game, "RunService")
local ReplicatedStorage = GetService(game, "ReplicatedStorage")
local ServerScriptService = GetService(game, "ServerScriptService")

-- Module Data
local self = {__metatable = "[Nevermore] Nevermore's metatable is locked"}
local IsClient = RunService:IsClient()
local LibraryCache = {}
local ServerModules = FindFirstChild(ServerScriptService, FolderName) or FindFirstChild(ServerScriptService, "Nevermore")

-- Assertions
assert(script.Name ~= "ModuleScript", "[Nevermore] Nevermore was never given a name")
assert(script.ClassName == "ModuleScript", "[Nevermore] Nevermore must be a ModuleScript")
assert(script.Parent == ReplicatedStorage, "[Nevermore] Nevermore must be parented to ReplicatedStorage")

-- Helper functions
local function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
	local Object = FindFirstChild(Parent, Name)
	if not Object then
		Object = NewInstance(Class, Parent)
		Object.Name, Object.Archivable = Name
	end
	return Object
end
self.Retrieve = Retrieve -- Give the retrieve function to clients

if not RunService:IsServer() then
	Retrieve = WaitForChild -- Clients wait for assets to be created by the server
end

local function GetFolder() -- First time use only
	local Resources = Retrieve(ResourcesLocation, "Resources", "Folder")
	self.Resources = Resources
	return Resources
end

-- Generation function
local function GetResourceManager(self, index) -- Using several strings for the same method (e.g. Event and GetRemoteEvent) is slightly less efficient
	assert(type(index) == "string", "[Nevermore] Method must be a string")
	local originalIndex = index
	index = gsub(index, "^Get", "")
	local Class = Classes[index] or index
	local Table = {}
	local Folder = GetFolder(Class .. "s")
	local function Function(Nevermore, Name, Parent)
		if Nevermore ~= self then -- Enables functions to support calling by '.' or ':'
			Name, Parent = Nevermore, Name
		end
		local Object = Table[Name]
		if not Object then
			Object = Retrieve(Parent or Folder, Name, Class)
			Table[Name] = Object
		end
		return Object
	end
	self[originalIndex] = Function
	return Function
end
self.__index = GetResourceManager
GetFolder = GetResourceManager(self, "GetFolder")
local Repository = GetFolder("Modules") -- Generates Folder manager and grabs Module folder

-- Assemble table LibraryCache
local Descendants = {ServerModules or Repository}
local Count, NumDescendants = 0, 1
repeat
	Count = Count + 1
	local GrandChildren = GetChildren(Descendants[Count])
	local NumGrandChildren = #GrandChildren
	for a = 1, NumGrandChildren do
		local Descendant = GrandChildren[a]
		local Name = Descendant.Name
		Descendants[NumDescendants + a] = Descendant

		if Descendant.ClassName == "ModuleScript" then
			assert(not LibraryCache[Name], "[Nevermore] Duplicate Module with name \"" .. Name .. "\"")
			LibraryCache[Name] = Descendant
			if not IsClient then
				Descendant.Parent = find(lower(Name), "server") and ServerModules or Repository
			end-- TODO: Destroy non-scripts on server, but the loop needs to be adjusted to iterate over the furthest descendants first
		end
	end
	NumDescendants = NumDescendants + NumGrandChildren
until Count == NumDescendants

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
