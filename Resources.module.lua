-- The core resource manager and library loader for RoStrap designed to streamline the retrieval and networking of resources
-- @author Validark

local Metatable = {}
local Resources = setmetatable({}, Metatable)
local Caches = {} -- All cached data within Resources is accessible through Resources:GetLocalTable()

function Resources:GetLocalTable(TableName) -- Returns a cached table by TableName, generating if non-existant
	TableName = self ~= Resources and self or TableName
	local Table = Caches[TableName]

	if not Table then
		Table = {}
		Caches[TableName] = Table
	end

	return Table
end

local RunService = game:GetService("RunService")
local ServerSide = RunService:IsServer()
local Instance_new, type, require = Instance.new, type, require
local InstantiableInstances = {
	Folder = true; RemoteEvent = true; BindableEvent = true;
	RemoteFunction = true; BindableFunction = true; Library = false;
}
local LocalResourcesLocation

local function GetRootFolder()
	return script
end

local function GetLocalRootFolder()
	local Folder = LocalResourcesLocation:FindFirstChild("Resources") or Instance_new("Folder")
	Folder.Name = "Resources"
	Folder.Parent = LocalResourcesLocation
	return Folder
end

function Metatable:__index(MethodName, Folder)
	if type(MethodName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2) end

	local IsLocal, InstanceType, FolderGetter, FolderName, Instantiable, CacheName, Cache do -- Get Function Constants
		InstanceType, IsLocal = MethodName:gsub("^Get", "", 1)
		if IsLocal == 0 then error("[Resources] Methods should begin with \"Get\"", 2) end -- Make sure methods begin with "Get"

		InstanceType, IsLocal = InstanceType:gsub("^Local", "", 1) -- Remove "Get" and "Local" prefixes from MethodName to isolate InstanceType
		IsLocal = IsLocal == 1
		FolderGetter = InstanceType == "Folder" and (IsLocal and GetLocalRootFolder or GetRootFolder) or IsLocal and Resources.GetLocalFolder or Resources.GetFolder -- Determine whether Method is Local

		if InstanceType:byte(-1) == 121 then -- if last character is a 'y'
			local Last = InstanceType:byte(-2)
			FolderName = Last ~= 97 and Last ~= 101 and Last ~= 105 and Last ~= 111 and Last ~= 117 and InstanceType:sub(1, -2) .. "ies" or InstanceType .. "s"
		else
			FolderName = InstanceType .. "s" -- Set FolderName to ["RemoteEvent" .. "s"], or ["Librar" .. "ies"]
		end

		Instantiable = InstantiableInstances[InstanceType]
		CacheName = IsLocal and "Local" .. FolderName or FolderName
		if Folder then
			Cache = Caches[CacheName]
		elseif Instantiable == nil then -- This block will never run for most people
			local GeneratedInstance
			Instantiable, GeneratedInstance = pcall(Instance_new, InstanceType)
			if Instantiable and GeneratedInstance then GeneratedInstance:Destroy() end
		end
	end

	local function GetFunction(this, InstanceName)
		InstanceName = this ~= self and this or InstanceName
		if type(InstanceName) ~= "string" then error("[Resources] " .. MethodName .. " expected a string parameter, got " .. typeof(InstanceName), 2) end

		if not Folder then
			Cache = Caches[CacheName]
			Folder = FolderGetter(FolderName)
			local Children = Folder:GetChildren() -- Cache children of Folder into Table

			if not Cache then
				Cache = Children -- Recycling is good!
				Caches[CacheName] = Children
			end

			for i = 1, #Children do
				local Child = Children[i]
				Cache[Child.Name] = Child
				Children[i] = nil
			end
		end

		local Object = Cache[InstanceName]

		if not Object then
			Object = not IsLocal and not ServerSide	and (Folder:WaitForChild(InstanceName, 5)
				or warn("[Resources] Make sure to require \"Resources\" on the Server. Perhaps require this (if applicable): ", (debug.traceback():reverse():match("%d+ eniL ,(%b'')") or ""):reverse())
				or Folder:WaitForChild(InstanceName)) or Folder:FindFirstChild(InstanceName)

			if not Object then
				if not Instantiable then error("[Resources] " .. InstanceType .. " \"" .. InstanceName .. "\" is not installed within " .. Folder:GetFullName() .. ".", 2) end
				Object = Instance_new(InstanceType)
				Object.Name = InstanceName
				Object.Parent = Folder
			end

			Cache[InstanceName] = Object
		end

		return Object
	end

	Resources[MethodName] = GetFunction
	return GetFunction
