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

-- Optimize
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
local Appended, RetrieveObject, Repository = true

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
	function RetrieveObject(Table, Name, Folder, Class) -- This is what allows the client / server to run the same code
		local Object = FindFirstChild(Folder, Name) or NewInstance(Class, Folder)
		Object.Name, Object.Archivable = Name
		Table[Name] = Object
		return Object
	end

	if not RunService:IsStudio() then
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
	function RetrieveObject(Table, Name, Folder) -- This is what allows the client / server to run the same code
		local Object = WaitForChild(Folder, Name)
		Table[Name] = Object
		return Object
	end
end

local function GetFolder() return RetrieveObject(self, "Resources", script, "Folder") end -- First time use only

function self:__index(index) -- Using several strings for the same method (e.g. Event and GetRemoteEvent) is slightly less efficient
	assert(type(index) == "string", "[Nevermore] Method must be a string")
	if not Appended then
		local NevermoreDescendants = GetChildren(script)
		for a = 1, #NevermoreDescendants do
			local Appendage = NevermoreDescendants[a]
			if IsA(Appendage, "ModuleScript") then
				local func = require(Appendage)
				self["Get" .. Appendage.Name] = function(...)
					return func(extract(...))
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
			return Table[Name] or RetrieveObject(Table, Name, Parent or Folder, Class)
		end
		self[originalIndex] = Function
		return Function
	end
end
GetFolder = self:__index("GetFolder")
Repository = GetFolder("Modules") -- Generates Folder manager and grabs Module folder
Appended = not CacheAssemble(ServerModules or Repository) -- Assembles table LibraryCache

self.GetFolder = GetFolder
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
