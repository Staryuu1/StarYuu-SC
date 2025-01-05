local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Star Hub",
    LoadingTitle = "StarHub",
    LoadingSubtitle = "by Staryuu",
    ConfigurationSaving = {
    Enabled = false,
    FolderName = "StarHub", -- Create a custom folder for your hub/game
    FileName = "StarHub"
    },
    Discord = {
    Enabled = false,
    Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD.
    RememberJoins = false -- Set this to false to make them join the discord every time they load it up
    },
    KeySystem = true, -- Set this to true to use our key system
    KeySettings = {
    Title = "StarHub",
    Subtitle = "Key System",
    Note = "Ask Staryuu for key",
    FileName = "StarKey",
    SaveKey = true,
    GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
    Key = "StarGanteng"
    }
})

--- variable
Settings = {}
Settings.SelectedPortal = nil
Settings.SelectedTier = nil
Settings.SelectedDificult = nil
Settings.SelectedMacro = nil
Settings.Replay = false
local v5 = require(game.ReplicatedStorage.src.Loader)
local ItemInventoryServiceClient = v5.load_client_service(script, "ItemInventoryServiceClient")
local profile_data = { equipped_units = {} }
local rs = game:GetService("ReplicatedStorage")
local unit_data = require(rs.src.Data.Units)
---
-- auto save
function saveSettings()
    local HttpService = game:GetService('HttpService')
    local a = "Starhub"
    local b = game:GetService('Players').LocalPlayer.Name .. '_AnimeAdventures.json'
    if not isfolder(a) then
        makefolder(a)
    end
    writefile(a .. '/' .. b, HttpService:JSONEncode(Settings))
    Settings = ReadSetting()
    warn("Settings Saved!")
end
function ReadSetting()
    local s, e = pcall(function()
        local HttpService = game:GetService('HttpService')
        local a = "Starhub"
   		local b = game:GetService('Players').LocalPlayer.Name .. '_AnimeAdventures.json'
        if not isfolder(a) then
            makefolder(a)
        end
        return HttpService:JSONDecode(readfile(a .. '/' .. b))
    end)
    if s then
       
        return e
    else
        saveSettings()
        return ReadSetting()
    end
end
Settings = ReadSetting()
---

Spawn(function ()
    function notif(Title, content)
        Rayfield:Notify({
            Title = Title,
            Content = content,
            Duration = 6.5,
            Image = 4483362458,
            Actions = { -- Notification Buttons
               Ignore = {
                  Name = "Okay!",
                  Callback = function()
                  
               end
            },
         },
         })
    end
end)

--get player data --
function get_inventory_items_unique_items()
	return ItemInventoryServiceClient["session"]['inventory']['inventory_profile_data']['unique_items']
end
---
-- portal handler

function get_portal_uuid()
    local selectedPortalUUID = nil

    for i, v in pairs(get_inventory_items_unique_items()) do
        if string.find(v['item_id'], "portal") or string.find(v['item_id'], "disc") then
            if v['item_id'] == Settings.SelectedPortal then
                local portalDepth = v["_unique_item_data"]["_unique_portal_data"]["portal_depth"]
                local challenge = v["_unique_item_data"]["_unique_portal_data"]["challenge"]

                local isChallengeIgnored = false
                for _, ignoredChallenge in ipairs(Settings.SelectedDificult) do
                    if challenge == ignoredChallenge then
                        isChallengeIgnored = true
                        break
                    end
                end

                if not isChallengeIgnored then
                    for j = 2, #Settings.SelectedTier do
                        local selectedT = tonumber(Settings.SelectedTier[j])
                        if portalDepth == selectedT then
                            print(v["uuid"])
                            notif("InfoPortalSelected", "UUID: " .. v["uuid"] .. " | Tier: " .. portalDepth .. " | Challenge: " .. challenge)
                            selectedPortalUUID = v["uuid"]
                            break
                        end
                    end
                end
            end
        end
        if selectedPortalUUID then
            break
        end
    end

    return selectedPortalUUID
