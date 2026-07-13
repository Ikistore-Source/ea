-- [[ TAB 1: DASHBOARD MONITOR ]] --
local function FormatRibuan(angka)
    if not angka then return "0" end
    local sorted = string.format("%0.f", angka):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")
    return sorted
end

local total_wl, total_dl, total_bgl, total_tgd = 0, 0, 0, 0
local last_scan_time = 0
local scan_interval = 5
local auto_scan_enabled = true 

local function PerformScan()
    local temp_wl, temp_dl, temp_bgl, temp_tgd = 0, 0, 0, 0
    if GetObjectList then
        local success, objects = pcall(GetObjectList)
        if success and type(objects) == "table" then
            for _, obj in pairs(objects) do
                if type(obj) == "table" and obj.id then
                    local jumlah = tonumber(obj.count) or tonumber(obj.amount) or 0
                    if obj.id == 1796 then temp_wl = temp_wl + jumlah
                    elseif obj.id == 7188 then temp_dl = temp_dl + jumlah
                    elseif obj.id == 8470 then temp_bgl = temp_bgl + jumlah
                    elseif obj.id == 2950 then temp_tgd = temp_tgd + jumlah
                    end
                end
            end
        end
    end
    total_wl, total_dl, total_bgl, total_tgd = temp_wl, temp_dl, temp_bgl, temp_tgd
end

-- [[ TAB 2: TOOLS ]] --
local auto_exchange = false
local auto_backpack = false
local auto_take = false
local delay_val = 500

function ToolsLoop()
    while true do
        Sleep(100)
        if auto_exchange then
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|exchange_go\n" .. "buttonClicked|exq_8470_200_2950_1_0")
            Sleep(delay_val)
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|exchange_qty_8470_200_2950_1_0\n" .. "qty|1")
            Sleep(delay_val)
        end
        if auto_backpack then
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|backpack_menu\n" .. "itemid|2950")
            Sleep(delay_val)
        end
        if auto_take then
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|backpack_menu\n" .. "buttonClicked|0")
            Sleep(delay_val)
        end
    end
end
RunThread(ToolsLoop)

-- [[ TAB 3: VENDING PRO (FIXED) ]] --
if not settings then
    settings = { 
        entot = "100", 
        amount = "1500000000", 
        auto_wd = false,    -- Tambahan
        auto_ex = false     -- Tambahan
    }
end

RunThread(function()
    while true do
        Sleep(100)
        -- Bagian Withdraw Bank
        if settings.auto_wd then
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|bankgems\n" .. "ZgmT8PmnKxxh5Lgc7Lbw|1sKcCJul5Pi8TIHFaWm|\n" .. "XOB2N7r8ZWaBK2Kbh9jWZBO|kAbZzOXuJwV1pABBtoy|\n" .. "FMuuKKt0ckk9w8Bf|TvbeC4OpstHXhxCjXHR|\n" .. "8Pm73GFnNKnW8o5wzpDNsXc|QJC1266hBzlr8iloV|\n" .. "buttonClicked|wd\n" .. "amount|" .. settings.amount)
            Sleep(5000)
        end
        
        -- Bagian Exchange
        if settings.auto_ex then
            local btn_str = "ex2_8470_1_1500000000_0"
            SendPacket(2, "action|dialog_return\n" .. "dialog_name|exchange2_go\n" .. "M5ojAFn1E8xLPlmdVp2|BlthJKMXkmpS3MlusxoYyTGkFO|\n" .. "2yWBrky3sNhXIisuePbNkV1e|uZpWQbYX274nTP82DUe0yxqQrP|\n" .. "pyry6nduz7DbKZJDmtRzk7R|gxrktm3CaYlsah0o|\n" .. "EReWSNsJ8QZ0Tb7dX|TldhJ0LBDkKeFXpsV5NYqAPS|\n" .. "buttonClicked|" .. btn_str)
            Sleep(settings.entot)
        end
    end
end)

