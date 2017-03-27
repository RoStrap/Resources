# Nevermore

Nevermore is a resource-loader designed to simplify the loading of libraries and unify the networking of resources between the client and server. In this README, "Nevermore" and "the module" refer to [Nevermore.module.lua](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua)

Also check out the codebase of useful libraries made by the [NevermoreFramework organization](https://github.com/NevermoreFramework) intended to streamline game development on [ROBLOX](https://roblox.com).

## Features

Nevermore has a long list features, some are in development, and others are fully implemented. These include:

- [x] **OOP** - Nevermore's core components are fully *Object Oriented Programming* ready.
- [x] **On-request Loading** - Nevermore will only load the features you use. No more, no less.
- [x] **Tested** - Nevermore is thoroughly tested before each release. It won't break your code.
- [ ] **Easy Setup** - Nevermore's [installer plugin](https://github.com/NevermoreEngine/Installation-Plugin) will get Nevermore and the modules you want set up for you.
- [x] **Plays well with others** - Nevermore won't interfere with other frameworks or your existing code.

## Getting Started

The version of Nevermore in this repository will be distributed by the [Installer-Plugin] for [ROBLOX]. Until then, you can follow the following instructions:
* Insert a `ModuleScript` into [ReplicatedStorage](http://wiki.roblox.com/index.php?title=API:Class/ReplicatedStorage) and name it something like "Resources" or "Nevermore"
* Copy and paste the code from [Nevermore.module.lua](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua) into the ModuleScript
* Make sure your Module repository is a `Folder` called "Modules" inside [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage) containing only ModuleScripts and Folders

Note: If you deviate from these instructions, it is not guaranteed to work

## Usage

### Initialization
This is the standard way of loading Nevermore onto either the Client or Server.
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Nevermore = require(ReplicatedStorage.Nevermore)
```
### Debugging
If your game is still in-development, it is best to use the [debugging version of this module](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore_Debug.module.lua). After you have successfully run the [debugging version](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore_Debug.module.lua) without errors, you can use the [main version](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua).

### Functionality and API
Upon being required for the first time on the Server, Nevermore indexes all of the modules in the Repository in ServerStorage and moves the ModuleScripts to ReplicatedStorage so that the Client can access them. Note that modules with "Server" in their name will not be replicated to ReplicatedStorage, and will only be accessible to the server.

Nevermore's tables are basically just like the Folders they reference, however the tables do not contain properties as Folder Objects do. To fully understand this module, think of the tables mentioned as "Smart Folders".

```lua
local Nevermore = require(game.ReplicatedStorage.Nevermore)
```

All of Nevermore's tables are procedurally generated (with the exception of the preloaded ModuleScripts table and `LoadLibrary` wrapper). This means that the first time the server calls for `Nevermore.RemoteEvents` it creates a table with storage `Folder` "RemoteEvents" inside of Nevermore (if one doesn't exist, one will be generated). `Nevermore.RemoteEvents` can then access any and everything within the `Folder` "RemoteEvents." If you reference a `RemoteEvent` that doesn't exist, one of the desired name will be generated. For example:

```lua
local Nevermore = require(game.ReplicatedStorage.Nevermore)

-- The line below does the following:
-- [1] Find `Nevermore` local variable (the one 3 lines above from here)
-- [2] Index the table of "RemoteEvents" inside `Nevermore`; create if none exists
-- [3] Retrieve "Chatted" in `RemoteEvents`; create if none exists
-- [4] Store `RemoteEvent` "Chatted" in variable "CustomChatEvent" for later use
local CustomChatEvent = Nevermore.RemoteEvents["Chatted"]
```

Nevermore also comes with a `LoadLibrary` function, which is literally just a convenient wrapper to make a custom require-by-string function. It looks like this:
```lua
function Nevermore.LoadLibrary(Name)
	return require(Nevermore.Modules[Name])
end
```
To use it, do like so:
```lua
local LoadLibrary = Nevermore.LoadLibrary
local TweenModule = LoadLibrary("Tween")
```
I like to overwrite the default require function with it, because you don't need both:
```lua
local require = Nevermore.LoadLibrary
local TweenModule = require("Tween")
```

If you want to access local storage (not replicated across the client-server model), you can add `Local` before the singular of the `FolderName` to access it. On the server, "local storage" is located in [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage). On the client, "local storage" is located in [LocalPlayer](http://wiki.roblox.com/index.php?title=API:Class/Players/LocalPlayer). Everything Nevermore stores goes into folders named `Resources`.

```lua
-- Server-side
local GunThePlayerJustBought = Nevermore.LocalGun["Ak47"]
-- Finds `ServerStorage.Resources.Guns.Ak47`
-- Make sure the above exists if you want to use it for things that are not valid Roblox Classes
-- Otherwise, Nevermore will error trying to do Instance.new("Gun")

GunThePlayerJustBought:Clone().Parent = PlayerBackpackThatBoughtIt
```

#### Example
The best way to understand this module in its simplicity is to see it in action
```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local CustomChatEvent = Nevermore.RemoteEvents["Chatted"] -- This shortcut is in the Configuration of Nevermore
local CustomChatFunction = Nevermore.RemoteFunctions["ChatFunction"]
```

```lua
-- Using the default require function (faster)
local TweenModule = require(Nevermore.Modules["Tween"])

-- Using the wrapper require function
local require = Nevermore.LoadLibrary
local TweenModule = require("Tween")
```

#### Manage other things
Try using Nevermore to manage other things like Maps for a game! Make a Folder named "Maps" inside Nevermore and it can then be accessed!

```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local Hometown = Nevermore.Maps["Hometown v2"]
Hometown.Parent = workspace
```

## Attributions

Many thanks to the wonderful [contributors](https://github.com/NevermoreEngine/Nevermore/graphs/contributors) that have contributed bigly to Making Nevermore Great Again. Credit to [Validark](https://github.com/Narrev) for creating the main [Nevermore.module.lua](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua), to [Quenty](https://github.com/Quenty) for creating and open-sourcing the [original version](https://github.com/Quenty/NevermoreEngine), and also to the [original contributors]( https://github.com/Quenty/NevermoreEngine/graphs/contributors).