end



function spawnPortal()
    local selectedPortalUUID = get_portal_uuid()
if selectedPortalUUID then
    local args = {
        [1] = selectedPortalUUID
    }
    
    game:GetService("ReplicatedStorage"):WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("use_portal"):InvokeServer(unpack(args))
    
    
else
    notif("PortalStatus:", "Portal Not Found")
end

end
---
-- unit data handler
repeat
    for i, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "xp") and rawget(v, "uuid") and rawget(v, "unit_id") then
            table.insert(profile_data.equipped_units, v)
        end
    end
until #profile_data.equipped_units > 0

local function get_unit_data_by_id(id)
    for i, v in pairs(unit_data) do
        if v.id == id then
            return v
        end
    end
end

local function get_unit_by_uuid(uuid)
    for i, v in pairs(profile_data.equipped_units) do
        if v.uuid == uuid then
            return v
        end
    end
end

local function get_unit_by_name(name)
    for i, v in pairs(profile_data.equipped_units) do
        if v.unit_id == name then
            return v
        end
    end
end
--
-- Macro Handler
spawn(function()
    function upgrade_unit_by_pos(targetPos, money)
        local workspace = game:GetService("Workspace")
        local unitsFolder = workspace:WaitForChild("_UNITS")
        local nearestUnit = nil
        local nearestDistance = math.huge
        local lp = game.Players.LocalPlayer
        local money1 = tonumber(lp._stats.resource.Value)
        
        while money1 <= money do
            print("Waiting for conditions to be met...")
            wait(1)  -- Wait until money catches up
            money1 = tonumber(lp._stats.resource.Value)
        end
        
        for _, unit in ipairs(unitsFolder:GetChildren()) do
            repeat
                wait() -- Wait until the unit's _stats property is available
            until unit:FindFirstChild("_stats")
            
            local stats = unit:FindFirstChild("_stats")
            
            if stats and stats.player.Value == game.Players.LocalPlayer then
                local unitPos = unit.PrimaryPart.Position
                local distance = (unitPos - targetPos).Magnitude
                
                if distance < nearestDistance then
                    nearestUnit = unit
                    nearestDistance = distance
                end
            end
        end
        
        if nearestUnit then
            print("Nearest unit:", nearestUnit.Name, "at position:", nearestUnit.PrimaryPart.Position)
            
            local args = {
                [1] = nearestUnit
            }
            
            game:GetService("ReplicatedStorage"):WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("upgrade_unit_ingame"):InvokeServer(unpack(args))
            
            print("Upgraded unit:", nearestUnit.Name)
            
            return "Done upgrading unit: " .. nearestUnit.Name
        else
            print("No eligible units found.")
            return "No eligible units found."
        end
    end
     
end)

