local addonName, ItemStorageBrowser = ...

local function StyleEditBox(editBox)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 18,
        edgeSize = 16,
        insets = {
            left = 4,
            right = 4,
            top = 4,
            bottom = 4
        }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
end

-- Функция для проверки, есть ли выбранные значения в дропдауне
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

-- Функция для обновления текста дропдауна с множественным выбором (с ограничением длины)
local function UpdateMultiSelectDropdownText(dropdown, options)
    local selectedTexts = {}
    for value, selected in pairs(dropdown.selectedValues or {}) do
        if selected then
            for _, option in ipairs(options) do
                if option.value == value then
                    -- Удаляем цветовые коды для качества
                    local cleanText = string.gsub(option.text, "|c%x%x%x%x%x%x%x%x", "")
                    cleanText = string.gsub(cleanText, "|r", "")
                    table.insert(selectedTexts, cleanText)
                    break
                end
            end
        end
    end

    if #selectedTexts > 0 then
        local displayText = table.concat(selectedTexts, ", ")
        -- Ограничиваем длину текста, добавляя "..." если слишком длинный
        if #displayText > 25 then
            displayText = string.sub(displayText, 1, 22) .. "..."
        end
        UIDropDownMenu_SetText(dropdown, displayText)
    else
        UIDropDownMenu_SetText(dropdown, "Не выбрано")
    end
end

