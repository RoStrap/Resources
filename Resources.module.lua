-- RoStrap's Core Bootstrapper
-- @readme https://github.com/RoStrap/Resources
-- @author Validark

local CollectionService = game:GetService("CollectionService")
local ServerSide = game:GetService("RunService"):IsServer()
local LocalTables = {}
local Libraries = {}
local Createable = {Folder = true; RemoteEvent = true; BindableEvent = true; RemoteFunction = true; BindableFunction = true}
local LocalResourcesLocation, LibraryRepository
local require, Instance_new = require, Instance.new

local function Get(_, Name, MethodName, ...)
	if ... then error("[Resources] " .. tostring(select(select("#", ...), ...) or "Functions") .. " should be called with only one parameter", 2) end
	if MethodName == "LoadLibrary" then return require(Libraries[Name] or Get(nil, Name, "GetLibrary")) end

	local PrefixOccurrences, FolderName, Folder, Object
	MethodName, PrefixOccurrences = MethodName:gsub("^Get", "", 1)
	if PrefixOccurrences ~= 1 then error("[Resources] Methods should begin with \"Get\"", 2) end

	if MethodName:byte(-1) == 121 then -- if last character is a 'y'
		local Last = MethodName:byte(-2)
		FolderName = Last ~= 97 and Last ~= 101 and Last ~= 105 and Last ~= 111 and Last ~= 117 and MethodName:sub(1, -2) .. "ies" or MethodName .. "s"
	else
		FolderName = MethodName .. "s"
	end

	MethodName, PrefixOccurrences = MethodName:gsub("^Local", "", 1)
	if PrefixOccurrences == 1 then
		if MethodName == "Table" then
			local Table = LocalTables[Name]
			if not Table then
				Table = {}
				LocalTables[Name] = Table
			end
			return Table
		end

		Folder = LocalResourcesLocation:FindFirstChild("Resources")

		if not Folder then
			Folder = Instance_new("Folder")
			Folder.Name = "Resources"
			Folder.Parent = LocalResourcesLocation
		end

		if FolderName ~= "LocalFolders" then
			FolderName = FolderName:sub(6)
			Folder = Folder:FindFirstChild(FolderName) or Instance_new("Folder", Folder)
			Folder.Name = FolderName
		end

		Object = Folder:FindFirstChild(Name)
	else
		Folder = FolderName == "Folders" and script or not ServerSide and
			(script:WaitForChild(FolderName, 5) or warn("[Resources] Make sure to require \"Resources\" on the Server") or script:WaitForChild(FolderName, math.huge))
			or script:FindFirstChild(FolderName)

		if not Folder then
			Folder = Instance_new("Folder")
			Folder.Name = FolderName
			Folder.Parent = script
		end

		Object = not ServerSide and Folder:WaitForChild(Name) or Folder:FindFirstChild(Name)
	end

	if Object then
		return Object, false
	end

	if Createable[MethodName] then
		Object = Instance_new(MethodName) -- Twice as fast as pcall
		Object.Name = Name
		Object.Parent = Folder
	else
		local Success
		Success, Object = pcall(Instance_new, MethodName, Folder)
		if not Success then error(("[Resources] %s \"%s\" is not installed."):format(MethodName, Name), 2) end
		Object.Name, Createable[MethodName] = Name, true
	end

	return Object, true
end

if not ServerSide then
	repeat LocalResourcesLocation = game:GetService("Players").LocalPlayer until LocalResourcesLocation or not wait()
else
	LocalResourcesLocation = game:GetService("ServerStorage")
	LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository") or game:GetService("ServerScriptService"):FindFirstChild("Repository")
end

for a = 1, 2 do
	local Modules = CollectionService:GetTagged(a == 1 and "ReplicatedLibraries" or "ServerLibraries") -- Assemble `Libraries` table
	local ModuleCount = #Modules
	if ModuleCount > 0 then
		local Repository = Get(nil, "Libraries", a == 1 and "GetFolder" or "GetLocalFolder")
		for i = 1, ModuleCount do
			local Library = Modules[i]
			Library.Parent = Repository
			Libraries[Library.Name] = Libraries[Library.Name] and not (a == 2 and CollectionService:HasTag(Libraries[Library.Name], "ReplicatedLibraries")) and
				error("[Resources] Duplicate Library names. Overshadowing is only permitted when a ServerLibrary overshadows a ReplicatedLibrary", 0) or Library
		end
	end
end

local TagLibraryFolder = script:FindFirstChild("LibraryTags")
if TagLibraryFolder then
	local TagLibraries = TagLibraryFolder:GetChildren()
	for a = 1, #TagLibraries do
		local TagLibrary = TagLibraries[a]
		local Modules = CollectionService:GetTagged(TagLibrary.Name)
		local ModuleCount = #Modules
		if ModuleCount > 0 then
			local Success, Error = pcall(require(TagLibrary), Modules, ModuleCount, Libraries)
			if not Success then warn("[Resources] An error occurred while loading", TagLibrary.Name .. ":", Error) end
		end
	end
end
if LibraryRepository then LibraryRepository = LibraryRepository:Destroy() end
local Wrappers = {LoadLibrary = function(Name) return require(Libraries[Name] or Get(nil, Name, "GetLibrary")) end}

local Resources = newproxy(true)
local Metatable = getmetatable(Resources)
Metatable.__namecall = Get
Metatable.__metatable = "The metatable is locked"
function Metatable:__index(MethodName) -- For deprecated syntax support. Please do not use `.` except for `Resources.LoadLibrary`
	return Wrappers[MethodName] or
		type(MethodName) == "string" and function(...) if select("#", ...) ~= 1 then error("[Resources] " .. MethodName .. " should be called with only one parameter", 2) end return Get(nil, ..., MethodName) end or
		error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2)
end

return Resources
