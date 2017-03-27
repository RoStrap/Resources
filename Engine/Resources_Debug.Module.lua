-- Resources Revamp
-- @author Validark
-- @readme https://github.com/NevermoreFramework/Nevermore

local Resources = {}

local Classes = { -- ContainerName -> ClassName (default: ClassName = ContainerName .. "s")
	Accessories = "Accessory";
	Resources = "Folder";
}

local sub = string.sub
local gsub = string.gsub
local new = Instance.new
local GetChildren = game.GetChildren
local FindFirstChild = game.FindFirstChild

local Folders, LocalFolders = game.ReplicatedStorage

if script.Name ~= "Resources" then error("[Nevermore] Nevermore should be named \"Resources\"") end
if script.ClassName ~= "ModuleScript" then error("[Nevermore] Nevermore must be a ModuleScript") end
if script.Parent ~= game.ReplicatedStorage then error("[Nevermore] Nevermore must be parented to ReplicatedStorage") end

local function __index(self, Index) -- Create methods called to Resources
	if type(Index) ~= "string" then
		error("[Nevermore] You can only index strings inside Resources")
	end
	local Folders = Folders
	local Name, Class = gsub(Index, "^Local", "")

	if Class == 1 then
		Folders = LocalFolders
	end

	Class = Classes[Name] or sub(Name, 1, -2)
	local Table = {}
	local Folder = Folders[Name]
	self[Index] = Table

	return setmetatable(Table, {
		__index = function(self, Name)
			local Object = FindFirstChild(Folder, Name)

			if not Object then
				Object = new(Class, Folder)
				Object.Name = Name
			end

			Table[Name] = Object
			return Object
		end
	})
end

local Modules
if game:GetService("RunService"):IsServer() then
	LocalFolders = game.ServerStorage
	if not LocalFolders:FindFirstChild("Modules") then error("[Nevermore] Your modules Repository should be in ServerStorage and be named \"Modules\"") end
	if not FindFirstChild(LocalFolders, "Resources") then
		new("Folder", LocalFolders).Name = "Resources"
	end

	local ServerModules = LocalFolders.Modules
	Folders, LocalFolders = __index(Resources, "Resources"), __index(Resources, "LocalResources")
	local Repository = Folders.Modules
	local find, lower = string.find, string.lower
	local Count, NumDescendants = 0, 1
	Modules = {ServerModules}

	repeat
		Count = Count + 1
		local GrandChildren = GetChildren(Modules[Count])
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
				Descendant.Parent = find(lower(Name), "server") and LocalFolders.Modules or Repository
			elseif Descendant.ClassName ~= "Folder" then
				error(Descendant.Name .. " is neither a Folder nor a ModuleScript, and doesn't belong in the Modules Repository")
			end
		end
		NumDescendants, Modules[Count] = NumDescendants + NumGrandChildren
	until Count == NumDescendants

	ServerModules:Destroy()
	Resources.Modules = Modules
else
	LocalFolders = game.Players.LocalPlayer
	if not FindFirstChild(LocalFolders, "Resources") then
		new("Folder", LocalFolders).Name = "Resources"
	end
	local find = string.find
	local GetLocal = __index

	function __index(self, Name) -- Client just gets a copy, no object creation
		if type(Name) ~= "string" then
			error("[Nevermore] You can only index strings inside Resources [2]")
		end
		if find(Name, "^Local") then
			return GetLocal(self, Name)
		else
			local Table = GetChildren(Folders[Name])

			for a = 1, #Table do
				local Module = Table[a]
				Table[Module.Name], Table[a] = Module
			end

			self[Name] = Table
			return Table
		end
	end
	Folders, LocalFolders = __index(Resources, "Resources"), __index(Resources, "LocalResources")
	Modules = __index(Resources, "Modules")
end
Resources.Resources, Resources.LocalResources = nil -- This cleans up the by-product of procedurally generating the Folders tables
local DebugID, RequestDepth = 0, 0

function Resources.LoadLibrary(Name)
	if type(Name) ~= "string" then
		error("[Nevermore] LoadLibrary requires a string parameter")
	end
	DebugID = DebugID + 1
	local LocalDebugID = DebugID
	print(string.rep("\t", RequestDepth), LocalDebugID, "Loading:", Name)
	RequestDepth = RequestDepth + 1
	local Library = type(Name) ~= "string" and error("[Nevermore] ModuleName must be a string") or require(Modules[Name] or error("[Nevermore] Module \"" .. Name .. "\" is not installed."))
	RequestDepth = RequestDepth - 1
	print(string.rep("\t", RequestDepth), LocalDebugID, "Done loading:", Name)
	return Library
end

return setmetatable(Resources, {__index = __index; __metatable = "[Resources] Resources's metatable is locked"})