-- Ждем инициализации системы вкладок
local function RegisterArmorTab()
    -- Регистрируем вкладку брони
    ItemStorageBrowser:RegisterTab({
        name = "Броня",
        icon = "Interface\\Icons\\INV_Chest_Plate01",

        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.filtersFrame = CreateFrame("Frame", nil, container)
                tab.filtersFrame:SetSize(500, 80)
                tab.filtersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)

                -- Выбор типа брони
                tab.armorTypeLabel = tab.filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.armorTypeLabel:SetWidth(130)
                tab.armorTypeLabel:SetPoint("TOPLEFT", tab.filtersFrame, "TOPLEFT", 0, 0)
                tab.armorTypeLabel:SetText("Тип брони:")
                tab.armorTypeLabel:SetFontObject("ChatFontNormal")
                tab.armorTypeLabel:SetJustifyH("CENTER")

                tab.armorTypeDropdown = CreateFrame("Frame", "ISB_ArmorTypeDropdown", tab.filtersFrame,
                    "UIDropDownMenuTemplate")
                tab.armorTypeDropdown:SetPoint("TOPLEFT", tab.armorTypeLabel, "BOTTOMLEFT", -20, -5)
                tab.armorTypeDropdown:SetWidth(160)
                tab.armorTypeDropdown.selectedValues = {}

                tab.armorTypes = {{
                    text = "Ткань",
                    value = "Тканевые"
                }, {
                    text = "Кожа",
                    value = "Кожаные"
                }, {
                    text = "Кольчуга",
                    value = "Кольчужные"
                }, {
                    text = "Латы",
                    value = "Латные"
                }, {
                    text = "Щиты",
                    value = "Щиты"
                }}

                UIDropDownMenu_Initialize(tab.armorTypeDropdown, function(self, level, menuList)
                    for _, armorType in ipairs(tab.armorTypes) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = armorType.text
                        info.value = armorType.value
                        info.checked = tab.armorTypeDropdown.selectedValues[armorType.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.armorTypeDropdown.selectedValues[self.value] =
                                not tab.armorTypeDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.armorTypeDropdown, tab.armorTypes)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.armorTypeDropdown, "Не выбрано")

                -- Выбор слота
                tab.slotLabel = tab.filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.slotLabel:SetWidth(130)
                tab.slotLabel:SetPoint("LEFT", tab.armorTypeLabel, "RIGHT", 0, 0)
                tab.slotLabel:SetText("Слот:")
                tab.slotLabel:SetFontObject("ChatFontNormal")
                tab.slotLabel:SetJustifyH("CENTER")

                tab.slotDropdown = CreateFrame("Frame", "ISB_SlotDropdown", tab.filtersFrame, "UIDropDownMenuTemplate")
                tab.slotDropdown:SetPoint("TOPLEFT", tab.slotLabel, "BOTTOMLEFT", -20, -5)
                tab.slotDropdown:SetWidth(160)
                tab.slotDropdown.selectedValues = {}

                tab.slots = {{
                    text = "Голова",
                    value = "INVTYPE_HEAD"
                }, {
                    text = "Плечи",
                    value = "INVTYPE_SHOULDER"
                }, {
                    text = "Спина",
                    value = "INVTYPE_CLOAK"
                }, {
                    text = "Грудь",
                    value = "INVTYPE_CHEST"
                }, {
                    text = "Запястья",
                    value = "INVTYPE_WRIST"
                }, {
                    text = "Кисти рук",
                    value = "INVTYPE_HAND"
                }, {
                    text = "Пояс",
                    value = "INVTYPE_WAIST"
                }, {
                    text = "Ноги",
                    value = "INVTYPE_LEGS"
                }, {
                    text = "Ступни",
                    value = "INVTYPE_FEET"
                }, {
                    text = "Щит",
                    value = "INVTYPE_SHIELD"
                }}

                UIDropDownMenu_Initialize(tab.slotDropdown, function(self, level, menuList)
                    for _, slot in ipairs(tab.slots) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = slot.text
                        info.value = slot.value
                        info.checked = tab.slotDropdown.selectedValues[slot.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.slotDropdown.selectedValues[self.value] =
                                not tab.slotDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.slotDropdown, tab.slots)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.slotDropdown, "Не выбрано")

                -- Выбор качества (без пункта "Любое качество")
                tab.qualityLabel = tab.filtersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.qualityLabel:SetWidth(130)
                tab.qualityLabel:SetPoint("LEFT", tab.slotLabel, "RIGHT", 0, 0)
                tab.qualityLabel:SetText("Качество:")
                tab.qualityLabel:SetFontObject("ChatFontNormal")
                tab.qualityLabel:SetJustifyH("CENTER")

                tab.qualityDropdown = CreateFrame("Frame", "ISB_QualityDropdown", tab.filtersFrame,
                    "UIDropDownMenuTemplate")
                tab.qualityDropdown:SetPoint("TOPLEFT", tab.qualityLabel, "BOTTOMLEFT", -20, -5)
                tab.qualityDropdown:SetWidth(160)
                tab.qualityDropdown.selectedValues = {} -- Пустой по умолчанию

                tab.qualities = {{
                    text = "|cffffffffОбычное|r",
                    value = 1
                }, {
                    text = "|cff1eff00Необычное|r",
                    value = 2
                }, {
                    text = "|cff0070ddРедкое|r",
                    value = 3
                }, {
                    text = "|cffa335eeЭпическое|r",
                    value = 4
                }}

                UIDropDownMenu_Initialize(tab.qualityDropdown, function(self, level, menuList)
                    for _, quality in ipairs(tab.qualities) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = quality.text
                        info.value = quality.value
                        info.checked = tab.qualityDropdown.selectedValues[quality.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.qualityDropdown.selectedValues[self.value] =
                                not tab.qualityDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.qualityDropdown, tab.qualities)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.qualityDropdown, "Не выбрано")

                -- Уровень персонажа
                tab.levelFrame = CreateFrame("Frame", nil, tab.filtersFrame)
                tab.levelFrame:SetSize(150, 30)
                tab.levelFrame:SetPoint("TOPLEFT", tab.qualityLabel, "BOTTOMLEFT", 20, -5)

                tab.levelLabel = tab.levelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.levelLabel:SetWidth(130)
                tab.levelLabel:SetPoint("LEFT", tab.qualityLabel, "RIGHT", 0, 0)
                tab.levelLabel:SetFontObject("ChatFontNormal")
                tab.levelLabel:SetJustifyH("CENTER")
                tab.levelLabel:SetText("Уровень:")

                -- Красивые поля для уровней
                tab.levelInputFrame = CreateFrame("Frame", nil, tab.levelFrame)
                tab.levelInputFrame:SetWidth(140)
                tab.levelInputFrame:SetPoint("LEFT", tab.levelLabel, "RIGHT", 0, 0)

                tab.minLevel = CreateFrame("EditBox", nil, tab.levelInputFrame)
                tab.minLevel:SetSize(30, 24)
                tab.minLevel:SetPoint("TOPLEFT", tab.levelLabel, "BOTTOMLEFT", 26, -7)
                tab.minLevel:SetAutoFocus(false)
                tab.minLevel:SetNumeric(true)
                tab.minLevel:SetMaxLetters(2)
                tab.minLevel:SetText("")
                tab.minLevel:SetCursorPosition(0)
                tab.minLevel:SetFontObject("ChatFontNormal")
                tab.minLevel:SetJustifyH("CENTER")
                StyleEditBox(tab.minLevel)

                tab.levelSeparator = tab.levelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tab.levelSeparator:SetPoint("LEFT", tab.minLevel, "RIGHT", 5, 0)
                tab.levelSeparator:SetText("-")
                tab.levelSeparator:SetTextColor(1, 1, 1, 0.7)

                tab.maxLevel = CreateFrame("EditBox", nil, tab.levelFrame)
                tab.maxLevel:SetSize(30, 24)
                tab.maxLevel:SetPoint("LEFT", tab.levelSeparator, "RIGHT", 5, 0)
                tab.maxLevel:SetAutoFocus(false)
                tab.maxLevel:SetNumeric(true)
                tab.maxLevel:SetMaxLetters(2)
                tab.maxLevel:SetText("")
                tab.maxLevel:SetCursorPosition(0)
                tab.maxLevel:SetFontObject("ChatFontNormal")
                tab.maxLevel:SetJustifyH("CENTER")
                StyleEditBox(tab.maxLevel)

                -- Кнопки
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.filtersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.filtersFrame, "RIGHT", 0, -15)

                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.armorTypeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.armorTypeDropdown, "Не выбрано")

                    tab.slotDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.slotDropdown, "Не выбрано")

                    tab.qualityDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.qualityDropdown, "Не выбрано")

                    tab.minLevel:SetText("")
                    tab.maxLevel:SetText("")
                    tab.minLevel:SetCursorPosition(0)
                    tab.maxLevel:SetCursorPosition(0)

                    if tab.itemListContent then
                        tab.itemListContent:Hide()
                    end

                    tab:UpdateFilterButtonState()
                end)

                tab.filterButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.filterButton:SetSize(100, 22)
                tab.filterButton:SetPoint("LEFT", tab.resetButton, "RIGHT", 10, 0)
                tab.filterButton:SetText("Подобрать")
                tab.filterButton:Disable()

                tab.UpdateFilterButtonState = function()
                    local hasArmorType = HasSelectedValues(tab.armorTypeDropdown)
                    local hasSlotType = HasSelectedValues(tab.slotDropdown)
                    local hasQuality = HasSelectedValues(tab.qualityDropdown)
                    local hasLevel = tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""

                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasArmorType or hasSlotType or hasQuality or hasLevel then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end

                tab.filterButton:SetScript("OnClick", function()
                    local minLvl = tab.minLevel:GetText() ~= "" and tonumber(tab.minLevel:GetText()) or 1
                    local maxLvl = tab.maxLevel:GetText() ~= "" and tonumber(tab.maxLevel:GetText()) or 80

                    -- Определяем фильтры
                    local armorTypesToFilter = HasSelectedValues(tab.armorTypeDropdown) and
                                                   tab.armorTypeDropdown.selectedValues or nil
                    local slotTypesToFilter = HasSelectedValues(tab.slotDropdown) and tab.slotDropdown.selectedValues or
                                                  nil
                    local qualitiesToFilter = HasSelectedValues(tab.qualityDropdown) and
                                                  tab.qualityDropdown.selectedValues or nil

                    tab:FilterItems(armorTypesToFilter, slotTypesToFilter, minLvl, maxLvl, qualitiesToFilter)
                end)

                -- Назначим обработчики для полей ввода уровня
                local function UpdateOnTextChanged()
                    tab:UpdateFilterButtonState()
                end

                tab.minLevel:SetScript("OnTextChanged", UpdateOnTextChanged)
                tab.maxLevel:SetScript("OnTextChanged", UpdateOnTextChanged)

                -- Область для отображения результатов
                tab.itemList = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
                tab.itemList:SetSize(500, 250)
                tab.itemList:SetPoint("TOPLEFT", tab.filtersFrame, "BOTTOMLEFT", 0, -10)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)

                tab.initialized = true
            end

            -- Показываем элементы фильтрации
            tab.filtersFrame:Show()
            tab.buttonsFrame:Show()
            tab.itemList:Show()

            -- Функция для обновления полосы прокрутки
            tab.UpdateScrollBar = function()
                local contentHeight = tab.itemListContent:GetHeight()
                local visibleHeight = tab.itemList:GetHeight()
                if contentHeight > visibleHeight then
                    tab.itemList.ScrollBar:Show()
                else
                    tab.itemList.ScrollBar:Hide()
                end
            end

            -- Обновляем полосу прокрутки
            if tab.UpdateScrollBar then
                tab.UpdateScrollBar()
            end
        end,

        FilterItems = function(tab, armorTypes, slotTypes, minLevel, maxLevel, qualities)
            if not ItemStorageBrowser.database then
                return
            end
            if not tab.itemListContent then
                return
            end

            -- Очищаем предыдущие результаты
            tab.itemListContent:Hide()
            tab.itemListContent:SetParent(nil)
            tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
            tab.itemListContent:SetSize(500, 1)
            tab.itemList:SetScrollChild(tab.itemListContent)

            local yOffset = 0
            local hasResults = false

            -- Группируем предметы по персонажам
            local groupedResults = {}

            for _, character in ipairs(ItemStorageBrowser.database) do
                local characterItems = {}

                for _, item in ipairs(character.items) do
                    local name, link, quality, _, reqLevel, typeName, subType, _, equipLoc, _, _, itemLevel =
                        GetItemInfo(item.link)
                    if link and equipLoc and equipLoc ~= "" and equipLoc ~= "INVTYPE_BAG" then
                        local matches = true

                        -- Тип брони
                        if armorTypes then
                            local found = false
                            for selectedType, active in pairs(armorTypes) do
                                if active and string.find(subType or "", selectedType) then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                matches = false
                            end
                        end

                        -- Слот
                        if slotTypes then
                            local found = false
                            for selectedSlot, active in pairs(slotTypes) do
                                if active and equipLoc == selectedSlot then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                matches = false
                            end
                        end

                        -- Уровень
                        reqLevel = reqLevel or 0
                        if reqLevel < minLevel or reqLevel > maxLevel then
                            matches = false
                        end

                        -- Качество
                        if qualities and not qualities[quality] then
                            matches = false
                        end

                        if matches then
                            item.itemLevel = itemLevel or 0
                            table.insert(characterItems, item)
                        end
                    end
                end

                if #characterItems > 0 then
                    table.sort(characterItems, function(a, b)
                        if a.itemLevel ~= b.itemLevel then
                            return a.itemLevel < b.itemLevel
                        end
                        return a.name < b.name
                    end)
                    groupedResults[character.name] = characterItems
                    hasResults = true
                end
            end

            -- Если нет результатов, показываем сообщение
            if not hasResults then
                local noResultsText = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noResultsText:SetPoint("CENTER", tab.itemListContent, "CENTER", 0, 0)

                -- Проверяем, применены ли какие-либо фильтры
                local hasFilters = (armorTypes and next(armorTypes) ~= nil) or (slotTypes and next(slotTypes) ~= nil) or
                                       (qualities and next(qualities) ~= nil) or minLevel ~= 1 or maxLevel ~= 80
                if hasFilters then
                    noResultsText:SetText("Нет предметов, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет экипируемых предметов в хранилище")
                end
                yOffset = yOffset - 30
            else
                -- Отображаем результаты по персонажам
                for characterName, items in pairs(groupedResults) do
                    -- Заголовок с именем персонажа
                    local characterHeader = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    characterHeader:SetPoint("TOPLEFT", 0, yOffset)
                    characterHeader:SetText("Персонаж: " .. characterName)
                    yOffset = yOffset - 20

                    -- Отображаем предметы для текущего персонажа
                    for _, item in ipairs(items) do
                        local itemFrame = CreateFrame("Frame", nil, tab.itemListContent)
                        itemFrame:SetSize(500, 30)
                        itemFrame:SetPoint("TOPLEFT", 0, yOffset)

                        -- Иконка предмета
                        local itemIcon = CreateFrame("Button", nil, itemFrame)
                        itemIcon:SetSize(24, 24)
                        itemIcon:SetPoint("LEFT", itemFrame, "LEFT", 5, 0)
                        itemIcon:SetNormalTexture(GetItemIcon(item.link))
                        itemIcon:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(itemIcon, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(item.link)
                            if IsShiftKeyDown() then
                                GameTooltip_ShowCompareItem(GameTooltip)
                            end
                            GameTooltip:Show()
                        end)

                        itemIcon:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                            HideShoppingTooltips()
                        end)

                        -- Получаем цвет качества предмета
                        local quality = select(3, GetItemInfo(item.link)) or 1
                        local itemColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or
                                              "|cffffffff"

                        -- Кнопка-ссылка на предмет
                        local itemButton = CreateFrame("Button", nil, itemFrame)
                        itemButton:SetPoint("LEFT", itemIcon, "RIGHT", 10, 0)
                        itemButton:SetSize(380, 24)

                        -- Название предмета как гиперссылка с цветом качества
                        itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemButton.text:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                        itemButton.text:SetText(itemColor .. item.name .. "|r")

                        -- Всплывающая подсказка
                        itemButton:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(item.link)
                            if IsShiftKeyDown() then
                                GameTooltip_ShowCompareItem(GameTooltip)
                            end
                            GameTooltip:Show()
                        end)

                        itemButton:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                            HideShoppingTooltips()
                        end)

                        -- Вставка ссылки в чат при Shift+клике
                        itemIcon:SetScript("OnClick", function(self, button)
                            if IsShiftKeyDown() then
                                ChatEdit_InsertLink(item.link)
                            end
                        end)

                        itemButton:SetScript("OnClick", function(self, button)
                            if IsShiftKeyDown() then
                                ChatEdit_InsertLink(item.link)
                            end
                        end)

                        -- Текст количества предметов
                        local itemCountText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemCountText:SetPoint("LEFT", itemButton, "RIGHT", 10, 0)
                        itemCountText:SetText("x" .. item.count)

                        yOffset = yOffset - 30
                    end
                end
            end

            -- Обновляем высоту контента
            tab.itemListContent:SetSize(500, math.abs(yOffset))
            -- Обновляем полосу прокрутки
            if tab.UpdateScrollBar then
                tab.UpdateScrollBar()
            end
        end,

        OnDeactivate = function(tab, container)
            tab.initialized = false
            -- Очищаем содержимое при деактивации
            if tab.filtersFrame then
                tab.filtersFrame:Hide()
            end
            if tab.itemList then
                tab.itemList:Hide()
            end
            if tab.itemListContent then
                tab.itemListContent:Hide()
            end
        end
    })
end

-- Регистрируем событие для отложенной инициализации
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    RegisterArmorTab()
    self:UnregisterEvent(event)
end)

-- Вспомогательная функция: прячет окна сравнения (ShoppingTooltip1/2)
local function HideShoppingTooltips()
    for i = 1, 2 do
        local st = _G["ShoppingTooltip" .. i]
        if st and st:IsShown() then
            st:Hide()
        end
    end
end

-- Обработчик модификатора Shift: показывает сравнение при нажатии, прячет при отпускании
local tooltipCompareFrame = CreateFrame("Frame")
tooltipCompareFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

tooltipCompareFrame:SetScript("OnEvent", function(self, event, key, state)
    if key == "LSHIFT" or key == "RSHIFT" then
        if state == 1 then
            -- Shift нажат
            if GameTooltip and GameTooltip:IsShown() then
                GameTooltip_ShowCompareItem(GameTooltip)
            end
        else
            -- Shift отпущен — прячем окна сравнения
            HideShoppingTooltips()
        end
    end
end)
