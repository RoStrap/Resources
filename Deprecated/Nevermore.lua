-- @author Validark
-- @original Quenty
-- @readme https://github.com/NevermoreFramework/Nevermore

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Configuration
local FolderName = "Modules" -- Name of Module Folder in ServerScriptService
local ResourcesLocation = ReplicatedStorage -- Where the "Resources" folder is, it will be generated if needed
local Classes = { -- Allows for abbreviations
	Event = "RemoteEvent"; -- You can use Nevermore:GetEvent() instead of GetRemoteEvent()
	Function = "RemoteFunction";
}
local Plurals = { -- If you want to name the folder something besides [Name .. "s"]
	Accessory = "Accessories";
	Folder = script.Name
}

if script.Name == "ModuleScript" then error("[Nevermore] Nevermore was never given a name") end
if script.ClassName ~= "ModuleScript" then error("[Nevermore] Nevermore must be a ModuleScript") end
if script.Parent ~= ReplicatedStorage then error("[Nevermore] Nevermore must be parented to ReplicatedStorage") end

local function Retrieve(Parent, Name, Class) -- This is what allows the client / server to run the same code
	local Object, Bool = Parent:FindFirstChild(Name)

	if not Object then
		Object = Instance.new(Class, Parent)
		Object.Name = Name
		Bool = true
	end

	return Object, Bool
end
local GetFirstChild = Retrieve

local Nevermore = {
	__metatable = "[Nevermore] Nevermore's metatable is locked";
	Retrieve = Retrieve;
	GetFirstChild = Retrieve;
}

local LocalResourcesLocation, CreateResourceManager
if not RunService:IsServer() then
	LocalResourcesLocation = game:GetService("Players").LocalPlayer
	Retrieve = game.WaitForChild -- Clients wait for assets to be created by the server
else
	LocalResourcesLocation = ServerStorage
end

function CreateResourceManager(Nevermore, Name) -- Create methods called to Nevermore
	if type(Name) == "string" then
		local FullName, Local = Name
		Name, Local = Name:gsub("^Get", ""):gsub("^Local", "")
		local function Function(...)
			local Retrieve = Retrieve
			local ResourcesLocation = ResourcesLocation

			if Local > 0 then
				Retrieve = GetFirstChild
				ResourcesLocation = LocalResourcesLocation
			end

			local Class = Classes[Name] or Name
			local Table = {}
			local Folder = Retrieve(ResourcesLocation, Plurals[Class] or Class .. "s", "Folder")
			function Function(self, Name, Parent)
				if self ~= Nevermore then -- Enables functions to support calling by '.' or ':'
					Name, Parent = self, Name
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
			Nevermore[FullName] = Function
			return Function(...)
		end
		Nevermore[FullName] = Function
		return Function
	end
end
Nevermore.__index = CreateResourceManager
setmetatable(Nevermore, Nevermore)

local Modules do -- Assembles table Modules
	local Repository = Nevermore:GetFolder("Modules") -- Grabs Module folder
	ResourcesLocation = script

	if RunService:IsServer() then
		local ServerModules = ServerScriptService:FindFirstChild(FolderName or "Nevermore") or error("Make sure your module repository is a descendant of ServerScriptService named " ..  (FolderName or "Nevermore"))
		ServerModules.Name = ""
		local ServerRepository = Nevermore:GetLocalFolder("Modules")
		local Boundaries = {}
		local Count, BoundaryCount = 0, 0
		local NumDescendants, CurrentBoundary = 1, 1
		local LowerBoundary, SetsEnabled, UpperBoundary, LowerBoundary

		Modules = {ServerModules}

		repeat
			Count = Count + 1
			local Child = Modules[Count]
			local Name = Child.Name
			local GrandChildren = Child:GetChildren()
			local NumGrandChildren = #GrandChildren

			if SetsEnabled then
				if not LowerBoundary and Count > Boundaries[CurrentBoundary] then
					LowerBoundary = true
				elseif LowerBoundary and Count > Boundaries[CurrentBoundary + 1] then
					CurrentBoundary = CurrentBoundary + 2
					local Boundary = Boundaries[CurrentBoundary]

					if Boundary then
						LowerBoundary = Count > Boundary
					else
						SetsEnabled = false
						LowerBoundary = false
					end
				end
			end

			local Server = LowerBoundary or Name:lower():find("server")

			if NumGrandChildren ~= 0 then
				if Server then
					SetsEnabled = true
					Boundaries[BoundaryCount + 1] = NumDescendants
					BoundaryCount = BoundaryCount + 2
					Boundaries[BoundaryCount] = NumDescendants + NumGrandChildren
				end

				for a = 1, NumGrandChildren do
					Modules[NumDescendants + a] = GrandChildren[a]
				end
			end

			if Child.ClassName == "ModuleScript" then
				if LowerBoundary or not Modules[Name] then
					Modules[Name] = Child
					Child.Parent = Server and ServerRepository or Repository
				else
					error("[Nevermore] Duplicate Module with name \"" .. Name .. "\"")
				end
			elseif Child.ClassName ~= "Folder" then
				Child.Parent = Nevermore:GetLocalFolder("ServerStuff", ServerScriptService)
				warn("[Nevermore] You shouldn't have", Child:GetFullName(), "in your modules Repository")
			end
			NumDescendants, Modules[Count] = NumDescendants + NumGrandChildren
		until Count == NumDescendants
		ServerModules:Destroy()
	else
		Modules = Repository:GetChildren()
		for a = 1, #Modules do
			local Module = Modules[a]
			Modules[Module.Name], Modules[a] = Module
		end
	end
end

function Nevermore.GetModule(self, Name) -- Custom Require function
	Name = self ~= Nevermore and self or Name
	return type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(Modules[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
end

Nevermore.__call = Nevermore.GetModule
Nevermore.LoadLibrary = Nevermore.GetModule
return Nevermore
