--[[ local function Log(msg)
    print("|cff00ff00[ItemExport]:|r " .. tostring(msg))
end

local function Debug(msg)
    print("|cffffff00[ItemExport DEBUG]:|r " .. tostring(msg))
end ]] --

local bankWasOpened = false
local lastBagItems = {}
local lastBankItems = {}

local function InsertToChat(msg)

    local editBox = ChatEdit_GetActiveWindow()

    if not editBox then
        ChatFrame_OpenChat(msg)
    else
        editBox:Insert(msg)
    end

end

--------------------------------------------------
-- Сканирование сумок
--------------------------------------------------
local function ScanBags()

    local bagItems = {}
    local bankItems = {}

    local bagItemCount = 0
    local bankItemCount = 0

    local freeBagSlots = 0
    local freeBankSlots = 0

    local inventoryBags = {0, 1, 2, 3, 4}
    local bankBags = {-1, 5, 6, 7, 8, 9, 10, 11}

    local function ScanBagList(bagList, targetTable, isBank)

        for _, bagID in ipairs(bagList) do

            local slots = GetContainerNumSlots(bagID) or 0

            for slot = 1, slots do

                local texture, count, locked, quality, readable, lootable, link = GetContainerItemInfo(bagID, slot)

                if link then

                    local id = tonumber(link:match("item:(%d+)")) or 0

                    local itemName, itemLink, itemQuality, _, _, itemType, itemSubType = GetItemInfo(link)

                    table.insert(targetTable, {
                        item_id = id,
                        item_count = count or 1,
                        item_name = itemName or "Unknown",
                        item_link = itemLink or link,
                        item_quality = itemQuality or quality or 0,
                        item_type = itemType or "Unknown",
                        item_subtype = itemSubType or "Unknown"
                    })

                    if isBank then
                        bankItemCount = bankItemCount + 1
                    else
                        bagItemCount = bagItemCount + 1
                    end

                else
                    if isBank then
                        freeBankSlots = freeBankSlots + 1
                    else
                        freeBagSlots = freeBagSlots + 1
                    end
                end
            end
        end
    end

    ScanBagList(inventoryBags, bagItems, false)
    ScanBagList(bankBags, bankItems, true)

    return bagItems, bankItems, bagItemCount, bankItemCount, freeBagSlots, freeBankSlots
end

local function consolidate_items_by_link(items)

    local consolidated = {}

    for _, item in ipairs(items) do
        if item and item.item_link then
            local existing = consolidated[item.item_link]
            if existing then
                existing.item_count = existing.item_count + item.item_count
            else
                consolidated[item.item_link] = {
                    item_id = item.item_id,
                    item_count = item.item_count,
                    item_name = item.item_name,
                    item_link = item.item_link,
                    item_quality = item.item_quality,
                    item_type = item.item_type,
                    item_subtype = item.item_subtype
                }
            end
        end
    end

    local result = {}
    for _, item in pairs(consolidated) do
        table.insert(result, item)
    end
    return result
end

local function merge_bag_and_bank_items(bag_items, bank_items)
    local combined = {}
    for _, item in ipairs(bag_items or {}) do
        table.insert(combined, item)
    end
    for _, item in ipairs(bank_items or {}) do
        table.insert(combined, item)
    end
    return consolidate_items_by_link(combined)
end

--------------------------------------------------
-- Обновление экспортных данных
--------------------------------------------------

