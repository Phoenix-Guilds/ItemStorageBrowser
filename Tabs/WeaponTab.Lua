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

local function RegisterWeaponTab()
    -- Регистрируем вкладку оружия
    ItemStorageBrowser:RegisterTab({
        name = "Оружие",
        icon = "Interface\\Icons\\INV_Sword_04",

        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.weaponFiltersFrame = CreateFrame("Frame", nil, container)
                tab.weaponFiltersFrame:SetSize(500, 80)
                tab.weaponFiltersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)

                -- Выбор руки
                tab.handLabel = tab.weaponFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.handLabel:SetWidth(130)
                tab.handLabel:SetPoint("TOPLEFT", tab.weaponFiltersFrame, "TOPLEFT", 0, 0)
                tab.handLabel:SetText("Рука:")
                tab.handLabel:SetFontObject("ChatFontNormal")
                tab.handLabel:SetJustifyH("CENTER")

                tab.handDropdown = CreateFrame("Frame", "ISB_HandDropdown", tab.weaponFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.handDropdown:SetPoint("TOPLEFT", tab.handLabel, "BOTTOMLEFT", -20, -5)
                tab.handDropdown:SetWidth(160)
                tab.handDropdown.selectedValues = {}

                tab.hands = {{
                    text = "Правая рука",
                    value = "INVTYPE_WEAPONMAINHAND"
                }, {
                    text = "Левая рука",
                    value = "INVTYPE_WEAPONOFFHAND"
                }, {
                    text = "Двуручное",
                    value = "INVTYPE_2HWEAPON"
                }, {
                    text = "Одноручное",
                    value = "INVTYPE_WEAPON"
                }, {
                    text = "Дальний бой",
                    value = "INVTYPE_RANGED"
                }, {
                    text = "Метательное",
                    value = "INVTYPE_THROWN"
                }, {
                    text = "Боеприпасы",
                    value = "INVTYPE_AMMO"
                } -- Добавлен тип для боеприпасов
                }

                UIDropDownMenu_Initialize(tab.handDropdown, function(self, level, menuList)
                    for _, hand in ipairs(tab.hands) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = hand.text
                        info.value = hand.value
                        info.checked = tab.handDropdown.selectedValues[hand.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.handDropdown.selectedValues[self.value] =
                                not tab.handDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.handDropdown, tab.hands)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.handDropdown, "Не выбрано")

                -- Выбор вида оружия
                tab.weaponTypeLabel = tab.weaponFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.weaponTypeLabel:SetWidth(150)
                tab.weaponTypeLabel:SetPoint("LEFT", tab.handLabel, "RIGHT", 0, 0)
                tab.weaponTypeLabel:SetText("Вид оружия:")
                tab.weaponTypeLabel:SetFontObject("ChatFontNormal")
                tab.weaponTypeLabel:SetJustifyH("CENTER")

                tab.weaponTypeDropdown = CreateFrame("Frame", "ISB_WeaponTypeDropdown", tab.weaponFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.weaponTypeDropdown:SetPoint("TOPLEFT", tab.weaponTypeLabel, "BOTTOMLEFT", -20, -5)
                tab.weaponTypeDropdown:SetWidth(160)
                tab.weaponTypeDropdown.selectedValues = {}

                tab.weaponTypes = {{
                    text = "Одноручные топоры",
                    value = "Одноручные топоры"
                }, {
                    text = "Двуручные топоры",
                    value = "Двуручные топоры"
                }, {
                    text = "Луки",
                    value = "Луки"
                }, {
                    text = "Арбалеты",
                    value = "Арбалеты"
                }, {
                    text = "Кистевое",
                    value = "Кистевое"
                }, {
                    text = "Кинжалы",
                    value = "Кинжалы"
                }, {
                    text = "Одноручное дробящее",
                    value = "Одноручное дробящее"
                }, {
                    text = "Двуручное дробящее",
                    value = "Двуручное дробящее"
                }, {
                    text = "Одноручные мечи",
                    value = "Одноручные мечи"
                }, {
                    text = "Двуручные мечи",
                    value = "Двуручные мечи"
                }, {
                    text = "Посохи",
                    value = "Посохи"
                }, {
                    text = "Древковое",
                    value = "Древковое"
                }, {
                    text = "Жезлы",
                    value = "Жезлы"
                }, {
                    text = "Огнестрельное",
                    value = "Огнестрельное"
                }, {
                    text = "Метательное",
                    value = "Метательное"
                }, {
                    text = "Стрелы",
                    value = "Стрелы"
                }, -- Добавлены боеприпасы
                {
                    text = "Пули",
                    value = "Пули"
                } -- Добавлены боеприпасы
                }

                UIDropDownMenu_Initialize(tab.weaponTypeDropdown, function(self, level, menuList)
                    for _, weaponType in ipairs(tab.weaponTypes) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = weaponType.text
                        info.value = weaponType.value
                        info.checked = tab.weaponTypeDropdown.selectedValues[weaponType.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.weaponTypeDropdown.selectedValues[self.value] = not tab.weaponTypeDropdown
                                                                                    .selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.weaponTypeDropdown, tab.weaponTypes)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.weaponTypeDropdown, "Не выбрано")

                -- Выбор качества
                tab.weaponQualityLabel = tab.weaponFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.weaponQualityLabel:SetWidth(130)
                tab.weaponQualityLabel:SetPoint("LEFT", tab.weaponTypeLabel, "RIGHT", 0, 0)
                tab.weaponQualityLabel:SetText("Качество:")
                tab.weaponQualityLabel:SetFontObject("ChatFontNormal")
                tab.weaponQualityLabel:SetJustifyH("CENTER")

                tab.weaponQualityDropdown = CreateFrame("Frame", "ISB_WeaponQualityDropdown", tab.weaponFiltersFrame,
                    "UIDropDownMenuTemplate")
                tab.weaponQualityDropdown:SetWidth(160)
                tab.weaponQualityDropdown:SetPoint("TOPLEFT", tab.weaponQualityLabel, "BOTTOMLEFT", -20, -5)
                tab.weaponQualityDropdown.selectedValues = {}

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

                UIDropDownMenu_Initialize(tab.weaponQualityDropdown, function(self, level, menuList)
                    for _, quality in ipairs(tab.qualities) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = quality.text
                        info.value = quality.value
                        info.checked = tab.weaponQualityDropdown.selectedValues[quality.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.weaponQualityDropdown.selectedValues[self.value] = not tab.weaponQualityDropdown
                                                                                       .selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.weaponQualityDropdown, tab.qualities)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.weaponQualityDropdown, "Не выбрано")

                -- Уровень персонажа
                tab.levelFrame = CreateFrame("Frame", nil, tab.weaponFiltersFrame)
                tab.levelFrame:SetSize(150, 30)
                tab.levelFrame:SetPoint("TOPLEFT", tab.weaponQualityLabel, "BOTTOMLEFT", 20, -5)

                tab.levelLabel = tab.levelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.levelLabel:SetWidth(130)
                tab.levelLabel:SetPoint("LEFT", tab.weaponQualityLabel, "RIGHT", 0, 0)
                tab.levelLabel:SetFontObject("ChatFontNormal")
                tab.levelLabel:SetJustifyH("CENTER")
                tab.levelLabel:SetText("Уровень:")

                -- Поля для уровней
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
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.weaponFiltersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.weaponFiltersFrame, "RIGHT", 0, -15)

                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.handDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.handDropdown, "Не выбрано")

                    tab.weaponTypeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.weaponTypeDropdown, "Не выбрано")

                    tab.weaponQualityDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.weaponQualityDropdown, "Не выбрано")

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
                    local hasHandType = HasSelectedValues(tab.handDropdown)
                    local hasWeaponType = HasSelectedValues(tab.weaponTypeDropdown)
                    local hasQuality = HasSelectedValues(tab.weaponQualityDropdown)
                    local hasLevel = tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""

                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasHandType or hasWeaponType or hasQuality or hasLevel then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end

                tab.filterButton:SetScript("OnClick", function()
                    local minLvl = tab.minLevel:GetText() ~= "" and tonumber(tab.minLevel:GetText()) or 1
                    local maxLvl = tab.maxLevel:GetText() ~= "" and tonumber(tab.maxLevel:GetText()) or 80

                    -- Определяем фильтры
                    local handTypesToFilter = HasSelectedValues(tab.handDropdown) and tab.handDropdown.selectedValues or
                                                  nil
                    local weaponTypesToFilter = HasSelectedValues(tab.weaponTypeDropdown) and
                                                    tab.weaponTypeDropdown.selectedValues or nil
                    local qualitiesToFilter = HasSelectedValues(tab.weaponQualityDropdown) and
                                                  tab.weaponQualityDropdown.selectedValues or nil

                    tab:FilterItems(handTypesToFilter, weaponTypesToFilter, minLvl, maxLvl, qualitiesToFilter)
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
                tab.itemList:SetPoint("TOPLEFT", tab.weaponFiltersFrame, "BOTTOMLEFT", 0, -10)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)

                tab.initialized = true
            end

            -- Показываем элементы фильтрации
            tab.weaponFiltersFrame:Show()
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

        FilterItems = function(tab, handTypes, weaponTypes, minLevel, maxLevel, qualities)
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

                    if itemEquipLoc and
                        (itemEquipLoc == "INVTYPE_WEAPON" or itemEquipLoc == "INVTYPE_WEAPONMAINHAND" or itemEquipLoc ==
                            "INVTYPE_WEAPONOFFHAND" or itemEquipLoc == "INVTYPE_2HWEAPON" or itemEquipLoc ==
                            "INVTYPE_RANGED" or itemEquipLoc == "INVTYPE_RANGEDRIGHT" or itemEquipLoc ==
                            "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_AMMO") then -- Добавлена проверка для боеприпасов

                        local matches = true

                        -- Проверка типа руки (если есть выбранные типы)
                        if handTypes then
                            if not handTypes[itemEquipLoc] then
                                matches = false
                            end
                        end

                        -- Проверка типа оружия (если есть выбранные типы)
                        if weaponTypes then
                            if not weaponTypes[itemSubType] then
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
                    (handTypes and next(handTypes) ~= nil) or (weaponTypes and next(weaponTypes) ~= nil) or
                        (qualities and next(qualities) ~= nil) or minLevel ~= 1 or maxLevel ~= 80

                if hasFilters then
                    noResultsText:SetText(
                        "Нет оружия или боеприпасов, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет оружия или боеприпасов в хранилище")
                end
                yOffset = yOffset - 30
            else
                -- Отображаем результаты по персонажам
                for characterName, items in pairs(groupedResults) do
                    local characterHeader = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    characterHeader:SetPoint("TOPLEFT", 0, yOffset)
                    characterHeader:SetText("Персонаж: " .. characterName)
                    yOffset = yOffset - 20

                    for _, item in ipairs(items) do
                        local itemFrame = CreateFrame("Frame", nil, tab.itemListContent)
                        itemFrame:SetSize(500, 30)
                        itemFrame:SetPoint("TOPLEFT", 0, yOffset)

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

                        local quality = select(3, GetItemInfo(item.link)) or 1
                        local itemColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or
                                              "|cffffffff"

                        local itemButton = CreateFrame("Button", nil, itemFrame)
                        itemButton:SetPoint("LEFT", itemIcon, "RIGHT", 10, 0)
                        itemButton:SetSize(380, 24)

                        itemButton.text = itemButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        itemButton.text:SetPoint("LEFT", itemButton, "LEFT", 0, 0)
                        itemButton.text:SetText(itemColor .. item.name .. "|r")

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
            if tab.weaponFiltersFrame then
                tab.weaponFiltersFrame:Hide()
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
    RegisterWeaponTab()
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
