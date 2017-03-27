-- @author Validark
-- @readme https://github.com/NevermoreFramework/Nevermore

local Resources = {}

local ModuleName = script.Name
local Classes = { -- ContainerName -> ClassName (default: ClassName = ContainerName .. "s")
	Resources = "Folder";
	Accessories = "Accessory";
	[ModuleName] = "Folder";
}

local sub = string.sub
local gsub = string.gsub
local new = Instance.new
local GetChildren = game.GetChildren
local FindFirstChild = game.FindFirstChild

local Folders, LocalFolders = game.ReplicatedStorage

local function __index(self, Index) -- Create methods called to Resources
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

	if not FindFirstChild(LocalFolders, "Resources") then
		new("Folder", LocalFolders).Name = "Resources"
	end

	local ServerModules = LocalFolders.Modules
	Folders, LocalFolders = __index(Resources, ModuleName), __index(Resources, "LocalResources")
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
				Modules[Name] = Descendant
				Descendant.Parent = find(lower(Name), "server") and LocalFolders.Modules or Repository
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

	Folders, LocalFolders = __index(Resources, ModuleName), __index(Resources, "LocalResources")
	Modules = __index(Resources, "Modules")
end
Resources.Resources, Resources.LocalResources = nil -- This cleans up the by-product of procedurally generating the Folders tables

function Resources.LoadLibrary(Name)
	return require(Modules[Name])
end

return setmetatable(Resources, {__index = __index})
