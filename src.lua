local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local char, root, hum

local isTeleporting = false
local targetedPlayer

local modules = {
    notification = require(ReplicatedStorage.Game.Notification),
    vehicle = require(ReplicatedStorage.Vehicle.VehicleUtils)
}

local getvehiclepacket = modules.vehicle.GetLocalVehiclePacket
local getvehiclemodel = modules.vehicle.GetLocalVehicleModel

local function onCharacterAdded(character)
    char, root, hum = character, character:WaitForChild("HumanoidRootPart"), character:WaitForChild("Humanoid")

    local function onDied()
        char, root, hum = nil, nil, nil
    end

    hum.Died:Connect(onDied)
end

local function getPlayer(partial)
    if partial ~= "" then
        local lower = partial:lower()
        for _, plr in next, Players:GetPlayers() do
            if plr.Name:sub(1,#partial):lower() == lower or plr.DisplayName:sub(1,#partial):lower() == lower then
                return plr
            end
        end
        return nil
    else
        return nil
    end
end

local function notify(text)
    return modules.notification.new({
        Text = text,
        Duration = 3
    })
end

local function getPlayerVehicle(target)
    for i, v in next, workspace.Vehicles:GetChildren() do
        for i2, v2 in next, v:GetChildren() do
            if v2.Name == "Seat" or v2.Name == "Passenger" then
                if v2:FindFirstChild("PlayerName") then
                    if v2.PlayerName.Value == target.Name then
                        return v
                    end
                end
            end
        end
    end
end

local function teleportPlayerToAd(target)
    local localVehicle = getvehiclepacket()
    if not localVehicle or (localVehicle and tostring(localVehicle.Type) ~= "Heli") then
        return false
    end

    local targetVehicle = getPlayerVehicle(target)
    local heli = getvehiclemodel()
    if not targetVehicle then
        return false
    end

    if heli.PrimaryPart.Position.y < 100 then
		return notify("Fly higher to descend the rope.")
	end

    if not heli.Preset:FindFirstChild("RopePull") then
        modules.vehicle.Classes.Heli.attemptDropRope()

        repeat task.wait(0.1) until heli.Preset:FindFirstChild("RopePull")
    end

    local ropepull = heli.Preset.RopePull
    local rope = heli.Winch.RopeConstraint
    ropepull.CanCollide = false
    rope.Length = 15000

    repeat
        ropepull.CFrame = targetVehicle.PrimaryPart.CFrame
        ropepull.ReqLink:FireServer(targetVehicle, Vector3.zero)
        
        task.wait()
    until ropepull.AttachedTo.Value

    local clock = tick()

    repeat
        targetVehicle:PivotTo(CFrame.new(90, 20, 1459))

        task.wait()
    until not target.Character or not target.Character:FindFirstChild("InVehicle") or tick() - clock > 5

    modules.vehicle.Classes.Heli.attemptDropRope()
    notify("Success!")
end

local function giveHyperShift()
    ReplicatedStorage.GarageEquipItem:FireServer("BodyColor", "HyperShift")
    ReplicatedStorage.GarageEquipItem:FireServer("SecondBodyColor", "HyperShift")
    ReplicatedStorage.GarageEquipItem:FireServer("Texture", "Checker")
    ReplicatedStorage.GarageEquipItem:FireServer("Spoiler", "Thrusters")
    ReplicatedStorage.GarageEquipItem:FireServer("Rim", "Spinner")
end

if player.Character and player.Character:FindFirstChild("Humanoid") then
    task.spawn(onCharacterAdded, player.Character)
end

local Window = Rayfield:CreateWindow({
    Name = "Untitled",
    LoadingTitle = "Lol",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil, -- Create a custom folder for your hub/game
        FileName = "Big Hub"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
        RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    },
    KeySystem = false, -- Set this to true to use our key system
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
        SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
        GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
        Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    }
})

local Tab = Window:CreateTab("Tab Example", 4483362458)

local ADSection = Tab:CreateSection("Ad Portal TP")

local Label = Tab:CreateLabel("Selected Target: NOT SET")

local Input = Tab:CreateInput({
    Name = "Target",
    PlaceholderText = "Input",
    RemoveTextAfterFocusLost = true,
    Callback = function(Text)
        targetedPlayer = getPlayer(Text)
        if targetedPlayer then
            Label:Set(("Target: %s"):format(targetedPlayer.Name))
        else
            Label:Set("Target: NOT SET")
        end
    end,
 })


 local Button2 = Tab:CreateButton({
    Name = "Teleport",
    Callback = function()
        local target = targetedPlayer
        if target then
            local character = target.Character
            if character then
                local humroot = character:FindFirstChild("HumanoidRootPart")
                if humroot then
                    if character:FindFirstChild("InVehicle") then
                        if not isTeleporting then
                            isTeleporting = true
                            teleportPlayerToAd(target)
                            isTeleporting = false
                        end
                    else
                        notify("Target is not in a vehicle.")
                    end
                end
            end
        end
    end,
 })

 local MiscSection = Tab:CreateSection("Misc")


local Button = Tab:CreateButton({
    Name = "Spawn Bank Truck",
    Callback = function()
        ReplicatedStorage.GarageSpawnVehicle:FireServer("Chassis", "BankTruck")
    end,
 })

local Button = Tab:CreateButton({
    Name = "Give Hypershift",
    Callback = function()
        giveHyperShift()
    end,
 })

--  local Toggle = Tab:CreateToggle({
--     Name = "Super Rocket Launcher",
--     CurrentValue = false,
--     Flag = "Toggle1",
--     Callback = function(Value)
        
--     end,
--  })

player.CharacterAdded:Connect(onCharacterAdded)
