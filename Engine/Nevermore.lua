-- @author Narrev
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

-- Configuration
local DEBUG_MODE = false -- Helps identify which modules fail to load
local FolderName = "Modules"
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
local Appended, Retrieve, Repository = true

assert(IsA(script, "ModuleScript"), "[Nevermore] Nevermore must be a ModuleScript")
assert(script.Name ~= "ModuleScript", "[Nevermore] Nevermore was never given a name")
assert(script.Parent == ReplicatedStorage, "[Nevermore] Nevermore must be parented to ReplicatedStorage")

local function extract(...) -- Enables functions to support calling by '.' or ':'
	if ... == self then
		return select(2, ...)
	else
		return ...
	end
end

local function Cache(Object, Name)
	if IsA(Object, "ModuleScript") then
		assert(not LibraryCache[Name], "[Nevermore] Duplicate Module with name \"" .. Name .. "\"")
		LibraryCache[Name] = Object
		return true
	end
end

local function CacheAssemble(Object)
	local Children = GetChildren(Object)
	for a = 1, #Children do
		local Object = Children[a]
		local Name = Object.Name
		Cache(CacheAssemble(Object), Name) -- Caches objects that lack descendants first
	end
	return Object
end

if RunService:IsServer() then
	function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
		local Object = FindFirstChild(Parent, Name)
		if not Object then
			Object = NewInstance(Class, Parent)
			Object.Name, Object.Archivable = Name
		end
		return Object
	end

	if not RunService:IsClient() then
		local CacheModule = Cache
		function Cache(Object, Name)
			if CacheModule(Object, Name) then
				Object.Parent = find(lower(Name), "server") and ServerModules or Repository
			elseif not IsA(Object, "Script") then
				Destroy(Object)
			end
		end
	end
else
	Retrieve = WaitForChild
end

local function GetFolder() -- First time use only
	local Resources = Retrieve(script, "Resources", "Folder")
	self.Resources, self.Retrieve = Resources, Retrieve
	return Resources
end

function self:__index(index) -- Using several strings for the same method (e.g. Event and GetRemoteEvent) is slightly less efficient
	assert(type(index) == "string", "[Nevermore] Method must be a string")
	if not Appended then
		local NevermoreDescendants = GetChildren(script)
		for a = 1, #NevermoreDescendants do
			local Appendage = NevermoreDescendants[a]
			if IsA(Appendage, "ModuleScript") then
				local functions = require(Appendage)
				for index, func in next, functions do
					self[index] = function(...)
						return func(extract(...))
					end
				end
			end
		end
		Appended = true
		return self[index]
	else
		local originalIndex = index
		local index = gsub(index, "^Get", "")
		local Class = Classes[index] or index
		local Table = {}
		local Folder = GetFolder(Class .. "s")
		local function Function(...)
			local Name, Parent = extract(...)
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
end
GetFolder = self:__index("GetFolder")
Repository = GetFolder("Modules") -- Generates Folder manager and grabs Module folder
Appended = not CacheAssemble(ServerModules or Repository) -- Assembles table LibraryCache

function self.GetModule(...)
	local Name = extract(...)
	return type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(LibraryCache[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
end

if DEBUG_MODE then
	local GetModule = self.GetModule
	local DebugID, RequestDepth = 0, 0

	function self.GetModule(...)
		local Name = extract(...)
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
