-- @author Validark
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

-- Configuration
local FolderName = "Modules" -- Name of Module Folder in ServerScriptService
local ResourcesLocation -- Where the "Resources" folder is, it will be generated if needed
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- You can use Nevermore:GetEvent() instead of GetRemoteEvent()
	Function = "RemoteFunction";
}
local Plurals = { -- If you want to name the folder something besides [Name .. "s"]
	Accessory = "Accessories";
}

local NewInstance = Instance.new
local gsub = string.gsub
local type, require = type, require
local Destroy, FindFirstChild, GetService, GetChildren, WaitForChild = game.Destroy, game.FindFirstChild, game.GetService, game.GetChildren, game.WaitForChild

local RunService = GetService(game, "RunService")
local ServerStorage = GetService(game, "ServerStorage")
local ReplicatedStorage = GetService(game, "ReplicatedStorage")
local ServerScriptService = GetService(game, "ServerScriptService")

if script.Name == "ModuleScript" then error("[Nevermore] Nevermore was never given a name") end
if script.ClassName ~= "ModuleScript" then error("[Nevermore] Nevermore must be a ModuleScript") end
if script.Parent ~= ReplicatedStorage then error("[Nevermore] Nevermore must be parented to ReplicatedStorage") end

local function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
	local Object, Bool = FindFirstChild(Parent, Name)

	if not Object then
		Object = NewInstance(Class, Parent)
		Object.Name = Name
		Bool = true
	end

	return Object, Bool
end
local GetFirstChild = Retrieve

local self = {
	__metatable = "[Nevermore] Nevermore's metatable is locked";
	Retrieve = Retrieve;
	GetFirstChild = Retrieve;
}

local LocalResourcesLocation, CreateResourceManager
if not RunService:IsServer() then
	LocalResourcesLocation = GetService(game, "Players").LocalPlayer
	Retrieve = WaitForChild -- Clients wait for assets to be created by the server
else
	LocalResourcesLocation = ServerStorage
end

-- First-time use only
local function GetFolder() return Retrieve(ResourcesLocation or ReplicatedStorage, "Resources", "Folder") end
local function GetLocalFolder(...) -- This placeholder initializes the creation of the actual function 4 lines below
	function GetLocalFolder()
		return GetFirstChild(LocalResourcesLocation, "Resources", "Folder")
	end
	GetLocalFolder = CreateResourceManager(self, "GetLocalFolder")
	return GetLocalFolder(...)
end

function CreateResourceManager(self, Name) -- Create methods called to Nevermore
	if type(Name) == "string" then
		local FullName, Local = Name
		Name, Local = gsub(gsub(Name, "^Get", ""), "^Local", "")
		local Retrieve = Retrieve
		local GetFolder = GetFolder

		if Local > 0 then
			Retrieve = GetFirstChild
			GetFolder = GetLocalFolder
		end

		local Class = Classes[Name] or Name
		local Table = {}
		local Folder = GetFolder(Plurals[Class] or Class .. "s")

		local function Function(Nevermore, Name, Parent)
			if Nevermore ~= self then -- Enables functions to support calling by '.' or ':'
				Name, Parent = Nevermore, Name
			end
			local Object, Bool = Table[Name]
			if not Object then
				if Parent then
				    Object, Bool = Retrieve(Parent, Name, Class)
				else
				    Object, Bool = Retrieve(Folder, Name, Class)
				    Table[Name] = Object
				end
			end
			return Object, Bool
		end
		self[FullName] = Function
		return Function
	end
end
self.__index = CreateResourceManager
GetFolder = CreateResourceManager(self, "GetFolder") -- Generates Folder manager

local Modules do -- Assembles table Modules
	local Repository = GetFolder("Modules") -- Grabs Module folder

	if RunService:IsServer() then
		local ServerModules = FindFirstChild(ServerScriptService, FolderName or "Nevermore")
		local Count, NumDescendants, Undeletable = 0, 1
		local ServerRepository = GetLocalFolder("Modules")
		Modules = {ServerModules}
		repeat
			Count = Count + 1
			local GrandChildren = GetChildren(Modules[Count])
			Modules[Count] = nil
			local NumGrandChildren = #GrandChildren
			for a = 1, NumGrandChildren do
				local Descendant = GrandChildren[a]
				local Name = Descendant.Name
				Modules[NumDescendants + a], GrandChildren[a] = Descendant
				if Descendant.ClassName == "ModuleScript" then
					if Modules[Name] then
						error("[Nevermore] Duplicate Module with name \"" .. Name .. "\"")
					end
					Modules[Name] = Descendant
					Descendant.Parent = Name:lower():find("server") and ServerRepository or Repository
				elseif Descendant.ClassName ~= "Folder" then
					--Undeletable = true
					Descendant.Parent = Retrieve(ServerScriptService, "Server", "Folder")
				end
			end
			NumDescendants = NumDescendants + NumGrandChildren
		until Count == NumDescendants

		if not Undeletable then
			Destroy(ServerModules)
		end
	else
		Modules = Repository:GetChildren()
		for a = 1, #Modules do
			local Module = Modules[a]
			Modules[a] = nil
			Modules[Module.Name] = Module
		end
	end
end

function self.GetModule(Nevermore, Name) -- Custom Require function
	Name = Nevermore ~= self and Nevermore or Name
	return type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(Modules[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
end

self.__call = self.GetModule
self.LoadLibrary = self.GetModule
return setmetatable(self, self)
