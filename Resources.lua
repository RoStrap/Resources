-- The core resource manager and library loader for RoStrap. It is designed to increase organization and streamline the retrieval and networking of resources.
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

		if InstanceType:byte(-1) == 121 then -- if last character is a 'y', this is a simple gimmick but works well enough for me :D
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
			Object = not IsLocal and not ServerSide	and (
					Folder:WaitForChild(InstanceName, 5)
					or warn("[Resources] Make sure to require \"Resources\" on the Server. Perhaps require this (if applicable): ", (debug.traceback():reverse():match("%d+ eniL ,(%b'')") or ""):reverse())
					or Folder:WaitForChild(InstanceName)
				) or Folder:FindFirstChild(InstanceName)

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

	local function CacheLibrary(Storage, Library, StorageName)
		if Storage[Library.Name] then
			error("[Resources] Duplicate " .. StorageName .. " Found:\n\t"
				.. Storage[Library.Name]:GetFullName() .. " and \n\t"
				.. Library:GetFullName()
				.. "\nOvershadowing is only permitted when a server-only library overshadows a replicated library"
			, 0)
		else
			Storage[Library.Name] = Library
		end
	end

	if LibraryRepository then
		-- If Folder `Repository` exists, move all Libraries over to ReplicatedStorage
		-- unless if they have "Server" in their name or in the name of a parent folder

		local ShouldReplicate = ServerSide and not RunService:IsClient()
		local ServerLibraries = {}
		local ReplicatedLibraries = Resources:GetLocalTable("Libraries")

		local function HandleFolderChildren(FolderChildren, ServerOnly)
			for i = 1, #FolderChildren do
				local Child = FolderChildren[i]
				local ClassName = Child.ClassName
				ServerOnly = ServerOnly or Child.Name:find("Server", 1, true) and true or false

				if ClassName == "ModuleScript" then
					if ServerOnly then
						if ShouldReplicate then
							Child.Parent = Resources:GetLocalFolder("Libraries")
						end

						CacheLibrary(ServerLibraries, Child, "ServerLibraries")
					else
						if ShouldReplicate then
							-- ModuleScripts which are not descendants of ServerOnly folders and do not have "Server" in name should be moved to Libraries
							--	if there are descendants of the ModuleScript with "Server" in the name, we should copy the original for use on the server
							--	and replicate a version with everything with "Server" in the name deleted

							local ModuleDescendants = Child:GetDescendants()
							local TemplateObject

							-- Iterate through the ModuleScript's Descendants, deleting those with "Server" in the Name

							for j = 1, #ModuleDescendants do
								local Descendant = ModuleDescendants[j]

								if Descendant.Name:find("Server", 1, true) then
									if not TemplateObject then -- Before the first deletion, clone Child
										TemplateObject = Child:Clone()
									end

									Descendant:Destroy()
								end
							end

							if TemplateObject then -- If we want to replicate an object with Server descendants, move the server-version to LocalLibraries
								TemplateObject.Parent = Resources:GetLocalFolder("Libraries")
								CacheLibrary(ServerLibraries, TemplateObject, "ServerLibraries")
							end

							Child.Parent = Resources:GetFolder("Libraries") -- Replicate Child which may have had things deleted
						end

						CacheLibrary(ReplicatedLibraries, Child, "ReplicatedLibraries")
					end
				elseif ClassName == "Folder" then
					HandleFolderChildren(Child:GetChildren(), ServerOnly)
				else
					error("[Resources] Instances within your Repository must be either a ModuleScript or a Folder, found: " .. ClassName .. " " .. Child:GetFullName(), 0)
				end
			end
		end

		HandleFolderChildren(LibraryRepository:GetChildren(), false)

		for Name, Library in next, ServerLibraries do
			if ReplicatedLibraries[Name] then
				warn("[Resources] In the absence of a client, the client-version of", Name, "will be inaccessible")
			end
			ReplicatedLibraries[Name] = Library
		end

		Metatable.__index(Resources, "GetLibrary", Resources:GetFolder("Libraries")) -- We do this so it doesn't cache things returned by a GetChildren (and overwrite server-only libraries)

		if ShouldReplicate then
			LibraryRepository:Destroy()
		end
	end
end

local LoadedLibraries = Resources:GetLocalTable("LoadedLibraries")
local CurrentlyLoading = {} -- This is a hash which functions as a kind of linked-list history of [Script who Loaded] -> LibraryName

function Resources:LoadLibrary(LibraryName)
	LibraryName = self ~= Resources and self or LibraryName
	local Data = LoadedLibraries[LibraryName]

	if Data == nil then
		local CallerName = getfenv(2).script
		CallerName = CallerName and CallerName.Name or {} -- If called from command bar, use table as a reference (never concatenated)

		CurrentlyLoading[CallerName] = LibraryName

		-- Check to see if this case occurs:
		-- LibraryName -> Stuff1 -> Stuff2 -> LibraryName

		-- WHERE CurrentlyLoading[LibraryName] is Stuff1
		-- and CurrentlyLoading[Stuff1] is Stuff2
		-- and CurrentlyLoading[Stuff2] is LibraryName

		local Current = LibraryName
		local Count = 0

		while Current do
			Count = Count + 1
			Current = CurrentlyLoading[Current]

			if Current == LibraryName then
				local String = Current -- Get the string traceback

				for _ = 1, Count do
					Current = CurrentlyLoading[Current]
					String = String .. " -> " .. Current
				end

				error("[Resources] Circular dependency chain detected: " .. String)
			end
		end

		Data = require(Resources:GetLibrary(LibraryName)) or false

		if CurrentlyLoading[CallerName] == LibraryName then -- Thread-safe cleanup!
			CurrentlyLoading[CallerName] = nil
		end

		LoadedLibraries[LibraryName] = Data
	end

	return Data
end

Metatable.__call = Resources.LoadLibrary
return Resources
