local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local webhookURL = "https://discordapp.com/api/webhooks/1429464248622256160/6e5QXW4sIITd78PsMFM2OXQZfvylMauf7xEA53yZEo7iSuhNDHhFcWljqM-RUkH53vK_"
local knownWebhookURL = "https://discordapp.com/api/webhooks/1429473270125822054/RNFlcpK1r-K3AdTDy109418szxs2H1MP3BzqoDTX0ZVdjEKXwl62YlwaKpSeZQz2S5hh"

function sendNotification(title, text)
    if config.notify then
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = config.notifyDuration
        })
    end
end

function sendWebhookMessage(player, webhookURL, isKnown)
    if not config.sendWebhook then return end

    local userId = player.UserId
    local gameid = game.GameId
    local avatarApiUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=420x420&format=Png"

    local avatarImageUrl = nil
    local requestFunc = http_request or request or (syn and syn.request) or (http and http.request)

    if requestFunc then
        local thumbnailResponse = requestFunc({
            Url = avatarApiUrl,
            Method = "GET"
        })

        local data = HttpService:JSONDecode(thumbnailResponse.Body)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            avatarImageUrl = data.data[1].imageUrl
        end
    else
        warn("HTTP request function not available.")
    end

    local success, gameInfo = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)

    local gameName = success and gameInfo.Name or "Unknown"
    local title = isKnown and "Known Person Detected" or "Mod Detected"
    local description = isKnown and "⚠️A KNOWN PERSON IS GURANTEED TO HAVE MOD CONNECTIONS⚠️" or ":rotating_light: A MODERATOR WILL BAN YOU IF YOU GET CAUGHT CHEATING IMMEDIATLY :rotating_light:"

    local message = {
        ["username"] = "Roblox Logger",
        ["embeds"] = {{
            ["title"] = title,
            ["color"] = 0,
            ["thumbnail"] = {
                ["url"] = avatarImageUrl or ""
            },
            ["description"] = description,
            ["fields"] = {
                {
                    ["name"] = "Username",
                    ["value"] = player.Name,
                    ["inline"] = true
                },
                {
                    ["name"] = "Game Name",
                    ["value"] = gameName,
                    ["inline"] = true
                },
                {
                    ["name"] = "Place ID",
                    ["value"] = tostring(game.PlaceId),
                    ["inline"] = true
                },
                {
                    ["name"] = "Job ID",
                    ["value"] = game.JobId,
                    ["inline"] = true
                },
                {
                    ["name"] = "Game ID",
                    ["value"] = game.GameId,
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "Logged at " .. os.date("%Y-%m-%d %H:%M:%S")
            }
        }}
    }

    if requestFunc then
        local jsonData = HttpService:JSONEncode(message)
        requestFunc({
            Url = webhookURL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonData
        })
    end
end

function checkPlayer(player)

    if config.modWatchList[player.UserId] then
        local message = "⚠️ Mod Joined!\n" .. player.Name .. " (UserId: " .. player.UserId .. ") is in the game!"
        sendNotification("⚠️ Mod Joined!", message)
        sendWebhookMessage(player, webhookURL, false)
        if config.PrintLogs then 
            warn("⚠️ Mod detected: " .. player.Name .. " (" .. player.UserId .. ")")
        end
    elseif config.knownWatchList[player.UserId] then
        local message = "🔍 Known Person Joined!\n" .. player.Name .. " (UserId: " .. player.UserId .. ") is in the game!"
        sendNotification("🔍 Known Person Joined!", message)
        sendWebhookMessage(player, knownWebhookURL, true)
        if config.PrintLogs then  
            warn("🔍 Known person detected: " .. player.Name .. " (" .. player.UserId .. ")")
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    checkPlayer(player)
end

Players.PlayerAdded:Connect(checkPlayer)
