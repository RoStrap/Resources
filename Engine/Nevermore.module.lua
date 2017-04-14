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

local function __index(self, Class) -- Create methods called to Resources
	local Name, Folder = gsub(Class, "^Local", "")
	Folder = (Folder == 0 and Folders or LocalFolders)[Name]
	local Table = GetChildren(Folder)

	for a = 1, #Table do -- Convert Array to hash table
		local Object = Table[a]
		Table[Object.Name], Table[a] = Object
	end

	self[Class] = Table
	Class = Classes[Name] or sub(Name, 1, -2)

	return setmetatable(Table, {
		__index = function(self, Name)
			local Object = FindFirstChild(Folder, Name)

			if not Object then
				Object = new(Class, Folder)
				Object.Name = Name
			end

			self[Name] = Object
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

	local Boundaries = {}
	local ServerModules = FindFirstChild(LocalFolders, "Modules") or LocalFolders.Resources.Modules
	ServerModules.Name = ""
	Folders = __index(Boundaries, ModuleName)
	LocalFolders = __index(Boundaries, "LocalResources")
	local Repository = Folders.Modules
	local find = string.find
	local lower = string.lower
	local Count, BoundaryCount = 0, 0
	local NumDescendants, CurrentBoundary = 1, 1
	local LowerBoundary, SetsEnabled, UpperBoundary, LowerBoundary

	Modules = {ServerModules}

	repeat
		Count = Count + 1
		local Child = Modules[Count]
		local Name = Child.Name
		local GrandChildren = GetChildren(Child)
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

		local Server = LowerBoundary or find(lower(Name), "server")

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
			end
			Child.Parent = Server and LocalFolders.Modules or Repository
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

	LocalFolders = __index({}, "LocalResources")
	Folders = GetChildren(Folders[ModuleName])

	for a = 1, #Folders do
		local Folder = Folders[a]
		local Objects = GetChildren(Folder)

		for b = 1, #Objects do
			local Object = Objects[b]
			Objects[Object.Name], Objects[b] = Object
		end
		Resources[Folder.Name], Folders[a] = Objects
	end
	Modules = Resources.Modules
end
Classes.Resources, Classes[ModuleName] = nil

local require = require
Resources.LoadLibrary = setmetatable({}, {
	__index = function(self, Name)
		local Library = require(Modules[Name])
		self[Name] = Library and Library or false
		return Library
	end
})

return setmetatable(Resources, {__index = __index})
