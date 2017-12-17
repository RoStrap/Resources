-- RoStrap's Core Bootstrapper
-- @readme https://github.com/RoStrap/Resources
-- @author Validark

local Libraries = {}
local Createable = {Folder = true; RemoteEvent = true; BindableEvent = true; RemoteFunction = true; BindableFunction = true}
local ServerSide = game:GetService("RunService"):IsServer()
local LocalResourcesLocation, LibraryRepository, Wrappers

local function Get(_, Name, MethodName, ...)
	if ... then error("[Resources] " .. tostring(select(select("#", ...), ...) or "Functions") .. " should be called with only one parameter", 0) end

	if MethodName == "LoadLibrary" then
		return require(Libraries[Name] or Get(nil, Name, "GetLibrary"))
	else
		local FolderName, Folder, Object
		if MethodName:sub(1, 3) == "Get" then MethodName = MethodName:sub(4) else error("[Resources] Methods should begin with \"Get\"", 0) end

		if MethodName:byte(-1) == 121 then
			local Last = MethodName:byte(-2)
			FolderName = Last ~= 97 and Last ~= 101 and Last ~= 105 and Last ~= 111 and Last ~= 117 and MethodName:sub(1, -2) .. "ies" or MethodName .. "s"
		else
			FolderName = MethodName .. "s"
		end

		if MethodName:sub(1, 5) == "Local" then
			MethodName = MethodName:sub(6)
			Folder = LocalResourcesLocation:FindFirstChild("Resources")

			if not Folder then
				Folder = Instance.new("Folder")
				Folder.Name = "Resources"
				Folder.Parent = LocalResourcesLocation
			end

			if FolderName ~= "LocalFolders" then
				local FolderName = FolderName:sub(6)
				Folder = Folder:FindFirstChild(FolderName) or Instance.new("Folder", Folder)
				Folder.Name = FolderName
			end

			Object = Folder:FindFirstChild(Name)
		else
			Folder = FolderName == "Folders" and script or not ServerSide and script:WaitForChild(FolderName) or script:FindFirstChild(FolderName)

			if not Folder then
				Folder = Instance.new("Folder")
				Folder.Name = FolderName
				Folder.Parent = script
			end
			
			Object = not ServerSide and Folder:WaitForChild(Name) or Folder:FindFirstChild(Name)
		end
		
		if Object then
			return Object, false
		else
			if Createable[MethodName] then
				Object = Instance.new(MethodName) -- Twice as fast as pcall
				Object.Name = Name
				Object.Parent = Folder
			else
				FolderName, Object = pcall(Instance.new, MethodName, Folder)
				if FolderName then
					Object.Name, Createable[MethodName] = Name, true
				else
					error(("[Resources] %s \"%s\" is not installed."):format(MethodName, Name), 0)
				end
			end
			return Object, true
		end
	end
end

if not ServerSide then
	repeat LocalResourcesLocation = game:GetService("Players").LocalPlayer until LocalResourcesLocation or not wait()
else
	LocalResourcesLocation = game:GetService("ServerStorage")
	LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository") or game:GetService("ServerScriptService"):FindFirstChild("Repository")
end

local CollectionService = game:GetService("CollectionService")
for a = 1, 2 do
	local Modules = CollectionService:GetTagged(a == 1 and "ReplicatedLibraries" or "ServerLibraries") -- Assemble `Libraries` table
	local ModuleCount = #Modules
	if ModuleCount > 0 then
		local Repository = Get(nil, "Libraries", a == 1 and "GetFolder" or "GetLocalFolder")
		for a = 1, ModuleCount do
			local Library = Modules[a]
			Library.Parent = Repository
			Libraries[Library.Name] = Library
		end
	end
end

local TagLibraryFolder = script:FindFirstChild("LibraryTags")
if TagLibraryFolder then
	local TagLibraries = TagLibraryFolder:GetChildren()
	for a = 1, #TagLibraries do
		local TagLibrary = TagLibraries[a]
		Modules = CollectionService:GetTagged(TagLibrary.Name)
		ModuleCount = #Modules
		if ModuleCount > 0 then
			local Success, Error = pcall(require(TagLibrary), Modules, ModuleCount, Libraries)
			if not Success then warn("[Resources] An error occurred while loading", TagLibrary.Name .. ":", Error) end
		end
	end
end
if LibraryRepository then LibraryRepository:Destroy() end

local Resources = newproxy(true)
local Metatable = getmetatable(Resources)
Metatable.__namecall = Get
Metatable.__metatable = "The metatable is locked"
function Metatable:__index(MethodName) -- For deprecated syntax support. Please do not use `.` as in `Resources.LoadLibrary`
	if type(MethodName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 0) end
	Wrappers = Wrappers or {}
	local Function = Wrappers[MethodName] or function(...) if select("#", ...) ~= 1 then error("[Resources] " .. MethodName .. " should be called with only one parameter", 0) end return Get(nil, ..., MethodName) end
	Wrappers[MethodName] = Function
	return Function
end

return Resources
