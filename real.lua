-- References
local Mobs = workspace.Scriptable.Mobs
local Player = game.Players.LocalPlayer

local function getHRP()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Autofarm State
local TargetTier = {"1"}
local CurrentMob = nil
local running = false

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

-- STart function
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

    renderConnection = RunService.RenderStepped:Connect(function()
        if not running then return end

        -- Ensure valid mob
        if not CurrentMob then
            CurrentMob = getMobsOfTier(TargetTier)[1]
            return
        end

        -- Switch mob if dead
        if getHealth(CurrentMob) <= 0 then
            CurrentMob = getNextMob(TargetTier, CurrentMob)
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
            if obj:IsA("ClickDetector") then
                fireclickdetector(obj, 0)
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
            task.wait(boxDelay)
        end
    end)
end

local function stopBoxLoop()
    runningBoxes = false
end

local ClickTab = Window:CreateTab("Auto Chikara Box")

ClickTab:CreateToggle({
    Name = "Auto Click Chikara Boxes",
    CurrentValue = false,
    Callback = function(state)
        if state then
            startBoxLoop()
        else
            stopBoxLoop()
        end
    end
})

ClickTab:CreateSlider({
    Name = "Scan Delay",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 1,
    Callback = function(value)
        boxDelay = value
    end
})
