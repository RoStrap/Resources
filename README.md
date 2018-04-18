# Resources
[Resources](https://github.com/RoStrap/Resources/blob/master/Resources.module.lua) is the core resource-manager and library-loader for [RoStrap](https://www.roblox.com/library/725884332/RoStrap). It is designed to streamline the loading of libraries and standardize the API for networking instances between the client and server.

## Set-up
[Resources](https://github.com/RoStrap/Resources/blob/master/Resources.module.lua) is automatically installed when you setup using the plugin, which can installed after clicking the logo [below](https://www.roblox.com/library/725884332/RoStrap):

[![](https://avatars1.githubusercontent.com/u/22812966?v=4&s=100)](https://www.roblox.com/library/725884332/RoStrap)

After installing, you should have a [Folder](http://wiki.roblox.com/index.php?title=API:Class/Folder) named "Repository" in [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage) (or [ServerScriptService](http://wiki.roblox.com/index.php?title=API:Class/ServerScriptService)). This `Repository` is where all of your [Libraries](https://github.com/RoStrap/Resources#library) will reside. *Only* [Folders](http://wiki.roblox.com/index.php?title=API:Class/Folder) and [Libraries](https://github.com/RoStrap/Resources#library) should go in this `Repository`.

## Initialization
To start using the module, simply [require](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) it. This is the standard way of requiring `Resources`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
```

## Demonstration
Here's a quick look at the API:
```lua
local Maid = Resources:LoadLibrary("Maid") -- requires a library by string

local ChatEvent = Resources:GetRemoteEvent("Chatted")
-- Gets RemoteEvent Resources.RemoteEvents.Chatted
-- On the server, it will generate Folder "RemoteEvents" and/or RemoteEvent "Chatted" if missing
-- On the client, it will yield until Resources.RemoteEvents.Chatted exists

local Shared = Resources:GetLocalTable("Shared")
-- Retrieves a (non-replicated) table hashed at key "Shared" (keys don't need to be strings)
```

## Terminology
### Library
A *Library* is constituted of a [ModuleScript](http://wiki.roblox.com/index.php?title=API:Class/ModuleScript) **and its descendants**. In the following image, there are only **two** Libraries; `Keys` and `Rbx_CustomFont`. These two will be accessible through the `LoadLibrary` function and **their descendants will not be**, though parent Libraries may internally utilize children through, for example, `require(script.Roboto)`.

![](https://user-images.githubusercontent.com/15217173/38775144-25b833f0-4038-11e8-9545-952f1634148b.png)

### Local
*Local* in a function-name refers to **a function that does not replicate** across the client-server boundary.

## API
All functions within `Resources` take in parameter `string Name`.

### LoadLibrary
When the server [requires](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) `Resources` for the first time, it will move the [Libraries](https://github.com/RoStrap/Resources#library) within `ServerStorage.Repository` to `ReplicatedStorage.Resources.Libraries`, where both the client and server can [require](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) them via the function `LoadLibrary`. Notice how folder heiarchy is ignored.

![](https://image.prntscr.com/image/ZonjgCDFQLabru0xbMBUNQ.png)

`LoadLibrary` is a require-by-string function which caches the results, so any given [Library](https://github.com/RoStrap/Resources#library) only has [require](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) called on it once ([require](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) is an [idempotent function](https://en.wikipedia.org/wiki/Idempotence#Computer_science_meaning)). To [require](http://wiki.roblox.com/index.php?title=Global_namespace/Roblox_namespace#require) the [Library](https://github.com/RoStrap/Resources#library) `Maid`, we could do the following:

```lua
local Maid = Resources:LoadLibrary("Maid")
-- Requires Library called "Maid"
-- If it has previously been required, simply returns previous result
-- @param string LibraryName The name of the library you wish to require
-- @returns the result of require(Library)
```

If so desired, **all** methods of `Resources` have *hybrid syntax*, meaning both method `:` and member `.` syntaxes are supported:

```lua
local require = Resources.LoadLibrary
local Maid = require("Maid")
```

To make a [Library](https://github.com/RoStrap/Resources#library) **server-only**, give them "Server" in the [Name](http://wiki.roblox.com/index.php?title=API:Class/Instance/Name) or make them a descendant of a [Folder](http://wiki.roblox.com/index.php?title=API:Class/Folder) with "Server" in the [Name](http://wiki.roblox.com/index.php?title=API:Class/Instance/Name) (not case-sensitive). This will make the [plugin](https://www.roblox.com/library/725884332/RoStrap) assign the **server-only** [Library](https://github.com/RoStrap/Resources#library) with the tag `ServerLibraries`. Conversely, [Libraries](https://github.com/RoStrap/Resources#library) moved into [ReplicatedStorage](http://wiki.roblox.com/index.php?title=API:Class/ReplicatedStorage) at run-time are tagged with the tag `ReplicatedLibraries`.

###### Note: Internally, `LoadLibrary` caches and returns `require(Resources:GetLibrary(LibraryName))`. `GetLibrary` is the only function that can retrieve objects from both `ServerStorage` and `ReplicatedStorage`. This is because libraries tagged with `ServerLibraries` are added directly to its cache (server-side only). `GetLocalLibrary` is technically a valid function, but unnecessary.

## Get Functions
Get Functions do a [hash-table](https://image.slidesharecdn.com/thebasicsanddesignofluatable-170213091607/95/the-basics-and-design-of-lua-table-8-638.jpg?cb=1486977682) lookup for the [Instance](http://wiki.roblox.com/index.php?title=API:Class/Instance) they are searching for. If this fails, the [Instance](http://wiki.roblox.com/index.php?title=API:Class/Instance) will be searched for via [FindFirstChild](http://wiki.roblox.com/index.php?title=API:Class/Instance/FindFirstChild).

**On the server, missing instances will be instantiated via [Instance.new](http://wiki.roblox.com/index.php?title=Instance_(Data_Structure)). On the client, the function will yield for the missing instances via [WaitForChild](http://wiki.roblox.com/index.php?title=API:Class/Instance/WaitForChild). This is true for all (non-Local) Get Functions.**

The object, once retrieved, will be cached in the aforementioned [hash-table](https://image.slidesharecdn.com/thebasicsanddesignofluatable-170213091607/95/the-basics-and-design-of-lua-table-8-638.jpg?cb=1486977682) for future calls and returned.

### GetFolder
`GetFolder` is the basis of all other functions within `Resources` (with the exception of [GetLocalTable](https://github.com/RoStrap/Resources#getlocaltable)). `GetFolder` returns a [Folder](http://wiki.roblox.com/index.php?title=API:Class/Folder) inside of `ReplicatedStorage.Resources`.

```lua
-- Folder Resources.Libraries
local Libraries = Resources:GetFolder("Libraries")

-- Folder Resources.BindableEvents
local BindableEvents = Resources:GetFolder("BindableEvents")
```

### Procedurally Generated Get Functions
Functions can be procedurally generated by `Resources`, in the form of `GetCLASSNAME` with string parameter [Name](http://wiki.roblox.com/index.php?title=API:Class/Instance/Name). These functions return an [Instance](http://wiki.roblox.com/index.php?title=API:Class/Instance) under `Resources:GetFolder(CLASSNAME:gsub("y$", "ie") .. "s")`.

```lua
local Chatted = Resources:GetRemoteEvent("Chatted")
-- Gets "Chatted" within Folder Resources:GetFolder("RemoteEvent" .. "s")
-- AKA ReplicatedStorage.Resources.RemoteEvents.Chatted

-- If either the Folder `RemoteEvents` or the RemoteEvent `Chatted` do not exist then:
--    on the server, they will be generated (Instance.new)
--    on the client, the thread will yield until they have been replicated (WaitForChild)
```

|GetRemoteEvent("Chatted")|⇨|GetFolder("RemoteEvents")|⇨|`ROOT`|
|:-----:|:-----:|:-----:|:-----:|:-----:|
|RemoteEvent `Chatted` in|**⇨**|Folder `RemoteEvents` in|**⇨**|`ReplicatedStorage.Resources`|

![](https://user-images.githubusercontent.com/15217173/38775951-d6bfbeee-404b-11e8-8396-9666a0b20b98.png)

[Any Instance type](http://wiki.roblox.com/index.php?title=API:Class/Instance#Inherited_Classes) is compatible with `Resources`:

```lua
local ClientLoaded = Resources:GetRemoteFunction("ClientLoaded")
```

In fact, `Resources` can also manage instance types that aren't instantiable by `Instance.new`. However, these **instances must be preinstalled in the locations in which they would otherwise be instantiated and will not be generated at run-time**. This allows you to do things like the following:

|```local Falchion = Resources:GetSword("Falchion")```|
|:-----:|
|![](https://user-images.githubusercontent.com/15217173/38775984-64af0b2e-404c-11e8-9279-0adace656665.png)|

### GetLocalTable
`GetLocalTable` returns a (non-replicated) [table](http://wiki.roblox.com/index.php?title=Table) hashed at the key which is passed in as a parameter. This is the only `Get` function that does not deal with [Instances](http://wiki.roblox.com/index.php?title=API:Class/Instance). This is a convienent way to avoid having [Libraries](https://github.com/RoStrap/Resources#library) that simply `return {}`

```lua
local Shared = Resources:GetLocalTable("Shared") -- returns a table

-- In another script
local Shared = Resources:GetLocalTable("Shared") -- same table (if on the same machine)
local Shared2 = Resources:GetLocalTable("Shared2") -- different table

-- The keys don't have to be strings
local PlayerData = Resources:GetLocalTable(6)
```

## Local Functions
If you want to access `LOCALSTORAGE`, you can call a function of the form `GetLocalCLASSNAME` to generate a [Local function](https://github.com/RoStrap/Resources#local). On the server, `LOCALSTORAGE` is located in [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage). On the client, `LOCALSTORAGE` is located in [LocalPlayer.PlayerScripts](http://wiki.roblox.com/index.php?title=API:Class/PlayerScripts). All [Instances](http://wiki.roblox.com/index.php?title=API:Class/Instance) managed by `Resources` are stored in [Folders](http://wiki.roblox.com/index.php?title=API:Class/Folder) named "Resources".

|Machine|`LOCALSTORAGE`|`LOCALRESOURCES`|
|:-----:|:----:|:----:|
|Server|`ServerStorage`|`ServerStorage.Resources`|
|Client|`Players.LocalPlayer.PlayerScripts`|`Players.LocalPlayer.PlayerScripts.Resources`|

**Both the server and clients can instantiate instances in their `LOCALSTORAGE` via Instance.new** (including the `LOCALRESOURCES` folders in the table above). No yielding involved.

```lua
local Attacking = Resources:GetLocalBindableEvent("Attacking")
-- Finds LOCALSTORAGE.Resources.BindableEvents.Attacking and creates if missing

-- where LOCALSTORAGE is PlayerScripts on the client and ServerStorage on the Server,
-- where "Resources" and "BindableEvents" are Folder Objects,
-- and "Attacking" is a BindableEvent Object

-- Each instance not present will always be generated (on whichever machine it runs, it will NOT be replicated)
```
|GetLocalBindableEvent("Attacking")|⇨|GetLocalFolder("BindableEvents")|⇨|Get `LOCALRESOURCES`|⇨|`ROOT`|
|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|
|BindableEvent `Attacking` in|**⇨**|Folder `BindableEvents` in|**⇨**|Folder `Resources` in|**⇨**|**`LOCALSTORAGE`**|

Here is what the above code would do if ran by the server versus what it would do if ran by a client:

|Server|Client|
|:----:|:----:|
|![](https://user-images.githubusercontent.com/15217173/38918583-6a9dcf50-42ab-11e8-8dbd-a165595af63f.png)|![](https://user-images.githubusercontent.com/15217173/38918817-00857d1a-42ac-11e8-9a3e-3176a2cb65b0.png)|

###### Note: In Play-Solo Mode, all local objects will go under `ServerStorage`, as there is no difference between the client and server. If you use identical Local-function calls on the client and server, this could cause conflicts in Play-Solo. `LOCALSTORAGE` is typically just for `GetLocalBindableEvent` calls and having a place to store server-only Libraries, which are under `GetLocalFolder("Resources")`

## Internals
The GetFunction generator practically looks like this (but is more efficient and expandable):

```lua
-- Given function GetChild which instantiates on the server and yields on the client if Object isn't found
-- Given function PlaceInCache(table Cache, RbxObject Object) which sets: Cache[Object.Name] = Object
-- Given string CLASSNAME from method Resources:GetCLASSNAME()

local FolderName = CLASSNAME:gsub("[^aeiou]y$", "ie") .. "s"

local Cache = Resources:GetLocalTable(FolderName)
local Folder = Resources:GetFolder(FolderName)

return function(Name)
	return Cache[Name] or PlaceInCache(Cache, GetChild(Folder, Name))
end
```

###### Note: Internally, `GetFolder` is generated and runs on the same code as functions like `GetRemoteEvent` or `GetLibrary` (the latter of which is generated by a call to `LoadLibrary`)

Although most people shouldn't need to access the internals of `Resources`, `GetLocalTable` is used internally and can be used to do just that. For example:

```lua
-- Cached results from `LoadLibrary` by string
local LoadedLibraries = Resources:GetLocalTable("LoadedLibraries")
-- e.g. {Maid = [require(ReplicatedStorage.Resources.Libraries.Maid)]}
```

All other hash tables internally used by `Resources` have keys identical to the [Folder](http://wiki.roblox.com/index.php?title=API:Class/Folder)-[names](http://wiki.roblox.com/index.php?title=API:Class/Instance/Name) of their generated folders within `Resources`.

```lua
-- Hash table of all Libraries accessible to this machine (server-only and replicated)
-- This will be empty on the client before `GetLibrary` or `LoadLibrary`
-- are called for the first time on the client
local LibraryObjects = Resources:GetLocalTable("Libraries")
-- This retrieves the cache used by Resources:GetLibrary()
-- e.g. {Maid = [ReplicatedStorage.Resources.Libraries.Maid]}


-- Procedurally generated tables:
local RemoteEvents = Resources:GetLocalTable("RemoteEvents")
-- This is a hash table of all RemoteEvents ever accessed through GetRemoteEvent() on this machine,
-- as well as all RemoteEvents that existed when Resources.GetRemoteEvent was first indexed
-- e.g. {Chatted = [ReplicatedStorage.Resources.RemoteEvents.Chatted]}


local LocalBindableEvents = Resources:GetLocalTable("LocalBindableEvents")
-- LOCALSTORAGE caches are prefixed by "Local", since there is no `GetLocalLocalTable`
-- This retrieves the cache used by Resources:GetLocalBindableEvent()

for RemoteName, RemoteObject in pairs(RemoteEvents) do
	print(RemoteName, "\t\t", RemoteObject:GetFullName())
end
```

## Ideas
#### Map Changer
Try using Resources to manage other things like Maps for a game! Make a Folder named "Maps" inside `ServerStorage.Resources` and it can then be accessed!
```lua
-- Server-side
local Resources = require(ReplicatedStorage:WaitForChild("Resources"))
local Hometown = Resources:GetLocalMap("Hometown v2")
Hometown.Parent = workspace
```
#### Gun system
```lua
-- Server-side
local GunThePlayerJustBought = Resources:GetLocalGun("Ak47")
-- Finds `ServerStorage.Resources.Guns.Ak47`
-- Make sure the above exists, otherwise, Resources will error trying to do Instance.new("Gun")

GunThePlayerJustBought:Clone().Parent = PlayerBackpackThatBoughtIt
```

#### UI system
```lua
-- Client-side
local ShopUI = Resources:GetUserInterface("Shop")
-- Yields for `ReplicatedStorage.Resources.UserInterfaces.Shop`
```

## Contact
If you have any questions, concerns, or feature requests, feel free to [send me a message on roblox](https://www.roblox.com/messages/compose?recipientId=2966752) or click the discord link below. There is also a dedicated issues tab at the top of this page, should you feel inclined to use that. Please send me links to your projects using this code! I would also appreciate being given credit!

<div align="left">
	<a href="https://discord.gg/2kXpuvb">
		<img src="https://discordapp.com/assets/94db9c3c1eba8a38a1fcf4f223294185.png" alt="Discord" width=200 height=68 />
	</a>
</div>