spawn(function ()
    function sell_unit_by_pos(targetPos)
        local workspace = game:GetService("Workspace")
        local unitsFolder = workspace:WaitForChild("_UNITS")
        local nearestUnit = nil
        local nearestDistance = math.huge
    
        for _, unit in ipairs(unitsFolder:GetChildren()) do
            local stats = unit:FindFirstChild("_stats")
            
            if stats and stats.player.Value == game.Players.LocalPlayer then
                local unitPos = unit.PrimaryPart.Position
                local distance = (unitPos - targetPos).Magnitude
                
                if distance < nearestDistance then
                    nearestUnit = unit
                    nearestDistance = distance
                end
            end
        end
        
        if nearestUnit then
            print("Nearest unit:", nearestUnit.Name, "at position:", nearestUnit.PrimaryPart.Position)
            
            local args = {
                [1] = nearestUnit
            }
            
            game:GetService("ReplicatedStorage"):WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("sell_unit_ingame"):InvokeServer(unpack(args))
            
            print("Sold unit:", nearestUnit.Name)
            
            return "Done selling unit: " .. nearestUnit.Name
        else
            print("No eligible units found.")
            return "No eligible units found."
        end
    end
end)
spawn(function ()
    function change_cycle_unit_by_pos(targetPos)
        local workspace = game:GetService("Workspace")
        local unitsFolder = workspace:WaitForChild("_UNITS")
        local nearestUnit = nil
        local nearestDistance = math.huge
    
        for _, unit in ipairs(unitsFolder:GetChildren()) do
            local stats = unit:FindFirstChild("_stats")
            
            if stats and stats.player.Value == game.Players.LocalPlayer then
                local unitPos = unit.PrimaryPart.Position
                local distance = (unitPos - targetPos).Magnitude
                
                if distance < nearestDistance then
                    nearestUnit = unit
                    nearestDistance = distance
                end
            end
        end
        
        if nearestUnit then
            print("Nearest unit:", nearestUnit.Name, "at position:", nearestUnit.PrimaryPart.Position)
            
            local args = {
                [1] = nearestUnit
            }
            
            game:GetService("ReplicatedStorage"):WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("cycle_priority"):InvokeServer(unpack(args))
            
            print("Changed cycle unit:", nearestUnit.Name)
            
            return "Done changing cycle unit: " .. nearestUnit.Name
        else
            print("No eligible units found.")
            return "No eligible units found."
        end
    end
end)
function replayRecordedData(path)
    local file = readfile("Starhub/Macro/"..path..".json")
    local players = game:GetService("Players")
    local lp = players.LocalPlayer
    local money = tonumber(lp._stats.resource.Value)
    local waveNum = workspace._wave_num.Value
    local time = workspace._wave_time.Value
    if file then
        print("MacroStart")
        local HttpService = game:GetService('HttpService')
        local recordData = HttpService:JSONDecode(file)
    
        local keys = {}
        for key in pairs(recordData) do
            table.insert(keys, tonumber(key))
        end
        table.sort(keys)
        
        for _, key in ipairs(keys) do
            local data = recordData[tostring(key)]  -- Using pairs instead of ipairs for dictionary-like keys
            print("data:", data)
            print("Money:", data.money)
            print("Type:", data.type)

            if Settings.Replay == false then 
                notif("Stopping Playing Macro", "Macro Stopped")
                break
            end

                if data.type == "spawn_unit" then
                    while money <= data.money do
                        print("Waiting for conditions to be met...")
                        wait(1)  -- Wait until money catches up
                        money = tonumber(lp._stats.resource.Value)
                        waveNum = workspace._wave_num.Value
                    end
                    local corStr = data.cframe
                        local corParts = {}
                        for str in corStr:gmatch("-?%d+%.?%d*") do
                            table.insert(corParts, tonumber(str))
                        end
                        local cor = CFrame.new(unpack(corParts))  -- Use "cframe" instead of "CFrame"
                    local unit = get_unit_by_name(data.unit)
                    
                    print("Spawning Unit:", unit.uuid)
                    
                    game:GetService("ReplicatedStorage").endpoints.client_to_server.spawn_unit:InvokeServer(unit.uuid, cor)
                    wait(1)
                elseif data.type == "upgrade_unit_ingame" then
                    while money <= data.money do
                        print("Waiting for conditions to be met...")
                        wait(1)  -- Wait until money catches up
                        money = tonumber(lp._stats.resource.Value)
                        waveNum = workspace._wave_num.Value
                    end
                    local corStr = data.pos
                    local corParts = {}
                    for str in corStr:gmatch("-?%d+%.?%d*") do
                        table.insert(corParts, tonumber(str))
                    end
                    local cor1 = Vector3.new(unpack(corParts))
                    
                    if cor1 then
                        print(cor1)
                        upgrade_unit_by_pos(cor1, data.money)
                        wait(1)
                        
                    else
                        print("Unit not found")
                    end
                elseif data.type == "cycle_priority" then
                    while tonumber(waveNum) < data.Wave or time >= data.Wavetime do
                        wait(1)  -- wait until wave number and time catches up
                        waveNum = workspace._wave_num.Value
                        time = workspace._wave_time.Value
                        print(time)
                    end
                    local corStr = data.pos
                    local corParts = {}
                    for str in corStr:gmatch("-?%d+%.?%d*") do
                        table.insert(corParts, tonumber(str))
                    end
                    local cor2 = Vector3.new(unpack(corParts))
                    
                    if cor2 then
                        change_cycle_unit_by_pos(cor2)
                    else
                        print("Unit not found")
                    end
                elseif data.type == "sell_unit_ingame"  then
                    local unit = Vector3.new(data.pos)
                    if unit then
                        sell_unit_by_pos(unit)
                    else
                        print("Unit not found")
                    end
                else
                    print('Invalid type:', data.type)
                end
        end
    end
