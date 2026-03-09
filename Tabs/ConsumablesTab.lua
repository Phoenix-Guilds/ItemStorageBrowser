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
                    table.insert(selectedTexts, option.text)
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

local function RegisterConsumablesTab()
    -- Регистрируем вкладку расходуемых предметов
    ItemStorageBrowser:RegisterTab({
        name = "Расходуемые",
        icon = "Interface\\Icons\\INV_Potion_93",

        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.consumablesFiltersFrame = CreateFrame("Frame", nil, container)
                tab.consumablesFiltersFrame:SetSize(500, 60)
                tab.consumablesFiltersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)

                -- Выбор типа расходуемого
                tab.typeLabel = tab.consumablesFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.typeLabel:SetWidth(120)
                tab.typeLabel:SetPoint("TOPLEFT", tab.consumablesFiltersFrame, "TOPLEFT", 0, 0)
                tab.typeLabel:SetText("Тип:")
                tab.typeLabel:SetFontObject("ChatFontNormal")
                tab.typeLabel:SetJustifyH("CENTER")

                tab.typeDropdown = CreateFrame("Frame", "ISB_ConsumablesTypeDropdown", tab.consumablesFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.typeDropdown:SetPoint("TOPLEFT", tab.typeLabel, "BOTTOMLEFT", -20, -2)
                tab.typeDropdown:SetWidth(150)
                tab.typeDropdown.selectedValues = {}

                tab.types = {{
                    text = "Еда и напитки",
                    value = "FoodDrink"
                }, {
                    text = "Зелья",
                    value = "Potion"
                }, {
                    text = "Эликсиры",
                    value = "Elixir"
                }, {
                    text = "Настойки",
                    value = "Flask"
                }, {
                    text = "Улучшения",
                    value = "Buff"
                }, {
                    text = "Свитки",
                    value = "Scroll"
                }, {
                    text = "Другое",
                    value = "Other"
                }}

                UIDropDownMenu_Initialize(tab.typeDropdown, function(self, level, menuList)
                    for _, type in ipairs(tab.types) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = type.text
                        info.value = type.value
                        info.checked = tab.typeDropdown.selectedValues[type.value]
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

                -- Требуемый уровень
                tab.levelLabel = tab.consumablesFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.levelLabel:SetWidth(140)
                tab.levelLabel:SetPoint("TOPLEFT", tab.consumablesFiltersFrame, "TOPLEFT", 180, 0)
                tab.levelLabel:SetText("Требуемый уровень:")
                tab.levelLabel:SetFontObject("ChatFontNormal")
                tab.levelLabel:SetJustifyH("CENTER")

                -- Поля для уровней
                tab.levelInputFrame = CreateFrame("Frame", nil, tab.consumablesFiltersFrame)
                tab.levelInputFrame:SetSize(140, 30)
                tab.levelInputFrame:SetPoint("TOPLEFT", tab.levelLabel, "BOTTOMLEFT", 0, -2)

                tab.minLevel = CreateFrame("EditBox", nil, tab.levelInputFrame)
                tab.minLevel:SetSize(40, 24)
                tab.minLevel:SetPoint("LEFT", tab.levelInputFrame, "LEFT", 15, 0)
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
                tab.maxLevel:SetSize(40, 24)
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
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.consumablesFiltersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.consumablesFiltersFrame, "RIGHT", 0, -15)

                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.typeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.typeDropdown, "Не выбрано")

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
                    local hasLevel = tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""

                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasType or hasLevel then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end

                tab.filterButton:SetScript("OnClick", function()
                    local minLevel = tab.minLevel:GetText() ~= "" and tonumber(tab.minLevel:GetText()) or nil
                    local maxLevel = tab.maxLevel:GetText() ~= "" and tonumber(tab.maxLevel:GetText()) or nil

                    -- Определяем фильтры
                    local typesToFilter = HasSelectedValues(tab.typeDropdown) and tab.typeDropdown.selectedValues or nil

                    tab:FilterItems(typesToFilter, minLevel, maxLevel)
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
                tab.itemList:SetPoint("TOPLEFT", tab.consumablesFiltersFrame, "BOTTOMLEFT", 0, -10)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)

                tab.initialized = true
            end

            -- Показываем элементы фильтрации
            tab.consumablesFiltersFrame:Show()
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

        FilterItems = function(tab, types, minLevel, maxLevel)
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

            -- Группируем предметы по категориям и персонажам
            local categorizedResults = {
                ["Еда и напитки"] = {},
                ["Зелья"] = {},
                ["Эликсиры"] = {},
                ["Настойки"] = {},
                ["Улучшения"] = {},
                ["Свитки"] = {},
                ["Другое"] = {}
            }

            for _, character in ipairs(ItemStorageBrowser.database) do
                for _, item in ipairs(character.items) do
                    -- Получаем полную информацию о предмете
                    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(
                        item.link)

                    if itemName then
                        -- Проверяем, является ли предмет расходуемым по типу и подтипу
                        local isConsumable = false
                        local category = "Другое"

                        -- Проверяем подтипы расходуемых предметов
                        if itemSubType == "Еда и напитки" then
                            isConsumable = true
                            category = "Еда и напитки"
                        elseif itemSubType == "Зелья" then
                            isConsumable = true
                            category = "Зелья"
                        elseif itemSubType == "Эликсиры" then
                            isConsumable = true
                            category = "Эликсиры"
                        elseif itemSubType == "Настойки" then
                            isConsumable = true
                            category = "Настойки"
                        elseif itemSubType == "Улучшения" or itemSubType == "Боевые эликсиры" or
                            itemSubType == "Сторожевые эликсиры" then
                            isConsumable = true
                            category = "Улучшения"
                        elseif itemSubType == "Свитки" then
                            isConsumable = true
                            category = "Свитки"
                        elseif itemSubType == "Расходуемые" or itemSubType == "Другое" then
                            isConsumable = true
                            category = "Другое"
                        end

                        if isConsumable then
                            local matches = true

                            -- 1. Проверка типа расходуемого (если выбраны типы)
                            if types then
                                local typeMatch = false

                                for typeValue, selected in pairs(types) do
                                    if selected then
                                        if typeValue == "FoodDrink" and category == "Еда и напитки" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Potion" and category == "Зелья" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Elixir" and category == "Эликсиры" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Flask" and category == "Настойки" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Buff" and category == "Улучшения" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Scroll" and category == "Свитки" then
                                            typeMatch = true
                                            break
                                        elseif typeValue == "Other" and category == "Другое" then
                                            typeMatch = true
                                            break
                                        end
                                    end
                                end

                                matches = matches and typeMatch
                            end

                            -- 2. Проверка требуемого уровня (если указаны границы)
                            if matches and (minLevel or maxLevel) then
                                itemMinLevel = itemMinLevel or 0

                                if minLevel and maxLevel then
                                    -- Проверка диапазона
                                    matches = matches and (itemMinLevel >= minLevel and itemMinLevel <= maxLevel)
                                elseif minLevel then
                                    -- Только минимальный уровень
                                    matches = matches and (itemMinLevel >= minLevel)
                                elseif maxLevel then
                                    -- Только максимальный уровень
                                    matches = matches and (itemMinLevel <= maxLevel)
                                end
                            end

                            if matches then
                                -- Добавляем информацию о персонаже к предмету
                                local itemWithChar = {
                                    name = item.name,
                                    link = item.link,
                                    count = item.count,
                                    character = character.name,
                                    itemLevel = itemMinLevel or 0,
                                    category = category
                                }

                                table.insert(categorizedResults[category], itemWithChar)
                            end
                        end
                    end
                end
            end

            -- Сортируем предметы внутри категорий по уровню (по убыванию) и затем по названию
            for category, items in pairs(categorizedResults) do
                table.sort(items, function(a, b)
                    if a.itemLevel ~= b.itemLevel then
                        return a.itemLevel > b.itemLevel
                    end
                    return a.name < b.name
                end)
            end

            -- Отображаем результаты по категориям
            for categoryName, items in pairs(categorizedResults) do
                if #items > 0 then
                    hasResults = true

                    -- Заголовок категории
                    local categoryHeader = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    categoryHeader:SetPoint("TOPLEFT", 0, yOffset)
                    categoryHeader:SetText(categoryName)
                    categoryHeader:SetTextColor(1, 0.82, 0) -- Золотой цвет для заголовков
                    yOffset = yOffset - 20

                    -- Отображаем предметы для текущей категории
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
                            GameTooltip:Show()
                        end)
                        itemIcon:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)

                        -- Получаем цвет качества предмета
                        local quality = select(3, GetItemInfo(item.link)) or 1
                        local itemColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or
                                              "|cffffffff"

                        -- Кнопка-ссылка на предмет
                        local itemButton = CreateFrame("Button", nil, itemFrame)
                        itemButton:SetPoint("LEFT", itemIcon, "RIGHT", 10, 0)
                        itemButton:SetSize(400, 24)

                        -- Название предмета как гиперссылка с цветом качества
                        itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemButton.text:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                        itemButton.text:SetText(itemColor .. item.name .. "|r")

                        -- Всплывающая подсказка
                        itemButton:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(itemButton, "ANCHOR_RIGHT")
                            GameTooltip:SetHyperlink(item.link)
                            GameTooltip:Show()
                        end)
                        itemButton:SetScript("OnLeave", function()
                            GameTooltip:Hide()
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

                    -- Добавляем отступ между категориями
                    yOffset = yOffset - 10
                end
            end

            -- Если нет результатов, показываем сообщение
            if not hasResults then
                local noResultsText = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                noResultsText:SetPoint("CENTER", tab.itemListContent, "CENTER", 0, 0)

                -- Проверяем, применены ли какие-либо фильтры
                local hasFilters = (types and next(types) ~= nil) or tab.minLevel:GetText() ~= "" or
                                       tab.maxLevel:GetText() ~= ""
                if hasFilters then
                    noResultsText:SetText(
                        "Нет расходуемых предметов, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет расходуемых предметов в хранилище")
                end
                yOffset = yOffset - 30
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
            if tab.consumablesFiltersFrame then
                tab.consumablesFiltersFrame:Hide()
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

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    RegisterConsumablesTab()
    self:UnregisterEvent(event)
end)
