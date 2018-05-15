This is an in-dev plugin version:
```lua
-- Plugin version of Resources
-- @author Validark

-- The plugin version will cache ALL ModuleScripts under TOP_OBJECT, even if they are within another ModuleScript
local TOP_OBJECT = script.Parent.Parent

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
	local Instance_new, type = Instance.new, type
	local InstantiableInstances = {Folder = true; RemoteEvent = true; BindableEvent = true; RemoteFunction = true; BindableFunction = true; Library = false}

	local function GetRootFolder()
		return script
	end

	function MakeGetterFunction(self, MethodName, Folder)
		if type(MethodName) ~= "string" then error("[Resources] Attempt to index Resources with invalid key: string expected, got " .. typeof(MethodName), 2) end

		local IsLocal, InstanceType, FolderGetter, FolderName, Instantiable, CacheName, Cache do -- Get Function Constants
			InstanceType, IsLocal = MethodName:gsub("^Get", "", 1)
			if IsLocal == 0 then error("[Resources] Methods should begin with \"Get\"", 2) end -- Make sure methods begin with "Get"

			InstanceType, IsLocal = InstanceType:gsub("^Local", "", 1) -- Remove "Get" and "Local" prefixes from MethodName to isolate InstanceType
			assert(IsLocal == 0, "[Resources] Plugin version of Resources should not use keyword `Local`")
			FolderGetter = InstanceType == "Folder" and GetRootFolder or Resources.GetFolder -- Determine whether Method is Local

			if InstanceType:byte(-1) == 121 then -- if last character is a 'y'
				local Last = InstanceType:byte(-2)
				FolderName = Last ~= 97 and Last ~= 101 and Last ~= 105 and Last ~= 111 and Last ~= 117 and InstanceType:sub(1, -2) .. "ies" or InstanceType .. "s"
			else
				FolderName = InstanceType .. "s" -- Set FolderName to ["RemoteEvent" .. "s"], or ["Librar" .. "ies"]
			end

			Instantiable = InstantiableInstances[InstanceType]
			CacheName = FolderName
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
				Object = Folder:FindFirstChild(InstanceName, true)

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

	local Libraries = Resources:GetLocalTable("Libraries")
	local Descendants = TOP_OBJECT:GetDescendants()

	for i = 1, #Descendants do
		local Library = Descendants[i]
		Libraries[Library.Name] = Library
	end

	MakeGetterFunction(Resources, "GetLibrary", TOP_OBJECT)
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

return setmetatable(Resources, {
	__index = MakeGetterFunction;
	__call = Resources.LoadLibrary;
})
```