-- [[ CONFIGURATION & INITIALIZATION (AUTO DROPPER) ]] --
if not settings_drop then
    settings_drop = {
        world_name = "SUS",
        targetX = 0,
        targetY = 0,
        itemID = 2950,
        count = 50,
        is_active = false,       
        auto_drop = false,      
        trigger_inventory = false, 
        ghost_mode = false,     
        enable_webhook = false,
        webhook_url = "PasteLinkHere",
        discord_id = "1234567890",
        trigger_test_webhook = false
    }
end

local world_buffer = settings_drop.world_name
local webhook_buffer = settings_drop.webhook_url
local discord_id_buffer = settings_drop.discord_id

local function SafeGetItemName(id)
    if GetItemInfo then
        local info = GetItemInfo(id)
        if info and info.name then return info.name end
    end
    return "Item ID: " .. tostring(id)
end

local function GetInventoryCount(id)
    if GetInventory then
        for _, item in pairs(GetInventory()) do
            if item.id == id then return item.amount end
        end
    end
    return 0
end

local function SendDiscordReport(is_test)
    if not settings_drop.enable_webhook or settings_drop.webhook_url == "" or settings_drop.webhook_url == "PasteLinkHere" then return end
    local nick = GetLocal().name:gsub("`(%S)", ""):match("%S+") or "Unknown"
    local world_name = GetWorld().name or "Unknown"
    local item_dropped = SafeGetItemName(settings_drop.itemID)
    local title_text = is_test and "IKISTORE - WEBHOOK TEST" or "IKISTORE - AUTO DROPPER REPORT"
    local action_text = is_test and "Testing webhook connection..." or "Dropped " .. settings_drop.count .. "x " .. item_dropped
    local payload = [[{"content": "<@]] .. settings_drop.discord_id .. [[> Auto Drop Notice!", "embeds": [{"author": {"name": "]] .. title_text .. [["}, "fields": [{"name": "Account", "value": "]] .. nick .. [[", "inline": true}, {"name": "World", "value": "]] .. world_name .. [[", "inline": true}, {"name": "Action", "value": "]] .. action_text .. [["}], "color": 3447003}]}]]
    if MakeRequest then MakeRequest(settings_drop.webhook_url, "POST", {["Content-Type"] = "application/json"}, payload) end
end

RunThread(function()
    while true do
        Sleep(100)
        if settings_drop.trigger_test_webhook then settings_drop.trigger_test_webhook = false SendDiscordReport(true) end
        if settings_drop.trigger_inventory and not settings_drop.is_active and GetInventoryCount(settings_drop.itemID) >= settings_drop.count then settings_drop.is_active = true end
        if settings_drop.is_active then
            SendPacket(2, "action|input\n|text|/warp " .. settings_drop.world_name .. "\n")
            Sleep(3000)
            if settings_drop.ghost_mode then SendPacket(2, "action|input\n|text|/ghost\n") Sleep(200) end
            FindPath(settings_drop.targetX, settings_drop.targetY)
            Sleep(3000)
            if settings_drop.auto_drop then
                SendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" .. settings_drop.itemID .. "|\ncount|" .. settings_drop.count .. "\n")
                Sleep(5000)
                if settings_drop.enable_webhook then SendDiscordReport(false) end
            end
            settings_drop.is_active = false
        end
    end
end)

