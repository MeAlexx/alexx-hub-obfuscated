local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/3345-c-a-t-s-u-s/NEVERLOSE-UI-Nightly/main/source.lua"))()
local Notification = Library:Notification()

local DebugPrint = true

-- Helper function to safely print debug messages
local function SafeDebugPrint(msg)
    if DebugPrint then
        print("[ALEXX] " .. tostring(msg))
    end
end

if not LPH_OBFUSCATED then
    function LPH_NO_VIRTUALIZE(f)
        return f
    end
else
    DebugPrint = false
end

if ALEXX_LOADED and LPH_OBFUSCATED then
    Notification:Notify("error", "Double Execution Detected", "Please only execute Alexx once!", 5)
    return
end

getgenv().ALEXX_HUB_LOADED = true

-- Variables
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Humanoid

-- Initialize Humanoid once, and reuse it
local function InitializeHumanoid()
    Humanoid = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("Humanoid", 5)
    if Humanoid then
        LocalPlayer.Character.HumanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 5)
    end
end

if LocalPlayer.Character then
    InitializeHumanoid()
end

LocalPlayer.CharacterAdded:Connect(function()
    InitializeHumanoid()
end)

local AlexxConfiguration = {
    Main = {
        Combat = {
            AttackAura = false,
            AutoCombo = false,
        },
        Farm = {
            KillFarm = false,
            AutoUltimate = true,
        },
    },
    Player = {
        Character = {
            OverwriteProperties = false,
            WalkSpeed = 50,
            JumpPower = 100,
        },
    },
}

-- Functions
local Functions = {}

-- Find the best target within the maximum distance
function Functions.BestTarget(MaxDistance)
    MaxDistance = MaxDistance or math.huge
    local Target = nil
    local MinKills = math.huge

    for _, v in pairs(game:GetService("Players"):GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local rootPart = v.Character:FindFirstChild("HumanoidRootPart")
            local distance = (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude
            local kills = v:GetAttribute("Kills") or 0

            if rootPart and distance < MaxDistance and kills < MinKills then
                Target = v
                MaxDistance = distance
                MinKills = kills
            end
        end
    end

    SafeDebugPrint("Best target found: " .. (Target and Target.Name or "None"))
    return Target
end

-- Use a specific ability
function Functions.UseAbility(Ability)
    local Tool = LocalPlayer.Backpack:FindFirstChild(Ability)
    if Tool then
        SafeDebugPrint("Using ability: " .. Ability)
        LocalPlayer.Character.Communicate:FireServer({
            Tool = Tool,
            Goal = "Console Move",
            ToolName = tostring(Ability)
        })
    else
        SafeDebugPrint("Ability not found: " .. Ability)
    end
end

-- Get a random ability from the hotbar that's not on cooldown
function Functions.RandomAbility()
    local Hotbar = LocalPlayer.PlayerGui.Hotbar.Backpack.Hotbar
    local Abilities = {}

    for _, v in pairs(Hotbar:GetChildren()) do
        if v.ClassName ~= "UIListLayout" and v.Visible and v.Base.ToolName.Text ~= "N/A" and not v.Base:FindFirstChild("Cooldown") then
            table.insert(Abilities, v)
        end
    end

    if #Abilities > 0 then
        local RandomAbility = Abilities[math.random(1, #Abilities)]
        return RandomAbility.Base.ToolName.Text
    else
        SafeDebugPrint("No available abilities")
        return nil
    end
end

-- Activate ultimate ability
function Functions.ActivateUltimate()
    local UltimateBar = LocalPlayer:GetAttribute("Ultimate") or 0
    if UltimateBar >= 100 then
        LocalPlayer.Character.Communicate:FireServer({
            MoveDirection = Vector3.new(0, 0, 0),
            Key = Enum.KeyCode.G,
            Goal = "KeyPress"
        })
        SafeDebugPrint("Ultimate activated")
    else
        SafeDebugPrint("Ultimate not ready: " .. UltimateBar .. "%")
    end
end

-- Teleport under a player
function Functions.TeleportUnderPlayer(player)
    local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local targetCFrame = rootPart.CFrame * CFrame.new(0, -5, 0)
        LocalPlayer.Character:SetPrimaryPartCFrame(targetCFrame)
        SafeDebugPrint("Teleported under player: " .. player.Name)
    else
        SafeDebugPrint("Failed to teleport under player: " .. player.Name)
    end
end

-- Connections
RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(deltaTime)
    if not Humanoid then return end

    -- Attack aura logic
    if AlexxConfiguration.Main.Combat.AttackAura then
        local NearestTarget = Functions.BestTarget(5)
        if NearestTarget then
            Functions.TeleportUnderPlayer(NearestTarget)
            local RandomAbility = Functions.RandomAbility()
            if RandomAbility then
                Functions.UseAbility(RandomAbility)
            else
                Functions.ActivateUltimate()
            end
        end
    end

    -- Kill farm logic
    if AlexxConfiguration.Main.Farm.KillFarm then
        local BestTarget = Functions.BestTarget()
        if BestTarget then
            Functions.TeleportUnderPlayer(BestTarget)
            local RandomAbility = Functions.RandomAbility()
            if RandomAbility then
                Functions.UseAbility(RandomAbility)
            else
                Functions.ActivateUltimate()
            end
        end
    end

    -- Update player properties
    if AlexxConfiguration.Player.Character.OverwriteProperties then
        Humanoid.WalkSpeed = AlexxConfiguration.Player.Character.WalkSpeed
        Humanoid.JumpPower = AlexxConfiguration.Player.Character.JumpPower
    end
end))

-- UI Section
Library:Theme("original")

local Window = Library:AddWindow("Alexx Hub", "The Strongest Battlegrounds | discord.gg/alexxhub")
Notification.MaxNotifications = 6

Window:AddTabLabel('Home')

local MainTab = Window:AddTab('Main', 'home')
local PlayerTab = Window:AddTab('Player', 'earth')
local SettingsTab = Window:AddTab('Settings', 'locked')

-- Combat Section
local CombatSection = MainTab:AddSection('Combat', "left")
CombatSection:AddToggle('Attack Aura', false, function(val)
    AlexxConfiguration.Main.Combat.AttackAura = val
end)

-- Farm Section
local FarmSection = MainTab:AddSection('Farm', "right")
FarmSection:AddToggle('Kill Farm', false, function(val)
    AlexxConfiguration.Main.Farm.KillFarm = val
end)
FarmSection:AddToggle('Auto Ultimate', true, function(val)
    AlexxConfiguration.Main.Farm.AutoUltimate = val
end)

-- Player Section
local CharacterSection = PlayerTab:AddSection('Character', "left")
CharacterSection:AddToggle('Overwrite Properties', false, function(val)
    AlexxConfiguration.Player.Character.OverwriteProperties = val
end)
CharacterSection:AddSlider('Walkspeed', 50, 250, 50, function(val)
    AlexxConfiguration.Player.Character.WalkSpeed = val
end)
CharacterSection:AddSlider('Jumppower', 50, 250, 50, function(val)
    AlexxConfiguration.Player.Character.JumpPower = val
end)

-- Final Notification to confirm script load
Notification:Notify("info", "Alexx_Hub Loaded", "Alexx Hub has been successfully loaded.", 5)

-- End of script
SafeDebugPrint("Script successfully executed. Thank you for using alexxHub.")
