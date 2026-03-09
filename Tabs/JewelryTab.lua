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

local function RegisterJewelryTab()
    -- Регистрируем вкладку бижутерии
    ItemStorageBrowser:RegisterTab({
        name = "Бижутерия и фетиши",
        icon = "Interface\\Icons\\INV_Jewelry_Ring_85",

        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.jewelryFiltersFrame = CreateFrame("Frame", nil, container)
                tab.jewelryFiltersFrame:SetSize(500, 60)
                tab.jewelryFiltersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)

                -- Выбор типа предмета
                tab.typeLabel = tab.jewelryFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.typeLabel:SetWidth(120)
                tab.typeLabel:SetPoint("TOPLEFT", tab.jewelryFiltersFrame, "TOPLEFT", 0, 0)
                tab.typeLabel:SetText("Тип:")
                tab.typeLabel:SetFontObject("ChatFontNormal")
                tab.typeLabel:SetJustifyH("CENTER")

                tab.typeDropdown = CreateFrame("Frame", "ISB_JewelryTypeDropdown", tab.jewelryFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.typeDropdown:SetPoint("TOPLEFT", tab.typeLabel, "BOTTOMLEFT", -20, -5)
                tab.typeDropdown:SetWidth(150)
                tab.typeDropdown.selectedValues = {}

                tab.types = {{
                    text = "Шея",
                    value = "INVTYPE_NECK"
                }, {
                    text = "Кольцо",
                    value = "INVTYPE_FINGER"
                }, {
                    text = "Аксессуар",
                    value = "INVTYPE_TRINKET"
                }, {
                    text = "Левая рука",
                    value = "INVTYPE_HOLDABLE"
                }, {
                    text = "Тотем",
                    value = "Тотем"
                }, {
                    text = "Манускрипт",
                    value = "Манускрипт"
                }, {
                    text = "Идол",
                    value = "Идол"
                }}

                UIDropDownMenu_Initialize(tab.typeDropdown, function(self, level, menuList)
                    for _, itemType in ipairs(tab.types) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = itemType.text
                        info.value = itemType.value
                        info.checked = tab.typeDropdown.selectedValues[itemType.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.typeDropdown.selectedValues[self.value] =
                                not tab.typeDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.typeDropdown, tab.types)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

                -- Выбор качества
                tab.qualityLabel = tab.jewelryFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.qualityLabel:SetWidth(120)
                tab.qualityLabel:SetPoint("TOPLEFT", tab.jewelryFiltersFrame, "TOPLEFT", 180, 0)
                tab.qualityLabel:SetText("Качество:")
                tab.qualityLabel:SetFontObject("ChatFontNormal")
                tab.qualityLabel:SetJustifyH("CENTER")

                tab.qualityDropdown = CreateFrame("Frame", "ISB_JewelryQualityDropdown", tab.jewelryFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.qualityDropdown:SetPoint("TOPLEFT", tab.qualityLabel, "BOTTOMLEFT", -20, -5)
                tab.qualityDropdown:SetWidth(150)
                tab.qualityDropdown.selectedValues = {}

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
                tab.levelLabel = tab.jewelryFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.levelLabel:SetWidth(120)
                tab.levelLabel:SetPoint("TOPLEFT", tab.jewelryFiltersFrame, "TOPLEFT", 360, 0)
                tab.levelLabel:SetText("Уровень:")
                tab.levelLabel:SetFontObject("ChatFontNormal")
                tab.levelLabel:SetJustifyH("CENTER")

                -- Поля для уровней
                tab.levelInputFrame = CreateFrame("Frame", nil, tab.jewelryFiltersFrame)
                tab.levelInputFrame:SetSize(140, 30)
                tab.levelInputFrame:SetPoint("TOPLEFT", tab.levelLabel, "BOTTOMLEFT", 0, -5)

                tab.minLevel = CreateFrame("EditBox", nil, tab.levelInputFrame)
                tab.minLevel:SetSize(30, 24)
                tab.minLevel:SetPoint("LEFT", tab.levelInputFrame, "LEFT", 20, 0)
                tab.minLevel:SetAutoFocus(false)
                tab.minLevel:SetNumeric(true)
                tab.minLevel:SetMaxLetters(2)
                tab.minLevel:SetText("")
                tab.minLevel:SetCursorPosition(0)
                tab.minLevel:SetFontObject("ChatFontNormal")
                tab.minLevel:SetJustifyH("CENTER")
                StyleEditBox(tab.minLevel)

                tab.levelSeparator = tab.levelInputFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tab.levelSeparator:SetPoint("LEFT", tab.minLevel, "RIGHT", 5, 0)
                tab.levelSeparator:SetText("-")
                tab.levelSeparator:SetTextColor(1, 1, 1, 0.7)

                tab.maxLevel = CreateFrame("EditBox", nil, tab.levelInputFrame)
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

                -- Кнопки (расположены справа под фильтрами)
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.jewelryFiltersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.jewelryFiltersFrame, "RIGHT", 0, -25)

                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.typeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

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
                    local hasType = HasSelectedValues(tab.typeDropdown)
                    local hasQuality = HasSelectedValues(tab.qualityDropdown)
                    local hasLevel = tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""

                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasType or hasQuality or hasLevel then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end

                tab.filterButton:SetScript("OnClick", function()
                    local minLvl = tab.minLevel:GetText() ~= "" and tonumber(tab.minLevel:GetText()) or 1
                    local maxLvl = tab.maxLevel:GetText() ~= "" and tonumber(tab.maxLevel:GetText()) or 80

                    -- Определяем фильтры
                    local typesToFilter = HasSelectedValues(tab.typeDropdown) and tab.typeDropdown.selectedValues or nil
                    local qualitiesToFilter = HasSelectedValues(tab.qualityDropdown) and
                                                  tab.qualityDropdown.selectedValues or nil

                    tab:FilterItems(typesToFilter, minLvl, maxLvl, qualitiesToFilter)
                end)

                -- Назначим обработчики для полей ввода уровня
                local function UpdateOnTextChanged()
                    tab:UpdateFilterButtonState()
                end

                tab.minLevel:SetScript("OnTextChanged", UpdateOnTextChanged)
                tab.maxLevel:SetScript("OnTextChanged", UpdateOnTextChanged)

                -- Область для отображения результатов
                tab.itemList = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
                tab.itemList:SetSize(500, 300)
                tab.itemList:SetPoint("TOPLEFT", tab.jewelryFiltersFrame, "BOTTOMLEFT", 0, -20)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)

                tab.initialized = true
            end

            -- Показываем элементы фильтрации
            tab.jewelryFiltersFrame:Show()
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

        FilterItems = function(tab, types, minLevel, maxLevel, qualities)
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
                    local itemName, itemLink, _, _, requiredLevel, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(
                        item.link)
                    local _, _, itemQuality = GetItemInfo(item.link)

                    -- Проверяем, относится ли предмет к бижутерии или фетишам
                    if itemEquipLoc and ( -- Бижутерия
                    itemEquipLoc == "INVTYPE_NECK" or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc ==
                        "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_HOLDABLE" or itemSubType == "Тотемы" or
                        itemSubType == "Манускрипты" or itemSubType == "Идолы") then

                        local matches = true

                        -- Проверка типа предмета (если есть выбранные типы)
                        if types then
                            local typeMatch = false

                            -- Проверяем соответствие equipLoc для бижутерии
                            if types[itemEquipLoc] then
                                typeMatch = true
                            end

                            -- Для реликвий проверяем подтип
                            if not typeMatch and types["Тотем"] and itemSubType == "Тотемы" then
                                typeMatch = true
                            end
                            if not typeMatch and types["Манускрипт"] and itemSubType ==
                                "Манускрипты" then
                                typeMatch = true
                            end
                            if not typeMatch and types["Идол"] and itemSubType == "Идолы" then
                                typeMatch = true
                            end

                            if not typeMatch then
                                matches = false
                            end
                        end

                        -- Проверка уровня
                        requiredLevel = requiredLevel or 0
                        if requiredLevel < minLevel or requiredLevel > maxLevel then
                            matches = false
                        end

                        -- Проверка качества (если есть выбранные качества)
                        if qualities then
                            if not itemQuality or not qualities[itemQuality] then
                                matches = false
                            end
                        end

                        if matches then
                            -- Получаем уровень предмета
                            local _, _, _, itemLevel, _, _, _, _, _, _, _, _ = GetItemInfo(item.link)
                            item.itemLevel = itemLevel or 0 -- Если не удалось получить уровень, используем 0

                            -- Вставляем предмет в таблицу с сохранением уровня
                            table.insert(characterItems, item)
                        end
                    end
                end

                if #characterItems > 0 then
                    table.sort(characterItems, function(a, b)
                        -- Сначала сортируем по уровню (по возрастанию)
                        if a.itemLevel ~= b.itemLevel then
                            return a.itemLevel < b.itemLevel
                        end
                        -- Если уровни равны, сортируем по названию (по алфавиту)
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
                local hasFilters =
                    (types and next(types) ~= nil) or (qualities and next(qualities) ~= nil) or minLevel ~= 1 or
                        maxLevel ~= 80
                if hasFilters then
                    noResultsText:SetText("Нет предметов, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет бижутерии и фетишей в хранилище")
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
            if tab.jewelryFiltersFrame then
                tab.jewelryFiltersFrame:Hide()
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
    RegisterJewelryTab()
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