end

if not ServerSide then
	local LocalPlayer repeat LocalPlayer = game:GetService("Players").LocalPlayer until LocalPlayer or not wait()
	repeat LocalResourcesLocation = LocalPlayer:FindFirstChildOfClass("PlayerScripts") until LocalResourcesLocation or not wait()
else
	LocalResourcesLocation = game:GetService("ServerStorage")
	local LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository") or game:GetService("ServerScriptService"):FindFirstChild("Repository")

	local function CacheLibrary(Storage, Library)
		if Storage[Library.Name] then
			error("[Resources] Duplicate Libraries Found:\n\t" .. Storage[Library.Name]:GetFullName() .. "\n\t" .. Library:GetFullName() .. "\nOvershadowing is only permitted when a server-only library overshadows a replicated library", 0)
		else
			Storage[Library.Name] = Library
		end
	end

	if LibraryRepository then
		-- If Folder `Repository` exists, move all Libraries over to ReplicatedStorage
		-- unless if they have "Server" in their name or in the name of a parent folder

		local ShouldReplicate = ServerSide and not RunService:IsClient()
		local ReplicatedLibraries = Resources:GetLocalTable("Libraries")
		local Descendants = LibraryRepository:GetDescendants()
		local i, NumDescendants = 0, #Descendants
		local ServerLibraries = {}

		while i < NumDescendants do
			i = i + 1
			local Object = Descendants[i]

			if Object.ClassName == "ModuleScript" then
				while i < NumDescendants and Descendants[i + 1]:IsDescendantOf(Object) do i = i + 1 end

				if ShouldReplicate then
					Object.Parent = Object.Name:find("Server", 1, true) and Resources:GetLocalFolder("Libraries") or Resources:GetFolder("Libraries")
				end

				CacheLibrary(ReplicatedLibraries, Object)
			elseif Object.ClassName == "Folder" then
				if Object.Name:find("Server", 1, true) then
					local Descendant = Descendants[i + 1]

					while i < NumDescendants and Descendant:IsDescendantOf(Object) do
						if Descendant.ClassName == "ModuleScript" then
							while i < NumDescendants and Descendants[i + 1]:IsDescendantOf(Descendant) do
								i = i + 1
							end

							if ShouldReplicate then
								Descendant.Parent = Resources:GetLocalFolder("Libraries")
							elseif ReplicatedLibraries[Descendant.Name] then
								warn("[Resources] In the absence of a client, the client-version of", Descendant.Name, "will be inaccessible.")
							end

							CacheLibrary(ServerLibraries, Descendant)
						elseif Descendant.ClassName ~= "Folder" then
							error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. Descendant.ClassName .. " " .. Descendant:GetFullName(), 0)
						end
						i = i + 1
						Descendant = Descendants[i + 1]
					end
				end
			else
				error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. Object.ClassName .. " " .. Object:GetFullName(), 0)
			end
		end

		for Name, Library in next, ServerLibraries do
			ReplicatedLibraries[Name] = Library
		end

		Metatable.__index(Resources, "GetLibrary", Resources:GetFolder("Libraries")) -- We do this so it doesn't cache things returned by a GetChildren (and overwrite server-only libraries)

		if ShouldReplicate then
			LibraryRepository:Destroy()
		end
	end
end

local LoadedLibraries = Resources:GetLocalTable("LoadedLibraries")

function Resources:LoadLibrary(LibraryName)
	LibraryName = self ~= Resources and self or LibraryName
	local Data = LoadedLibraries[LibraryName]

	if Data == nil then
		Data = require(Resources:GetLibrary(LibraryName))
		LoadedLibraries[LibraryName] = Data
	end

	return Data
end

Metatable.__call = Resources.LoadLibrary
return Resources