-- [[ FINAL COMBINED GUI ]] --
AddHook("OnDraw", "iks_combined_gui", function()
    if ImGui.Begin("IKISTORE - DASHBOARD") then
        if ImGui.BeginTabBar("MainTabs") then
            
            -- TAB 1: PLAYER INFO / MONITOR
            if ImGui.BeginTabItem("Player Info") then
                local player_name = "GUEST"
                local local_p = GetLocal()
                if type(local_p) == "table" and local_p.name then player_name = local_p.name end
                local world_name = "OUTSIDE"
                local w = GetWorld()
                if type(w) == "table" and w.name then world_name = string.gsub(w.name, "`%s", ""):gsub("`%w", "") end
                local current_time = os.time()
                local sisa_detik = scan_interval - (current_time - last_scan_time)
                if sisa_detik < 0 then sisa_detik = 0 end
                if auto_scan_enabled and world_name ~= "OUTSIDE" then
                    if (current_time - last_scan_time) >= scan_interval then PerformScan() last_scan_time = current_time end
                end
                
                local current_gems = GetPlayerInfo() and GetPlayerInfo().gems or 0
                local total_bgl_inv = GetItemCount(7188) or 0
                local total_tgd_inv = GetItemCount(8470) or 0
                local total_svl_inv = GetItemCount(2950) or 0
                
                ImGui.Separator()
                ImGui.Text("PLAYER STATUS INFO:")
                ImGui.Separator()
                ImGui.Text("GrowID     : " .. player_name)
                ImGui.Text("Total Gems : " .. FormatRibuan(current_gems))
                ImGui.Separator()
                ImGui.Text("INVENTORY VALUATION:")
                ImGui.Text("Total BGL  : " .. tostring(total_bgl_inv) .. " pcs")
                ImGui.Text("Total TGD  : " .. tostring(total_tgd_inv) .. " pcs")
                ImGui.Text("Total SVL  : " .. tostring(total_svl_inv) .. " pcs")
                
                ImGui.Separator()
                ImGui.Text("World : " .. world_name)
                ImGui.Text("FLOATING ITEMS VALUATION")
                ImGui.Text("Total DL   : " .. FormatRibuan(total_wl))
                ImGui.Text("Total BGL  : " .. FormatRibuan(total_dl))
                ImGui.Text("Total TGD  : " .. FormatRibuan(total_bgl))
                ImGui.Text("Total SVL  : " .. FormatRibuan(total_tgd))
                ImGui.Separator()
                ImGui.Text("Status : " .. (auto_scan_enabled and "AUTO SCAN ON" or "MANUAL MODE"))
                local changed, value = ImGui.Checkbox("Auto Scan (" .. (auto_scan_enabled and sisa_detik or "5") .. "s)", auto_scan_enabled)
                if changed then auto_scan_enabled = value end
                if ImGui.Button("SCAN MANUAL NOW", -1, 24) then PerformScan() last_scan_time = current_time end
                ImGui.EndTabItem()
            end

            -- TAB 2: TOOLS
            if ImGui.BeginTabItem("Tools") then
                local changed_ex, val_ex = ImGui.Checkbox("Auto Exchange", auto_exchange)
                if changed_ex then auto_exchange = val_ex end
                local changed_bp, val_bp = ImGui.Checkbox("Auto Open Backpack", auto_backpack)
                if changed_bp then auto_backpack = val_bp end
                local changed_tk, val_tk = ImGui.Checkbox("Auto Take Item", auto_take)
                if changed_tk then auto_take = val_tk end
                ImGui.Separator()
                ImGui.Text("Delay (ms):")
                if ImGui.Button("-", 30, 24) then if delay_val > 50 then delay_val = delay_val - 50 end end
                ImGui.SameLine()
                local changed_d, val_d = ImGui.InputInt("##delay_input", delay_val)
                if changed_d then delay_val = val_d end
                ImGui.SameLine()
                if ImGui.Button("+", 30, 24) then delay_val = delay_val + 50 end
                ImGui.EndTabItem()
            end

-- [[ GANTI BAGIAN TAB 3 DI GUI DENGAN INI ]] --
            if ImGui.BeginTabItem("Vending Pro") then
                ImGui.Text("Vending Pro Settings")
                local cDL, nDL = ImGui.InputInt("Delay (ms)", settings.entot)
                if cDL then settings.entot = nDL end
                local cAM, nAM = ImGui.InputInt("Amount Gems", settings.amount)
                if cAM then settings.amount = nAM end
                ImGui.Separator()
                local cWD, sWD = ImGui.Checkbox("AUTO WITHDRAW BANK", settings.auto_wd)
                if cWD then settings.auto_wd = sWD end
                local cEX, sEX = ImGui.Checkbox("AUTO EXCHANGE", settings.auto_ex)
                if cEX then settings.auto_ex = sEX end
                ImGui.Separator()
                ImGui.Text("Status WD : " .. (settings.auto_wd and "ON" or "OFF"))
                ImGui.Text("Status EX : " .. (settings.auto_ex and "ON" or "OFF"))
                ImGui.Separator()
                local count_tgd = GetItemCount(8470) or 0
                local count_svl = GetItemCount(2950) or 0
                ImGui.Text("Total TGD (8470): " .. tostring(count_tgd) .. " pcs")
                ImGui.Text("Total SVL (2950): " .. tostring(count_svl) .. " pcs")
                ImGui.Separator()
                ImGui.Text("Status: " .. (settings.is_active and "RUNNING" or "STOPPED"))
                ImGui.Text("Posisi: " .. math.floor(GetLocal().pos.x/32) .. "," .. math.floor(GetLocal().pos.y/32))
                ImGui.Text("GrowID: " .. (GetLocal() and GetLocal().name or "Unknown"))
                ImGui.EndTabItem()
            end

            -- TAB 4: AUTO DROPPER
            if ImGui.BeginTabItem("Auto Dropper") then
                local cWR, nWR = ImGui.InputText("World Name", world_buffer, 30)
                if cWR then world_buffer = nWR settings_drop.world_name = nWR end
                local cX, nX = ImGui.InputInt("Target X", settings_drop.targetX)
                if cX then settings_drop.targetX = nX end
                local cY, nY = ImGui.InputInt("Target Y", settings_drop.targetY)
                if cY then settings_drop.targetY = nY end
                if ImGui.Button("GET POS") then
                    local p = GetLocal()
                    if p then settings_drop.targetX = math.floor(p.pos.x/32) settings_drop.targetY = math.floor(p.pos.y/32) end
                end
                ImGui.SameLine()
                if ImGui.Button("GET WORLD") then
                    local w = GetWorld().name
                    if w and w ~= "" then world_buffer = w settings_drop.world_name = w end
                end
                local cID, nID = ImGui.InputInt("Item ID", settings_drop.itemID)
                if cID then settings_drop.itemID = nID end
                local cCT, nCT = ImGui.InputInt("Count", settings_drop.count)
                if cCT then settings_drop.count = nCT end
                local ch, st = ImGui.Checkbox("RUN POSITION", settings_drop.is_active)
                if ch then settings_drop.is_active = st end
                local chDrop, stDrop = ImGui.Checkbox("AUTO DROP", settings_drop.auto_drop)
                if chDrop then settings_drop.auto_drop = stDrop end
                local chTrig, stTrig = ImGui.Checkbox("TRIGGER BY INVENTORY", settings_drop.trigger_inventory)
                if chTrig then settings_drop.trigger_inventory = stTrig end
                local chG, stG = ImGui.Checkbox("GHOST MODE", settings_drop.ghost_mode)
                if chG then settings_drop.ghost_mode = stG end
                ImGui.EndTabItem()
            end

            -- TAB 5: WEBHOOK
            if ImGui.BeginTabItem("Webhook") then
                local chWeb, stWeb = ImGui.Checkbox("ENABLE DISCORD WEBHOOK", settings_drop.enable_webhook)
                if chWeb then settings_drop.enable_webhook = stWeb end
                local cURL, nURL = ImGui.InputText("Webhook URL", webhook_buffer, 200)
                if cURL then webhook_buffer = nURL settings_drop.webhook_url = nURL end
                local cUID, nUID = ImGui.InputText("Discord ID", discord_id_buffer, 30)
                if cUID then discord_id_buffer = nUID settings_drop.discord_id = nUID end
                if ImGui.Button("TEST DROP") then settings_drop.trigger_test_webhook = true end
                ImGui.EndTabItem()
            end
            
            ImGui.EndTabBar()
        end
        ImGui.End()
    end
end)
