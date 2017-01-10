-- @author Narrev
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

-- Configuration
local DEBUG_MODE = false -- Helps identify which modules fail to load
local FolderName = "Modules" -- Module Folder in ServerScriptService
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent";
	Function = "RemoteFunction";
}

-- Optimizations
local NewInstance = Instance.new
local type, error, assert, select, require = type, error, assert, select, require
local find, gsub, lower = string.find, string.gsub, string.lower
local IsA, Destroy, GetService, GetChildren, WaitForChild, FindFirstChild = game.IsA, game.Destroy, game.GetService, game.GetChildren, game.WaitForChild, game.FindFirstChild

-- Services
local RunService = GetService(game, "RunService")
local ReplicatedStorage = GetService(game, "ReplicatedStorage")
local ServerScriptService = GetService(game, "ServerScriptService")

-- Module Data
local self = {__metatable = "[Nevermore] Nevermore's metatable is locked"}
local LibraryCache = {}
local ServerModules = FindFirstChild(ServerScriptService, FolderName) or FindFirstChild(ServerScriptService, "Nevermore")
local Retrieve, Repository

local IsClient = RunService:IsClient()

assert(IsA(script, "ModuleScript"), "[Nevermore] Nevermore must be a ModuleScript")
assert(script.Name ~= "ModuleScript", "[Nevermore] Nevermore was never given a name")
assert(script.Parent == ReplicatedStorage, "[Nevermore] Nevermore must be parented to ReplicatedStorage")

function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
	local Object = FindFirstChild(Parent, Name)
	if not Object then
		Object = NewInstance(Class, Parent)
		Object.Name, Object.Archivable = Name
	end
	return Object
end
self.Retrieve = Retrieve

if not RunService:IsServer() then
	Retrieve = WaitForChild
end

local function GetFolder() -- First time use only
	local Resources = Retrieve(script, "Resources", "Folder")
	self.Resources = Resources
	return Resources
end

function self:__index(index) -- Using several strings for the same method (e.g. Event and GetRemoteEvent) is slightly less efficient
	assert(type(index) == "string", "[Nevermore] Method must be a string")
	local originalIndex = index
	local index = gsub(index, "^Get", "")
	local Class = Classes[index] or index
	local Table = {}
	local Folder = GetFolder(Class .. "s")
	local function Function(...)
		local Name, Parent

		if ... == self then -- Enables functions to support calling by '.' or ':'
			Name, Parent = select(2, ...)
		else
			Name, Parent = ...
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
GetFolder = self:__index("GetFolder")
Repository = GetFolder("Modules") -- Generates Folder manager and grabs Module folder

-- Assemble table LibraryCache
local Descendants, Count, NumDescendants = {ServerModules or Repository}, 0, 1
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

function self.GetModule(...)
	local Name = ... == self and select(2, ...) or ...
	return type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(LibraryCache[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
end

if DEBUG_MODE then
	local GetModule = self.GetModule
	local DebugID, RequestDepth = 0, 0

	function self.GetModule(...)
		local Name = ... == self and select(2, ...) or ...
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
