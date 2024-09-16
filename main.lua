-- X Hub - Current Place Name

--// Variables and Services
local repo = 'https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LaunchEnabled = false -- Toggle state for the launch functionality
local LaunchPower = 1 -- Default launch power multiplier
local AutofarmEnabled = false -- Toggle state for autofarm

local Toggles = getgenv().Linoria.Toggles
local Options = getgenv().Linoria.Options

-- UI Tabs, Group Boxes, and Related Variables
local placeId = game.PlaceId
local jobId = game.JobId
local supportedPlaceId = 2551991523

-- Kick if place ID or job ID doesn't match
if placeId ~= supportedPlaceId then
    LocalPlayer:Kick("Broken Bones Script Not Supported for this game.")
    return
end

-- Get current place name
local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name

-- Create the main window
local Window = Library:CreateWindow({
    Title = 'X Hub - ' .. placeName,
    Center = true,
    AutoShow = true,
    Resizable = true
})

-- Tabs
local Tabs = {
    Main = Window:AddTab('Main'),
    Misc = Window:AddTab('Misc'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- Group Boxes
local MainLeftGroupBox = Tabs.Main:AddLeftGroupbox('Launch Tool')
local MainRightGroupBox = Tabs.Main:AddRightGroupbox('Shop Features')
local MiscLeftGroupBox = Tabs.Misc:AddLeftGroupbox('Scripts')
local MiscRightGroupBox = Tabs.Misc:AddRightGroupbox('LocalPlayer Stats')
local ServerRightGroupBox = Tabs.Misc:AddRightGroupbox('Server')

--// Functions

-- Function to enable/disable Launch Tool
local function EnableLaunchTool(state)
    LaunchEnabled = state
    if LaunchEnabled then
        Library:Notify("Launch Tool is enabled")
    else
        Library:Notify("Launch Tool is disabled")
    end
end

-- Function to launch player to mouse click location with applied power
local function LaunchPlayer(targetPos)
    local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        local bodyVelocity = Instance.new("BodyVelocity")
        local direction = (targetPos - humanoidRootPart.Position).unit * 1000 * LaunchPower
        bodyVelocity.Velocity = direction -- Multiplied by Launch Power slider value
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Parent = humanoidRootPart

        -- Destroy velocity after 0.5 seconds
        task.delay(0.5, function()
            bodyVelocity:Destroy()
        end)
    end
end

-- Function to handle autofarming by launching player in random directions
local function Autofarm()
    while AutofarmEnabled do
        local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local randomDirection = Vector3.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000)).unit * 1000 * LaunchPower
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Velocity = randomDirection
            bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
            bodyVelocity.Parent = humanoidRootPart

            -- Destroy velocity after 0.5 seconds
            task.delay(0.5, function()
                bodyVelocity:Destroy()
            end)
        end
        task.wait(0.2) -- Wait 0.2 seconds between launches
    end
end

-- Function to upgrade stats
local function UpgradeStat(statName, value)
    local args = {
        [1] = statName,
        [2] = value
    }
    ReplicatedStorage.Functions.UpdateStat:InvokeServer(unpack(args))
end

-- Rejoin the current game
local function RejoinGame()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

-- Server Hop (random server)
local function ServerHop()
    TeleportService:Teleport(game.PlaceId)
end

-- Server Hop (server with lowest player count)
local function ServerHopLow()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
    for _, server in ipairs(servers.data) do
        if server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
            break
        end
    end
end

--// UI Setup

-- Main Tab - Left Groupbox for Launch Tool
MainLeftGroupBox:AddToggle('LaunchToolToggle', {
    Text = 'Launch Tool',
    Default = false, -- Start disabled
    Tooltip = 'Toggle to enable the Launch Tool',
    
    Callback = function(state)
        EnableLaunchTool(state)
    end
})

