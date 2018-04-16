-- RoStrap's Core Bootstrapper
-- @author Validark

local Resources = {}
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

local MakeGetterFunction do
	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")

	local ServerSide = RunService:IsServer()
	local ShouldReplicate = ServerSide and not RunService:IsClient()
	local Instance_new, type = Instance.new, type
	local CreateableInstances = {Folder = true; RemoteEvent = true; BindableEvent = true; RemoteFunction = true; BindableFunction = true; Library = false}

	local LocalResourcesLocation, LibraryRepository, GetFolder

	local function GetLocalFolder() -- Temporary GetLocalFolder function; this will get overwritten
		local Folder = LocalResourcesLocation:FindFirstChild("Resources") or Instance_new("Folder", LocalResourcesLocation)
		Folder.Name = "Resources"
		return Folder
	end

	function MakeGetterFunction(self, MethodName, Folder)
		if type(MethodName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2) end

		local IsLocal, InstanceType, FolderGetter, FolderName, Createable, Cache do -- Get Function Constants
			InstanceType, IsLocal = MethodName:gsub("^Get", "", 1)
			if IsLocal == 0 then error("[Resources] Methods should begin with \"Get\"", 2) end -- Make sure methods begin with "Get"

			InstanceType, IsLocal = InstanceType:gsub("^Local", "", 1) -- Remove "Get" and "Local" prefixes from MethodName to isolate InstanceType
			IsLocal = IsLocal == 1
			FolderGetter = IsLocal and GetLocalFolder or GetFolder -- Determine whether Method is Local

			if InstanceType:byte(-1) == 121 then -- if last character is a 'y'
				local Last = InstanceType:byte(-2)
				FolderName = Last ~= 97 and Last ~= 101 and Last ~= 105 and Last ~= 111 and Last ~= 117 and InstanceType:sub(1, -2) .. "ies" or InstanceType .. "s"
			else
				FolderName = InstanceType .. "s" -- Set FolderName to ["RemoteEvent" .. "s"], or ["Librar" .. "ies"]
			end

			Createable = CreateableInstances[InstanceType]
			Cache = Resources:GetLocalTable(IsLocal and "Local" .. FolderName or FolderName)

			if Createable == nil then -- This block will never run for most people
				local GeneratedInstance -- In order to create a new method, the Folder must already be installed with elements, or the instance must be creatable
				Createable, GeneratedInstance = pcall(Instance_new, InstanceType)
				if Createable and GeneratedInstance then
					GeneratedInstance:Destroy()
				elseif not Createable then
					local Warn = true
					local ResourcesLocation = IsLocal and LocalResourcesLocation:FindFirstChild("Resources") or script
					Folder = ResourcesLocation and ResourcesLocation:FindFirstChild(FolderName)

					if Folder then -- Cache instances
						local Children = Folder:GetChildren()
						for i = 1, #Children do
							Warn = false -- Make sure there are instances pre-installed in Folder
							Cache[Children[i].Name] = Children[i]
						end
					end

					if Warn then
						warn("[Resources]", FolderName, ("must be pre-installed inside %s.Resources.%s in order to be fetched by")
							:format(ResourcesLocation:GetFullName():gsub("%.Resources$", "", 1), FolderName), MethodName)
					end
				end
			end
		end

		local function GetFunction(this, InstanceName)
			InstanceName = this ~= self and this or InstanceName
			if type(InstanceName) ~= "string" then error("[Resources] " .. MethodName .. " expected a string parameter, got " .. typeof(InstanceName), 2) end

			if not Folder then
				Folder = FolderGetter(FolderName)
				local Children = Folder:GetChildren() -- Cache children of Folder into Table
				for i = 1, #Children do
					local Child = Children[i]
					Cache[Child.Name] = Child
				end
			end

			local Object = Cache[InstanceName]

			if not Object then
				Object = not IsLocal and not ServerSide	and (Folder:WaitForChild(InstanceName, 5) or warn("[Resources] Make sure to require \"Resources\" on the Server")
					or Folder:WaitForChild(InstanceName)) or Folder:FindFirstChild(InstanceName)

				if not Object then
					if not Createable then error("[Resources] " .. InstanceType .. " \"" .. InstanceName .. "\" is not installed.", 2) end
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

	GetFolder = MakeGetterFunction(Resources, "GetFolder", script)
	GetLocalFolder = MakeGetterFunction(Resources, "GetLocalFolder")

	if not ServerSide then
		repeat LocalResourcesLocation = game:GetService("Players").LocalPlayer until LocalResourcesLocation or not wait()
		repeat until LocalResourcesLocation:FindFirstChildOfClass("PlayerScripts") or not wait()
		LocalResourcesLocation = LocalResourcesLocation:FindFirstChildOfClass("PlayerScripts")
	else
		LocalResourcesLocation = game:GetService("ServerStorage")
		LibraryRepository = LocalResourcesLocation:FindFirstChild("Repository") or game:GetService("ServerScriptService"):FindFirstChild("Repository")
		local Libraries = Resources:GetLocalTable("Libraries")

		for a = 1, 2 do
			local Modules = CollectionService:GetTagged(a == 1 and "ReplicatedLibraries" or "ServerLibraries") -- Assemble `Libraries` table
			local ModuleCount = #Modules
			if ModuleCount > 0 then
				local Repository = ShouldReplicate and (a == 1 and GetFolder or GetLocalFolder)("Libraries")
				for i = 1, ModuleCount do
					local Library = Modules[i]
					if ShouldReplicate then
						Library.Parent = Repository
					end
					Libraries[Library.Name] = Libraries[Library.Name] and (not (a == 2 and CollectionService:HasTag(Libraries[Library.Name], "ReplicatedLibraries")) and
						error("[Resources] Duplicate Libraries named \"" .. Library.Name .. "\". Overshadowing is only permitted when a ServerLibrary overshadows a ReplicatedLibrary", 0) or
						ServerSide and not ShouldReplicate and warn("[Resources] In the absence of a client, the client-version of", Library.Name, "will be inaccessible."))
						or Library
				end
				if a == 1 and Repository then
					MakeGetterFunction(Resources, "GetLibrary", Repository) -- Make it so the Server doesn't parse Resources.Libraries:GetChildren(), which is redundant
				end
			end
		end
	end

	local TagLibraryFolder = script:FindFirstChild("LibraryTags") -- If Resources has a descendant named LibraryTags, each child will be a ModuleScript which handles Tags
	if TagLibraryFolder then
		local TagLibraries = TagLibraryFolder:GetChildren()
		for a = 1, #TagLibraries do
			local TagLibrary = TagLibraries[a]
			local Modules = CollectionService:GetTagged(TagLibrary.Name)
			local ModuleCount = #Modules
			if ModuleCount > 0 then
				local Success, Error = pcall(require(TagLibrary), Modules, ModuleCount, Resources:GetLocalTable("Libraries"))
				if not Success then warn("[Resources] An error occurred while loading", TagLibrary.Name .. ":\n", Error) end
			end
		end
	end

	if ShouldReplicate and LibraryRepository then LibraryRepository = LibraryRepository:Destroy() end
end

local require = require
local LibraryData = Resources:GetLocalTable("LoadedLibraries")

function Resources:LoadLibrary(LibraryName)
	LibraryName = self ~= Resources and self or LibraryName
	local Data = LibraryData[LibraryName]

	if Data == nil then
		Data = require(Resources:GetLibrary(LibraryName))
		LibraryData[LibraryName] = Data
	end

	return Data
end

return setmetatable(Resources, {
	__index = MakeGetterFunction;
	__call = Resources.LoadLibrary;
})
