local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Ok lol", HidePremium = false, SaveConfig = true, ConfigFolder = "Lol", IntroEnabled = false})

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Char, Root = nil, nil
local SelectedLocation, TargetedPlayer, PlaySound = nil, nil, nil
local VehicleUtils = require(ReplicatedStorage.Vehicle.VehicleUtils)
local IsTeleporting = false

local Sounds = {}
local TPLocations = {
    ["Ad Portal"] = CFrame.new(90, 20, 1459),
    ["Sewers"] = CFrame.new(-1289, -26, -1708),
}

coroutine.wrap(function() 
    for _, v in next, getgc() do
        if type(v) == "function" and getfenv(v).script == Player.PlayerScripts.LocalScript then
            local con = getconstants(v)
            if table.find(con, "Play") and table.find(con, "Source") and table.find(con, "FireServer") then
                PlaySound = v
            end
        end
    end
end)()

local function CharacterAdded(character)
    Char, Root = character, character:WaitForChild("HumanoidRootPart")
end

CharacterAdded(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(CharacterAdded)

local function GetPlayer(text)
    if text == "" then return nil end
    for _, v in next, Players:GetPlayers() do
        if v.Name:lower():match(text) or v.DisplayName:lower():match(text) then
            return v
        end
    end
    return nil
end

local function Notify(text)
    return require(ReplicatedStorage.Game.Notification).new({
        Text = text,
        Duration = 3
    })
end

local function GetPlayerVehicle(target)
    for _, v in next, workspace.Vehicles:GetChildren() do
        for _, v2 in next, v:GetChildren() do
            if v2.Name == "Seat" or v2.Name == "Passenger" then
                if v2:FindFirstChild("PlayerName") then
                    if v2.PlayerName.Value == target.Name then
                        return v
                    end
                end
            end
        end
    end
    return false
end

local function RocketLauncher(obj)
    if obj.Name == "Missile" then
        if obj:FindFirstChild("SeekingMissileExplode") then
            for x = 1, 50 * 5, 5 do
				for y = 1, 1 * 5, 5 do
					for z = 1, 50 * 5, 5 do
						obj.SeekingMissileExplode:FireServer(Root.Position + Vector3.new(x, y, z))
					end
				end
			end
        end
    end
end
workspace.ChildAdded:Connect(RocketLauncher)

local function TeleportPlayer(target)
    local vehicle = VehicleUtils.GetLocalVehiclePacket()
    if not vehicle or (vehicle and vehicle.Type ~= "Heli") then
        Notify("You're not in a heli")
        return false
    end
    local character = target.Character
    if not character or (character and not character:FindFirstChild("HumanoidRootPart")) then
        Notify("Player is not loaded in")
        return false
    end
    local inVehicle = character:FindFirstChild("InVehicle")
    if not inVehicle then
        Notify("Player is not in a vehicle")
        return false
    end
    local targetVehicle = GetPlayerVehicle(target)
    if not targetVehicle then
        Notify("Couldn't find vehicle..")
        return false
    end
    local currentHeli = vehicle.Model
    if currentHeli.PrimaryPart.Position.y < 250 then
        currentHeli.PrimaryPart.CFrame = currentHeli.PrimaryPart.CFrame * CFrame.new(0, 250, 0)
        task.wait(0.5)
    end

    if not currentHeli.Preset:FindFirstChild("RopePull") then
        VehicleUtils.Classes.Heli.attemptDropRope()
        repeat task.wait(0.1) until currentHeli.Preset:FindFirstChild("RopePull")
    end

    local RopePull = currentHeli.Preset.RopePull
    local Rope = currentHeli.Winch.RopeConstraint
    RopePull.CanCollide = false
    Rope.Length = 10000

    repeat
        RopePull.CFrame = targetVehicle.PrimaryPart.CFrame
        RopePull.ReqLink:FireServer(targetVehicle, Vector3.zero)

        task.wait()
    until RopePull.AttachedTo.Value

    repeat
        targetVehicle:PivotTo(SelectedLocation)

        task.wait()
    until not character or not character:FindFirstChild("InVehicle")

    VehicleUtils.Classes.Heli.attemptDropRope()
    Notify("Success!")
end

for i, v in next, require(ReplicatedStorage.Resource.Settings).Sounds do
    table.insert(Sounds, i)
end

local HeliTab = Window:MakeTab({
	Name = "Heli TP",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})


local TPSection = HeliTab:AddSection({
	Name = "TP Player"
})

local Label = TPSection:AddLabel("Selected Player: nil")

TPSection:AddTextbox({
	Name = "Target",
	Default = nil,
	TextDisappear = true,
	Callback = function(Value)
		TargetedPlayer = GetPlayer(Value)
        if TargetedPlayer then
            Label:Set(("Selected Player: %s"):format(TargetedPlayer.Name))
        else
            Label:Set("Selected Player: nil")
        end
    end
})

TPSection:AddDropdown({
	Name = "Location",
	Default = nil,
	Options = {"Ad Portal", "Sewers"},
	Callback = function(Value)
		SelectedLocation = TPLocations[Value]
	end     
})

TPSection:AddButton({
	Name = "Teleport!",
	Callback = function()
        if SelectedLocation then
            if TargetedPlayer then
                if not IsTeleporting then
                    IsTeleporting = true
                    TeleportPlayer(TargetedPlayer)
                    IsTeleporting = false
                else
                    Notify("Teleport in process..")
                end
            end
        end
	end     
})

local SoundsTab = Window:MakeTab({
	Name = "Sounds",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local PitchValue
local SoundsSection = SoundsTab:AddSection({
	Name = "Sounds"
})

SoundsSection:AddDropdown({
	Name = "Play Sound",
	Default = nil,
	Options = Sounds,
	Callback = function(Value)
		PlaySound(Value, {
			Pitch = PitchValue,
			Source = Char,
			Volume = math.huge,
			Multi = true,
			MaxTime = 25
		}, false)
	end    
})

SoundsSection:AddTextbox({
	Name = "Pitch",
	Default = "1",
	TextDisappear = true,
	Callback = function(Value)
		PitchValue = Value
	end	  
})

local VehicleTab = Window:MakeTab({
	Name = "Vehicle",
	Icon = "rbxassetid://4483345998",
	PremiumOnly = false
})

local VehiclesSection = VehicleTab:AddSection({
	Name = "Vehicles"
})

VehiclesSection:AddButton({
	Name = "Spawn Bank Truck",
	Callback = function()
        ReplicatedStorage.GarageSpawnVehicle:FireServer("Chassis", "BankTruck")
  	end    
})

VehiclesSection:AddButton({
	Name = "HyperShift Car",
	Callback = function()
        ReplicatedStorage.GarageEquipItem:FireServer("BodyColor", "HyperShift")
        ReplicatedStorage.GarageEquipItem:FireServer("SecondBodyColor", "HyperShift")
        ReplicatedStorage.GarageEquipItem:FireServer("Texture", "Checker")
        ReplicatedStorage.GarageEquipItem:FireServer("Spoiler", "Thrusters")
        ReplicatedStorage.GarageEquipItem:FireServer("Rim", "Spinner")
  	end    
})

OrionLib:Init()