-- Launch Power Slider
MainLeftGroupBox:AddSlider('LaunchPowerSlider', {
    Text = 'Launch Power',
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 2, -- Allow decimal values
    Tooltip = 'Multiplier for the launch velocity',
    
    Callback = function(value)
        LaunchPower = value
        Library:Notify("Launch Power set to " .. tostring(value))
    end
})

-- Autofarm by Launch Toggle
MainLeftGroupBox:AddToggle('AutofarmToggle', {
    Text = 'Autofarm by Launch',
    Default = false,
    Tooltip = 'Toggle autofarming by launching in random directions every 0.2 seconds',
    
    Callback = function(state)
        AutofarmEnabled = state
        if state then
            task.spawn(Autofarm) -- Start autofarming in a new thread
        end
    end
})

MainLeftGroupBox:AddButton('Unbind Launch Tool', function()
    Toggles.LaunchToolToggle:SetValue(false)
    Library:Notify("Launch Tool unbound!")
end)

-- Main Tab - Right Groupbox for Shop Features
MainRightGroupBox:AddInput('LevelAddition', {
    Text = 'Level Addition',
    Default = 1,
    Numeric = true,
    Finished = true, -- fires callback only when enter is pressed
    Tooltip = 'Input the level increment amount'
})

-- Add Buttons to upgrade different levels
local levelTypes = {"breakslevel", "sprainslevel", "dislocationslevel", "flightlevel", "bouncelevel", "speedlevel"}

for _, level in ipairs(levelTypes) do
    MainRightGroupBox:AddButton('Upgrade ' .. level, function()
        local value = Options.LevelAddition.Value
        UpgradeStat(level, value)
        Library:Notify(level .. " upgraded by " .. value)
    end)
end

-- Misc Tab - Left Groupbox for Scripts
MiscLeftGroupBox:AddButton('Execute Infinite Yield', function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
    Library:Notify("Infinite Yield executed!")
end)

MiscLeftGroupBox:AddButton('Execute Dex Explorer', function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
    Library:Notify("Dex Explorer executed!")
end)

-- Misc Tab - Right Groupbox for LocalPlayer Stats
MiscRightGroupBox:AddInput('WalkSpeedInput', {
    Text = 'Walk Speed',
    Default = 16,
    Numeric = true,
    Finished = true, -- fires callback only when enter is pressed
    Tooltip = 'Set your walk speed'
})

MiscRightGroupBox:AddInput('JumpPowerInput', {
    Text = 'Jump Power',
    Default = 50,
    Numeric = true,
    Finished = true,
    Tooltip = 'Set your jump power'
})

MiscRightGroupBox:AddButton('Set WalkSpeed', function()
    LocalPlayer.Character.Humanoid.WalkSpeed = Options.WalkSpeedInput.Value
    Library:Notify("WalkSpeed set to " .. Options.WalkSpeedInput.Value)
end)

MiscRightGroupBox:AddButton('Set JumpPower', function()
    LocalPlayer.Character.Humanoid.JumpPower = Options.JumpPowerInput.Value
    Library:Notify("JumpPower set to " .. Options.JumpPowerInput.Value)
end)

MiscRightGroupBox:AddButton('Sit', function()
    LocalPlayer.Character.Humanoid.Sit = true
    Library:Notify("LocalPlayer is now sitting.")
end)

MiscRightGroupBox:AddButton('Reset Character', function()
    LocalPlayer:LoadCharacter()
end)

-- Misc Tab - Right Groupbox for Server Controls
ServerRightGroupBox:AddButton('Rejoin Game', function()
    RejoinGame()
end)

ServerRightGroupBox:AddButton('Server Hop', function()
    ServerHop()
end)

ServerRightGroupBox:AddButton('Server Hop Low', function()
    ServerHopLow()
end)

-- Watermark
Library:SetWatermark("X Hub - " .. LocalPlayer.Name)

-- ThemeManager and SaveManager Setup
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:SetFolder('XHub/SpecificGame')
ThemeManager:SetFolder('XHub')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- Loads any saved configuration marked for autoload
SaveManager:LoadAutoloadConfig()

Library:Notify("X Hub loaded!")
