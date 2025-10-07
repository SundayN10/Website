-- Roblox Value Scanner
-- Scans for valuable items in player bases and sends webhook notifications

task.spawn(function()
    -- Configuration
    local TARGET_PLACE_ID = 109983668079237 -- Change this to your game's PlaceId
    local SCAN_INTERVAL = 5 -- Seconds between scans
    
    -- Webhook URLs for different value tiers
    local WEBHOOKS = {
        {min = "1M/s", max = "4.99M/s", url = "YOUR_WEBHOOK_URL_HERE", name = "1M-5M", title = "MEDIUM VALUE ITEMS (1M-5M)"},
        {min = "5M/s", max = "9.99M/s", url = "YOUR_WEBHOOK_URL_HERE", name = "5M-10M", title = "HIGH VALUE ITEMS (5M-10M)"},
        {min = "10M/s", max = "29.99M/s", url = "YOUR_WEBHOOK_URL_HERE", name = "10M-30M", title = "ULTRA VALUE ITEMS (10M-30M)"},
        {min = "30M/s", max = "5B/s", url = "https://discord.com/api/webhooks/1425040650902175839/Nnr58CKVbFMGgyA6t7eYOSkofvvVpCTASb9XypP789QCfmE7Xm9RqNzJv4TyM9FwwzTM", name = "30M-5B", title = "SUPREME VALUE ITEMS (30M-5B)"}
    }
    
    -- Services
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    -- Track sent items to avoid duplicates
    local sentItems = {}
    
    -- Check if we're in the correct game
    if game.PlaceId ~= TARGET_PLACE_ID then 
        warn("Not in target game. Current PlaceId:", game.PlaceId)
        return 
    end
    
    -- Parse value strings like "1.5M/s" to numbers
    local function parseValue(valueString)
        local numStr = valueString:gsub("%$", ""):gsub("%s", "")
        local amount, suffix = numStr:match("([%d%.]+)([KMB]?)")
        amount = tonumber(amount) or 0
        
        if suffix == "K" then
            amount = amount * 1000
        elseif suffix == "M" then
            amount = amount * 1000000
        elseif suffix == "B" then
            amount = amount * 1000000000
        end
        
        return amount
    end
    
    -- Get server player count
    local function getServerInfo()
        return tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers or 0)
    end
    
    -- Scan for items in value range
    local function scanForItems(minValue, maxValue)
        local minNum, maxNum = parseValue(minValue), parseValue(maxValue)
        if minNum > maxNum then
            minNum, maxNum = maxNum, minNum
        end
        
        local foundItems = {}
        local plotsFolder = workspace:FindFirstChild("Plots")
        
        if not plotsFolder then 
            return foundItems 
        end
        
        -- Scan each plot
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            -- Check if plot belongs to another player
            local plotSign = plot:FindFirstChild("PlotSign")
            if plotSign then
                local textLabel = plotSign:FindFirstChild("SurfaceGui")
                    and plotSign.SurfaceGui:FindFirstChild("Frame")
                    and plotSign.SurfaceGui.Frame:FindFirstChild("TextLabel")
                
                if textLabel and textLabel.Text ~= (LocalPlayer.DisplayName .. "'s Base") then
                    -- Scan animal podiums in this plot
                    local animalPodiums = plot:FindFirstChild("AnimalPodiums")
                    if animalPodiums then
                        for _, podium in ipairs(animalPodiums:GetChildren()) do
                            local overhead = podium:FindFirstChild("Base")
                                and podium.Base:FindFirstChild("Spawn")
                                and podium.Base.Spawn:FindFirstChild("Attachment")
                                and podium.Base.Spawn.Attachment:FindFirstChild("AnimalOverhead")
                            
                            if overhead then
                                -- Check if item is available (not crafting/in machine)
                                local status = overhead:FindFirstChild("Stolen")
                                if not (status and (status.Text == "CRAFTING" or status.Text == "IN MACHINE")) then
                                    local generation = overhead:FindFirstChild("Generation")
                                    local rarity = overhead:FindFirstChild("Rarity")
                                    local displayName = overhead:FindFirstChild("DisplayName")
                                    
                                    if generation and rarity and displayName then
                                        local itemValue = parseValue(generation.Text)
                                        
                                        -- Check if value is in range
                                        if itemValue >= minNum and itemValue <= maxNum then
                                            table.insert(foundItems, {
                                                name = displayName.Text,
                                                rarity = rarity.Text,
                                                generation = generation.Text
                                            })
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        return foundItems
    end
    
    -- Send webhook notification
    local function sendWebhook(items, webhookUrl, tierName, title)
        if typeof(items) ~= "table" or #items == 0 then 
            return 
        end
        
        -- Check if server is full
        if #Players:GetPlayers() >= (Players.MaxPlayers or 0) then 
            return 
        end
        
        -- Count duplicate items
        local itemCounts = {}
        for _, item in ipairs(items) do
            if item.name and item.generation then
                local key = item.name .. "|" .. item.generation
                itemCounts[key] = (itemCounts[key] or 0) + 1
            end
        end
        
        -- Filter out already sent items
        local newItems = {}
        for key, count in pairs(itemCounts) do
            if not sentItems[key] then
                sentItems[key] = true
                local name, gen = key:match("(.+)|(.+)")
                table.insert(newItems, {
                    name = name,
                    generation = gen,
                    quantity = count
                })
            end
        end
        
        if #newItems == 0 then 
            return 
        end
        
        -- Build description
        local description = ""
        for i, item in ipairs(newItems) do
            description = description .. "🔥 " .. item.name .. " — " .. item.generation
            if item.quantity > 1 then
                description = description .. " - " .. item.quantity .. "x"
            end
            if i < #newItems then
                description = description .. "\n"
            end
        end
        
        -- Create embed
        local embed = {
            embeds = {{
                title = "🔥 " .. title,
                description = description,
                color = 3447003,
                fields = {
                    {
                        name = "📊 Server Info",
                        value = getServerInfo(),
                        inline = false
                    },
                    {
                        name = "🆔 Job ID",
                        value = "```" .. tostring(game.JobId) .. "```",
                        inline = false
                    },
                    {
                        name = "🔗 Join Server",
                        value = "[CLICK TO JOIN](https://www.roblox.com/games/" .. game.PlaceId .. "?jobId=" .. game.JobId .. ")",
                        inline = false
                    }
                },
                footer = {
                    text = "Value Scanner | " .. tierName .. " | " .. os.date("!%H:%M:%S")
                }
            }}
        }
        
        -- Send request
        pcall(function()
            HttpService:RequestAsync({
                Url = webhookUrl,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = HttpService:JSONEncode(embed)
            })
        end)
    end
    
    -- Wait for game to load
    repeat task.wait() until game:IsLoaded()
    
    print("Scanner started! Scanning every", SCAN_INTERVAL, "seconds")
    
    -- Main scanning loop
    task.spawn(function()
        while task.wait(SCAN_INTERVAL) do
            pcall(function()
                for _, tier in ipairs(WEBHOOKS) do
                    local items = scanForItems(tier.min, tier.max)
                    sendWebhook(items, tier.url, tier.name, tier.title)
                end
            end)
        end
    end)
end)
