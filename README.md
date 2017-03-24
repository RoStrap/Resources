# Nevermore

Nevermore is a module-loader designed to simplify the loading of libraries and unify the networking of resources between the client and server.

Also check out the codebase of useful libraries made by the [NevermoreFramework organization](https://github.com/NevermoreFramework) intended to streamline game development on [ROBLOX](https://roblox.com).

## Features

Nevermore has a long list features, some are in development, and others are fully implemented. These include:

- [x] **OOP** - Nevermore's core components are fully *Object Oriented Programming* ready.
- [x] **On-request Loading** - Nevermore will only load the features you use. No more, no less.
- [x] **Tested** - Nevermore is thoroughly tested before each release. It won't break your code.
- [ ] **Easy Setup** - Nevermore's [installer plugin](https://github.com/NevermoreEngine/Installation-Plugin) will get Nevermore and the modules you want set up for you.
- [x] **Plays well with others** - Nevermore won't interfere with other frameworks or your existing code.

## Getting Started

The version of Nevermore in this repository will be distributed by the [Installer-Plugin] for [ROBLOX]. Until then, you can follow the instructions in the [original repository](https://github.com/Quenty/NevermoreEngine).

## Usage

### Setup
Make sure Nevermore is a [ModuleScript](http://wiki.roblox.com/index.php?title=API:Class/ModuleScript) in [ReplicatedStorage](http://wiki.roblox.com/index.php?title=API:Class/ReplicatedStorage), and require it on both the Server and Client.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Nevermore = require(ReplicatedStorage.Nevermore)
```
### Configuration
At the beginning of the Nevermore code you will see some configurable variables. These are `DEBUG_MODE`, `FolderName`, and `ResourcesLocation`

Setting `DEBUG_MODE` to `true` will have Nevermore print to the output which modules load and which fail so developers can diagnose which modules are causing them issues.

`FolderName` is the name of the Parent Directory inside [ServerScriptService](http://wiki.roblox.com/index.php?title=API:Class/ServerScriptService) filled with modules accessible to Nevermore. By default, Nevermore expects a Folder called "Modules" or "Nevermore" in [ServerScriptService](http://wiki.roblox.com/index.php?title=API:Class/ServerScriptService) to contain all the modules.

`ResourcesLocation` is where resources like Modules, Events, or Game Maps are stored and accessed by Nevermore. This should be somewhere in ReplicatedStorage. By default, it creates a [Folder](http://wiki.roblox.com/index.php?title=API:Class/Folder) called "Resources" inside Nevermore.

### Functionality and API
Upon being required for the first time on the Server, Nevermore indexes all of the modules in the Repository in ServerScriptService and moves the ModuleScripts to ReplicatedStorage so that Nevermore on the Client can access them. Note that modules with "Server" in their name will not be replicated to ReplicatedStorage.

The first parameter of all of Nevermore's `Get` functions is `Name`. Calling `Nevermore:GetObjectType(Name)` will ask Nevermore to find an Object in "Resources" in a Folder called ("ObjectType" .. "s"). With the exception of `GetModule`, if a desired object does not exist, it will be procedurally generated. For example:

```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local CustomChatEvent = Nevermore:GetRemoteEvent("Chatted")
```

If you want to access local storage (not replicated across the client-server model), you can add `Local` after `Get` to access it. On the server, local storage is located in [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage). On the client, local storage is located in [LocalPlayer](http://wiki.roblox.com/index.php?title=API:Class/Players/LocalPlayer). Everything Nevermore stores goes under folders named `Resources`.

```lua
local GunThePlayerJustBought = Nevermore:GetLocalGun("Ak-47")
-- Make sure this exists if you want to use it
-- Otherwise, Nevermore will error trying to do Instance.new("Gun")

GunThePlayerJustBought:Clone().Parent = PlayerBackpackThatBoughtIt
```

Note: This local feature doesn't yet apply to modules. The only things currently excluded from replication are modules with "Server" in their name, which are moved to `ServerStorage` and thus only accessible from the Server.

#### Example

Upon first calling `GetEvent`, Nevermore will generate a new manager function stored at index `GetEvent`
This new function will access the Folder called "RemoteEvents" in "Resources". The Folder will be created if it doesn't already exist. The function then searches the Folder for an instance with the desired name, in this case "Chatted". If one doesn't exist, one will be created.

Specifically, the Server will create the new Instances, while Clients will yield until changes are replicated to ReplicatedStorage.

Shortcuts can also be used:
```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local CustomChatEvent = Nevermore:GetEvent("Chatted") -- This shortcut is in the Configuration of Nevermore

local CustomChatFunction = Nevermore:GetRemoteFunction("ChatFunction")
-- or
-- It isn't my fault Roblox doesn't call them Callbacks!
local CustomChatFunction = Nevermore:GetFunction("ChatFunction")
```

#### Module-loading
```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local Tween = Nevermore:GetModule("Tween")
```
You can also overwrite the default require function and substitute it with Nevermore's. After all, you don't need the original require function if all the modules are in "Resources"

```lua
local require = Nevermore.GetModule
local Tween = require("Tween")
```

#### Manage other things
Try using Nevermore to manage other things like Maps for a game! Make a Folder named "Resources" inside Nevermore (you can also place it in ReplicatedStorage outside of Nevermore, but make sure to change `ResourcesLocation` in the config data). Then make a folder that is the word with an "s" concatenated, in this case; "Maps". Inside "Maps" place the maps inside, and they can then be accessed by Nevermore by their string Name.


![Explorer Sample](http://image.prntscr.com/image/084280ba8b524e4eae4f183e41f5e496.png)

```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local Hometown = Nevermore:GetMap("Hometown v2")
Hometown.Parent = workspace
```

## Attributions

Many thanks to the wonderful [contributors](https://github.com/NevermoreEngine/Nevermore/graphs/contributors) that have contributed bigly to making Nevermore great again. Credit to [Quenty](http://github.com/Quenty) for creating and open-sourcing the original version of [Nevermore](https://github.com/Quenty/NevermoreEngine), and also to the [original contributors]( https://github.com/Quenty/NevermoreEngine/graphs/contributors).