end


--



local Tab1 = Window:CreateTab("join")
local SPortal = Tab1:CreateDropdown({
    Name = "Select portal",
    Options = {"eclipse portal","summer portal"},
    CurrentOption = Settings.SelectedPortal,
    Flag = "Portal",
    Callback = function(Option)
        print(Option[1])

        if Option[1] == "eclipse portal" then
            Settings.SelectedPortal = "portal_item__eclipse"
        elseif Option[1] == "summer portal" then
            Settings.SelectedPortal = "portal_summer"
        end
        
    end,
})
Tier = {}
for i = 0, 15 do
    table.insert(Tier, tostring(i))
end
local Tier = Tab1:CreateDropdown({
    Name = "Select Tier",
    Options = Tier,
    CurrentOption = {"nil"},
    MultipleOptions = true,
    Flag = "Tier",
    Callback = function(Option)
        Settings.SelectedTier = Option
    end,
})
local Challenge = Tab1:CreateDropdown({
    Name = "Ignore Challenge",
    Options = {"double_cost","short_range","fast_enemies","regen_enemies", "tank_enemies","shield_enemies"},
    CurrentOption = {"nil"},
    MultipleOptions = true,
    Flag = "Challenge",
    Callback = function(Option)    
        Settings.SelectedDificult = Option  
    end,
})

local Button = Tab1:CreateButton({
    Name = "Join portal",
    Callback = function()
    spawnPortal()    
    end,
 })

 local Tab2 = Window:CreateTab("Macro")
 local a = "Starhub/Macro/"
 if not isfolder(a) then
     makefolder(a)
 end
 
 local fileNames = listfiles("Starhub/Macro/")
 local options = {"nil"}
 
 for i, fileName in ipairs(fileNames) do
     if fileName:sub(-5) == ".json" then
         local macroName = fileName:sub(16, -6)  -- Extract the substring between "Macro" and ".json"
         table.insert(options, macroName)
     end
 end
 

local Dropdown = Tab2:CreateDropdown({
    Name = "Select Macro",
    Options = options,
    CurrentOption = options[1],
    Flag = "Selecting",
    Callback = function(Option)
        Settings.SelectedMacro = Option[1]
    end,
})

local Toggle2 = Tab2:CreateToggle({
    Name = "Play Macro",
    CurrentValue = false,
    Flag = "Play",
    Callback = function(Value)

    Settings.Replay = Value
    wait(0.1)
    notif("Playing Macro" , "Playing Macro:"..Settings.SelectedMacro)
    wait(0.1)
    replayRecordedData(Settings.SelectedMacro)
    end,
    })
 local Tab3 = Window:CreateTab("Settings")
 local Toggle = Tab3:CreateToggle({
    Name = "AutoSaveSettings",
    CurrentValue = false,
    Flag = "AutoSave", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    Callback = function(Value)
    if Value then
        game.Players.PlayerRemoving:Connect(function(player)
            if player == game.Players.LocalPlayer  then
                saveSettings()
            end
        end)
    end
    end,
 })
 local ManualSave = Tab3:CreateButton({
    Name = "ManualSaveSettings",
    Callback = function()
        saveSettings()
    end,
 })
 local Button = Tab3:CreateButton({
    Name = "Destroy Gui",
    Callback = function()
        Rayfield:Destroy()
    end,
 })
