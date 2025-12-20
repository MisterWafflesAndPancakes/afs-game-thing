-- References
local Mobs = workspace.Scriptable.Mobs
local Player = game.Players.LocalPlayer
local LocalPlayer = game.Players.LocalPlayer -- Anti afk logic stuff
local RunService = game:GetService("RunService")

-- Get HumanoidRootPart
local function getHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Autofarm State
local TargetTier = "1"
local CurrentMob = nil
local running = true
local cycleTiers = true -- enabled at runtime    

-- Helpers
local function getMobsOfTier(tier)
    local list = {}
    for _, mob in ipairs(Mobs:GetChildren()) do
        if mob.Name == tier then
            table.insert(list, mob)
        end
    end
    return list
end

-- Gets mob health
local function getHealth(mob)
    local pvp = mob:FindFirstChild("PVPFolder")
    local hp = pvp and pvp:FindFirstChild("NewHealth")
    return hp and hp.Value or 0
end

-- Tp function
local function tpTo(mob)
    local hrp = mob:FindFirstChild("HumanoidRootPart")
    local myHRP = getHRP()
    if hrp and myHRP then
        myHRP.CFrame = hrp.CFrame
    end
end

-- Gets next mob thing
local function getNextMob(tier, current)
    local mobs = getMobsOfTier(tier)
    for i, mob in ipairs(mobs) do
        if mob == current then
            return mobs[i + 1] or mobs[1]
        end
    end
    return mobs[1]
end

-- Start function
local function startLoop()
    running = true

    -- Initialize first mob
    local mobs = getMobsOfTier(TargetTier)
    CurrentMob = mobs[1]

    -- Prevent duplicate connections
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end

    renderConnection = RunService.Heartbeat:Connect(function()
        if not running then return end

        -- Ensure valid mob
        if not CurrentMob then
            CurrentMob = getMobsOfTier(TargetTier)[1]
            return
        end

        -- Switch mob if dead
        if getHealth(CurrentMob) <= 0 then
            local mobs = getMobsOfTier(TargetTier)
            local nextMob = getNextMob(TargetTier, CurrentMob)

            -- If cycling is enabled and we loop back to the first mob, cycle tier
            if cycleTiers and nextMob == mobs[1] then
                cycleTier()
                return
            end

            CurrentMob = nextMob
            return
        end

        -- Teleport every frame
        tpTo(CurrentMob)
    end)
end

-- Stop function
local function stopLoop()
    running = false
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
end

local AllTiers = {"1", "2", "3", "4", "5", "6"}

local function cycleTier()
    -- Find current tier index
    local index
    for i, tier in ipairs(AllTiers) do
        if tier == TargetTier then
            index = i
            break
        end
    end

    -- Move to next tier (wrap around)
    local nextIndex = (index % #AllTiers) + 1
    TargetTier = AllTiers[nextIndex]

    -- Reset mob so loop picks new tier
    CurrentMob = nil
end    

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "AFS Mob Autofarm",
    LoadingTitle = "AFS Mob Autofarm",
    LoadingSubtitle = "Made by XestorIae",
    ConfigurationSaving = {
        Enabled = false
    }
})

-- UI
local Tab = Window:CreateTab("Autofarm")

-- Dropbown
Tab:CreateDropdown({
    Name = "Select Enemy Tier",
    Options = {"1", "2", "3", "4", "5", "6"},
    CurrentOption = {"1"},
    Callback = function(option)
        TargetTier = typeof(option) == "table" and option[1] or option
        CurrentMob = nil
    end
})

Tab:CreateToggle({
    Name = "Cycle Tiers",
    CurrentValue = true, -- enabled at runtime
    Callback = function(Value)
        cycleTiers = Value
    end,
})

-- On off switch
Tab:CreateToggle({
    Name = "Toggle Autofarm",
    CurrentValue = false,
    Callback = function(state)
        if state then
            startLoop()
        else
            stopLoop()
        end
    end
})


local Boxes = workspace.Scriptable.ChikaraBoxes

local function scanForClickDetectors()
    for _, box in ipairs(Boxes:GetChildren()) do
        for _, obj in ipairs(box:GetDescendants()) do
            if obj:IsA("ClickDetector") and obj.Parent then
                pcall(function()
                    fireclickdetector(obj, 0)
                end)
            end
        end
    end
end


local function startBoxLoop()
    if runningBoxes then return end
    runningBoxes = true

    boxLoopThread = task.spawn(function()
        while runningBoxes do
            scanForClickDetectors()
            task.wait(boxDelay or 0.2) -- safe default
        end
    end)
end

local function stopBoxLoop()
    runningBoxes = false
end

local ClickTab = Window:CreateTab("Auto Chikara Box")

ClickTab:CreateToggle({
    Name = "Auto Click Chikara Boxes",
    CurrentValue = true,
    Callback = function(state)
        if state then
            startBoxLoop()
        else
            stopBoxLoop()
        end
    end
})

ClickTab:CreateSlider({
    Name = "Click delay",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Callback = function(value)
        boxDelay = value
    end
})

-- Anti-AFK related stuff
local antiAFKEnabled = false
local antiAFKConnection

local AFKTab = Window:CreateTab("Anti-Afk")

AFKTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        antiAFKEnabled = Value

        if antiAFKEnabled then
            -- Connect anti-AFK
            antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        else
            -- Disconnect anti-AFK
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
                antiAFKConnection = nil
            end
        end
    end,
})
