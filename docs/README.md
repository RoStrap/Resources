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
- [x] **Fast** - Nevermore is coded for optimal efficiency (feel free to submit a pull request if you can make it faster)
- [x] **Light-weight** - Nevermore reuses the same functions for everything, so very little storage is wasted

## Getting Started

The version of Nevermore in this repository will be distributed by the [Installer-Plugin] for [ROBLOX]. Until then, you can follow the following instructions:
* Insert a `ModuleScript` into [ReplicatedStorage](http://wiki.roblox.com/index.php?title=API:Class/ReplicatedStorage) and name it something like "Resources" or "Nevermore"
* Copy and paste the code from [Nevermore.module.lua](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua) into the ModuleScript
* Make sure your Module repository is a `Folder` called "Modules" inside [ServerScriptService](http://wiki.roblox.com/index.php?title=API:Class/ServerScriptService) (or [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage) if you changed it to that in the configuration) containing ModuleScripts and Folders that will run your codebase.

Note: If you deviate from these instructions, it is not guaranteed to work

## Usage

### Initialization
This is the standard way of loading Nevermore onto either the Client or Server.
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Nevermore = require(ReplicatedStorage:WaitForChild("Nevermore"))
```
### Functionality and API
Upon being required for the first time on the Server, Nevermore indexes all of the modules in the Repository in ServerStorage and moves the ModuleScripts to ReplicatedStorage so that the Client can access them.

Note that Modules or Folders with "Server" in their name (and their descendants) will not be replicated to the clients via ReplicatedStorage and will only be accessible to the server (via ServerStorage).

Nevermore's main purpose is to retrieve objects for use on both the client and server, both by the same function. This way, modules can run the same code on both the client and server and be guaranteed the resource will be properly obtained. This allows Modules to run the same code on both the Client and Server

Nevermore's functions look something like this:
```lua
local Chatted = Nevermore:GetRemoteEvent("Chatted")
local ClientLoaded = Nevermore:GetRemoteFunction("ClientLoaded")
```

On the Server, any instance Nevermore calls for will be generated if it doesn't already exist. On the Client, Nevermore will yield until the desired object exists.

Let's go through an example:
```lua
local Chatted = Nevermore:GetRemoteEvent("Chatted")
```
Because the default installed functions include only `GetFirstChild` (FindFirstChild or Create if non-existant) and `LoadLibrary` (wrapper that returns `require(GetModule(NAME))`), `GetRemoteEvent` first needs to be generated. This function, when called, will search for the `RemoteEvent` ("Get" is removed internally) inside of the `RemoteEvents` Folder inside of Folder `ReplicatedStorage.Resources`. Any of these that don't exist will be created on the server. The Client will wait for these to exist.

Because functions are procedurally generated, any instance type is compatible with Nevermore:

```lua
-- Not sure why you would need to, but
-- this retrieves a TextLabel inside
-- Nevermore.TextLabels
local Superman = Nevermore:GetTextLabel("Superman")
```

In fact, Nevermore can also manage Resources that aren't creatable by `Instance.new`. They must however, be preinstalled into Replicated.Resources. The built-in `GetModule` function is an example of this. A `Module` is not a creatable instance (a ModuleScript is) but the Nevermore modules within ServerScriptService that are replicated go under a Folder called "Modules" so Nevermore will error (on the server) if a Module is called for that doesn't exist.

This basically allows you to do things like:
```lua
local Falchion = Nevermore:GetSword("Falchion")
-- As long as this exists as Resources.Swords.Falchion,
-- it will be retrieved

-- The function generator will remove "Get" from "GetSword"
-- It will then add "s" to "Sword" and thus expect the Folder
-- to be named "Swords". Custom names other than appending "s"
-- can be put in the `Plurals` table of Nevermore, such as Accessories
-- instead of Accessorys (just appending "s")
```

Nevermore also comes with a `LoadLibrary` function as mentioned before, which is basically just a convenient wrapper to make a custom require-by-string function. It caches modules that have already ran and returned, making it more efficient than the built-in require upon subsequent calls. To use it, do like so:
```lua
local LoadLibrary = Nevermore.LoadLibrary
local TweenModule = LoadLibrary("Tween")
```
I like to overwrite the default require function with it, because you don't need both:
```lua
local require = Nevermore.LoadLibrary
local TweenModule = require("Tween")
```

Otherwise, you can use the built-in global `require`, but it doesn't cache like LoadLibrary does:
```lua
local TweenModule = require(Nevermore:GetModule("Tween"))
```

If you want to access local storage (not replicated across the client-server model), you can add `Local` before the singular of the `FolderName` to access it. On the server, "local storage" is located in [ServerStorage](http://wiki.roblox.com/index.php?title=API:Class/ServerStorage). On the client, "local storage" is located in [LocalPlayer](http://wiki.roblox.com/index.php?title=API:Class/Players/LocalPlayer). Everything Nevermore stores goes into folders named `Resources`.

```lua
-- Server-side
local GunThePlayerJustBought = Nevermore:GetLocalGun("Ak47")
-- Finds `ServerStorage.Resources.Guns.Ak47`
-- Make sure the above exists if you want to use it for things that are not valid Roblox Classes
-- Otherwise, Nevermore will error trying to do Instance.new("Gun")

GunThePlayerJustBought:Clone().Parent = PlayerBackpackThatBoughtIt
```

#### Example
The best way to understand this module in its simplicity is to see it in action
```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local CustomChatEvent = Nevermore:GetRemoteEvent("Chatted") -- Can use either ":" or "."
local CustomChatFunction = Nevermore.GetRemoteFunction("ChatFunction")
```

```lua
-- Using the default require function
local TweenModule = require(Nevermore:GetModule("Tween"))

-- Using the wrapper require function
local require = Nevermore.LoadLibrary
local TweenModule = require("Tween")
```

#### Manage other things
Try using Nevermore to manage other things like Maps for a game! Make a Folder named "Maps" inside Nevermore and it can then be accessed!

```lua
local Nevermore = require(ReplicatedStorage.Nevermore)
local Hometown = Nevermore:GetMap("Hometown v2")
Hometown.Parent = workspace
```

## Attributions

Many thanks to the wonderful [contributors](https://github.com/NevermoreEngine/Nevermore/graphs/contributors) that have contributed bigly to Making Nevermore Great Again. Credit to [Validark](https://github.com/Narrev) for creating the main [Nevermore.module.lua](https://github.com/NevermoreFramework/Nevermore/blob/master/Engine/Nevermore.module.lua), to [Quenty](https://github.com/Quenty) for creating and open-sourcing the [original version](https://github.com/Quenty/NevermoreEngine), and also to the [original contributors]( https://github.com/Quenty/NevermoreEngine/graphs/contributors).