local function UpdateExportData()

    local name = UnitName("player")
    if not name then
        return
    end

    local bagItems, bankItems, bagItemCount, bankItemCount, freeBagSlots, freeBankSlots = ScanBags()

    -- защита от очистки сумок при logout
    if bagItemCount == 0 and bankItemCount == 0 then
        -- Debug("Scan returned 0 items. Previous data preserved.")
        return
    end

    if not ItemStorage_ExportData then
        ItemStorage_ExportData = {}
    end

    -- Ensure account-level basics exists
    if not ItemStorage_Basics then
        ItemStorage_Basics = {}
    end

    local previousFreeBankSlots = ItemStorage_ExportData.free_bank_slots

    ItemStorage_ExportData.character = name
    ItemStorage_ExportData.realm = GetRealmName()
    ItemStorage_ExportData.timestamp = time()
    ItemStorage_ExportData.location = GetRealZoneText() or "Unknown"
    ItemStorage_ExportData.money = GetMoney() or 0
    ItemStorage_ExportData.free_bag_slots = freeBagSlots
    lastBagItems = bagItems or {}

    if bankWasOpened then
        lastBankItems = bankItems or {}
        ItemStorage_ExportData.free_bank_slots = freeBankSlots
    else
        if #lastBankItems > 0 then
            -- Банк не открывался, сохраняем предыдущие данные банка
            ItemStorage_ExportData.free_bank_slots = previousFreeBankSlots or 0
        else
            lastBankItems = {}
            ItemStorage_ExportData.free_bank_slots = freeBankSlots
        end
    end

    -- Формируем отдельные разделы bags и bank
    ItemStorage_ExportData.bags = ItemStorage_ExportData.bags or {}
    ItemStorage_ExportData.bank = ItemStorage_ExportData.bank or {}

    ItemStorage_ExportData.bags.last_update = time()
    ItemStorage_ExportData.bags.items = consolidate_items_by_link(lastBagItems)

    -- Если банк открывался, обновляем его содержимое, иначе сохраняем существующие данные
    if bankWasOpened then
        ItemStorage_ExportData.bank.last_update = time()
        ItemStorage_ExportData.bank.items = consolidate_items_by_link(lastBankItems)
    else
        if ItemStorage_ExportData.bank and ItemStorage_ExportData.bank.items and #ItemStorage_ExportData.bank.items > 0 then
            -- сохраняем ранее записанные данные банка
        else
            ItemStorage_ExportData.bank.last_update = time()
            ItemStorage_ExportData.bank.items = consolidate_items_by_link(lastBankItems)
        end
    end

    ItemStorage_ExportData.free_total_slots = ItemStorage_ExportData.free_bag_slots + ItemStorage_ExportData.free_bank_slots

    -- Update account-level basics metadata (no items here)
    ItemStorage_Basics.character = name
    ItemStorage_Basics.realm = GetRealmName()
    ItemStorage_Basics.timestamp = time()

    -- Log("Export updated. Bag items: " .. bagItemCount .. ", Bank items: " .. bankItemCount)
end

--------------------------------------------------
-- Event handler
--------------------------------------------------

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BANKFRAME_OPENED")
frame:RegisterEvent("BANKFRAME_CLOSED")
frame:RegisterEvent("PLAYER_LOGOUT")

frame:SetScript("OnEvent", function(self, event)

    if event == "PLAYER_ENTERING_WORLD" then
        -- Log("Player entered world.")
        bankWasOpened = false
        -- Restore previously saved per-character data if present
        if ItemStorage_ExportData then
            if ItemStorage_ExportData.bags and ItemStorage_ExportData.bags.items then
                lastBagItems = ItemStorage_ExportData.bags.items
            end
            if ItemStorage_ExportData.bank and ItemStorage_ExportData.bank.items then
                lastBankItems = ItemStorage_ExportData.bank.items
            end
        else
            ItemStorage_ExportData = {}
        end
        UpdateExportData()

    elseif event == "BAG_UPDATE" then
        UpdateExportData()

    elseif event == "BANKFRAME_OPENED" then
        -- Log("Bank opened.")
        bankWasOpened = true
        UpdateExportData()

    elseif event == "BANKFRAME_CLOSED" then
        -- Log("Bank closed.")
        bankWasOpened = false
        UpdateExportData()

    elseif event == "PLAYER_LOGOUT" then
        -- Log("Logout detected. Using last stored snapshot.")
        bankWasOpened = false
    end

end)

--------------------------------------------------
-- Slash command
--------------------------------------------------

SLASH_EXPORT1 = "/export"

SlashCmdList["EXPORT"] = function()

    -- Log("Manual export triggered.")
    UpdateExportData()

end

SLASH_BAGFREE1 = "/bagfree"
SlashCmdList["BAGFREE"] = function()

    local bagItems, _, bagItemCount, _, bagFree, _ = ScanBags()

    InsertToChat("В сумках " .. bagFree .. " свободных мест")

end

SLASH_BANKFREE1 = "/bankfree"
SlashCmdList["BANKFREE"] = function()

    local _, _, _, _, _, bankFree = ScanBags()

    InsertToChat("В банке " .. bankFree .. " свободных мест")

end

SLASH_TOTALFREE1 = "/free"
SlashCmdList["TOTALFREE"] = function()

    local _, _, _, _, bagFree, bankFree = ScanBags()

    InsertToChat("Свободных мест всего: " .. (bagFree + bankFree))

end
