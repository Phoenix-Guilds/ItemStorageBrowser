local addonName, ItemStorageBrowser = ...

-- Проверка выбранных значений
local function HasSelectedValues(dropdown)
    if not dropdown.selectedValues then
        return false
    end
    for _, selected in pairs(dropdown.selectedValues) do
        if selected then
            return true
        end
    end
    return false
end

-- Обновление текста dropdown
local function UpdateDropdownText(dropdown, options)
    for value, selected in pairs(dropdown.selectedValues or {}) do
        if selected then
            for _, option in ipairs(options) do
                if option.value == value then
                    UIDropDownMenu_SetText(dropdown, option.text)
                    return
                end
            end
        end
    end

    UIDropDownMenu_SetText(dropdown, "Не выбрано")
end

local function RegisterBagsTab()

    ItemStorageBrowser:RegisterTab({
        name = "Сумки",
        icon = "Interface\\Icons\\INV_Misc_Bag_10",

        OnActivate = function(tab, container)

            if not tab.initialized then

                -- Фрейм фильтров
                tab.filtersFrame = CreateFrame("Frame", nil, container)
                tab.filtersFrame:SetSize(500, 40)
                tab.filtersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)

                -- Заголовок
                tab.typeLabel = tab.filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.typeLabel:SetPoint("LEFT", tab.filtersFrame, "LEFT", 0, 0)
                tab.typeLabel:SetText("Тип сумки:")
                tab.typeLabel:SetWidth(100)
                tab.typeLabel:SetJustifyH("CENTER")

                -- Dropdown
                tab.typeDropdown = CreateFrame("Frame", "ISB_BagTypeDropdown", tab.filtersFrame,
                    "UIDropDownMenuTemplate")
                tab.typeDropdown:SetPoint("LEFT", tab.typeLabel, "RIGHT", -20, -2)
                tab.typeDropdown:SetWidth(180)
                tab.typeDropdown.selectedValues = {}

                tab.types = {{
                    text = "Обычные сумки",
                    value = "Normal"
                }, {
                    text = "Сумки наложения чар",
                    value = "Enchanting"
                }, {
                    text = "Сумки травника",
                    value = "Herbalism"
                }, {
                    text = "Сумки шахтера",
                    value = "Mining"
                }, {
                    text = "Сумки кожевника",
                    value = "Leatherworking"
                }, {
                    text = "Сумки начертателя",
                    value = "Inscription"
                }, {
                    text = "Сумки ювелира",
                    value = "Jewelcrafting"
                }}

                UIDropDownMenu_Initialize(tab.typeDropdown, function(self)

                    for _, type in ipairs(tab.types) do

                        local info = UIDropDownMenu_CreateInfo()
                        info.text = type.text
                        info.value = type.value
                        info.checked = tab.typeDropdown.selectedValues[type.value]

                        info.func = function(self)

                            tab.typeDropdown.selectedValues = {}
                            tab.typeDropdown.selectedValues[self.value] = true

                            UpdateDropdownText(tab.typeDropdown, tab.types)
                            tab:UpdateFilterButtonState()

                        end

                        UIDropDownMenu_AddButton(info)

                    end

                end)

                UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

                -- Кнопки
                tab.resetButton = CreateFrame("Button", nil, tab.filtersFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(90, 22)
                tab.resetButton:SetPoint("LEFT", tab.typeDropdown, "RIGHT", 10, 2)
                tab.resetButton:SetText("Сбросить")

                tab.filterButton = CreateFrame("Button", nil, tab.filtersFrame, "UIPanelButtonTemplate")
                tab.filterButton:SetSize(90, 22)
                tab.filterButton:SetPoint("LEFT", tab.resetButton, "RIGHT", 10, 0)
                tab.filterButton:SetText("Подобрать")
                tab.filterButton:Disable()

                tab.resetButton:SetScript("OnClick", function()

                    tab.typeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

                    if tab.itemListContent then
                        tab.itemListContent:Hide()
                    end

                    tab:UpdateFilterButtonState()

                end)

                tab.UpdateFilterButtonState = function()

                    if HasSelectedValues(tab.typeDropdown) then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end

                end

                tab.filterButton:SetScript("OnClick", function()

                    local typesToFilter = HasSelectedValues(tab.typeDropdown) and tab.typeDropdown.selectedValues or nil
                    tab:FilterItems(typesToFilter)

                end)

                -- Список результатов
                tab.itemList = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
                tab.itemList:SetSize(500, 320)
                tab.itemList:SetPoint("TOPLEFT", tab.filtersFrame, "BOTTOMLEFT", 0, -10)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)

                tab.itemList:SetScrollChild(tab.itemListContent)

                tab.initialized = true

            end

            tab.filtersFrame:Show()
            tab.itemList:Show()

        end,

        FilterItems = function(tab, types)

            if not ItemStorageBrowser.database then
                return
            end

            tab.itemListContent:Hide()
            tab.itemListContent:SetParent(nil)

            tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
            tab.itemListContent:SetSize(500, 1)
            tab.itemList:SetScrollChild(tab.itemListContent)

            local yOffset = 0
            local hasResults = false

            for _, character in ipairs(ItemStorageBrowser.database) do

                for _, item in ipairs(character.items) do

                    local name, link, quality, _, _, itemType, itemSubType = GetItemInfo(item.link)

                    if itemType == "Сумки" then

                        local matches = true

                        if types then

                            local selectedType

                            for t, _ in pairs(types) do
                                selectedType = t
                            end

                            if selectedType == "Normal" then
                                matches = (itemSubType == "Сумка")
                            elseif selectedType == "Enchanting" then
                                matches = (itemSubType == "Сумка наложения чар")
                            elseif selectedType == "Herbalism" then
                                matches = (itemSubType == "Сумка травника")
                            elseif selectedType == "Mining" then
                                matches = (itemSubType == "Сумка шахтера")
                            elseif selectedType == "Leatherworking" then
                                matches = (itemSubType == "Сумка кожевника")
                            elseif selectedType == "Inscription" then
                                matches = (itemSubType == "Сумка начертателя")
                            elseif selectedType == "Jewelcrafting" then
                                matches = (itemSubType == "Сумка ювелира")
                            end

                        end

                        if matches then

                            hasResults = true

                            local itemFrame = CreateFrame("Frame", nil, tab.itemListContent)
                            itemFrame:SetSize(500, 30)
                            itemFrame:SetPoint("TOPLEFT", 0, yOffset)

                            local itemIcon = CreateFrame("Button", nil, itemFrame)
                            itemIcon:SetSize(24, 24)
                            itemIcon:SetPoint("LEFT", 5, 0)
                            itemIcon:SetNormalTexture(GetItemIcon(item.link))

                            itemIcon:SetScript("OnEnter", function()

                                GameTooltip:SetOwner(itemIcon, "ANCHOR_RIGHT")
                                GameTooltip:SetHyperlink(item.link)
                                GameTooltip:Show()

                            end)

                            itemIcon:SetScript("OnLeave", function()

                                GameTooltip:Hide()

                            end)

                            local quality = select(3, GetItemInfo(item.link)) or 1
                            local color = ITEM_QUALITY_COLORS[quality].hex

                            local itemButton = CreateFrame("Button", nil, itemFrame)
                            itemButton:SetPoint("LEFT", itemIcon, "RIGHT", 10, 0)
                            itemButton:SetSize(380, 24)

                            itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            itemButton.text:SetPoint("LEFT", 0, 0)
                            itemButton.text:SetText(color .. name .. "|r")

                            itemButton:SetScript("OnEnter", function()

                                GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
                                GameTooltip:SetHyperlink(item.link)
                                GameTooltip:Show()

                            end)

                            itemButton:SetScript("OnLeave", function()

                                GameTooltip:Hide()

                            end)

                            itemButton:SetScript("OnClick", function()

                                if IsShiftKeyDown() then
                                    ChatEdit_InsertLink(item.link)
                                end

                            end)

                            local countText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            countText:SetPoint("LEFT", itemButton, "RIGHT", 10, 0)
                            countText:SetText("x" .. item.count .. " (" .. character.name .. ")")

                            yOffset = yOffset - 30

                        end

                    end

                end

            end

            if not hasResults then

                local noResults = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noResults:SetPoint("CENTER", 0, 0)
                noResults:SetText("Сумки не найдены")

                yOffset = yOffset - 30

            end

            tab.itemListContent:SetSize(500, math.abs(yOffset))

        end,

        OnDeactivate = function(tab)

            tab.initialized = false

            if tab.filtersFrame then
                tab.filtersFrame:Hide()
            end

            if tab.itemList then
                tab.itemList:Hide()
            end

        end

    })

end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(self)

    RegisterBagsTab()
    self:UnregisterEvent("PLAYER_LOGIN")

end)
