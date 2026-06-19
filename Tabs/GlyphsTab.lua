local addonName, ItemStorageBrowser = ...

local function StyleEditBox(editBox)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 18, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editBox:SetBackdropColor(0, 0, 0, 0.5)
end

-- Функция для проверки, есть ли выбранные значения в дропдауне
local function HasSelectedValues(dropdown)
    if not dropdown.selectedValues then return false end
    for _, selected in pairs(dropdown.selectedValues) do
        if selected then return true end
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

-- Функция для получения типа символа (большой/малый)
local function GetGlyphSize(itemLink)
    -- Сначала пробуем получить размер из подтипа предмета, если он содержит нужную информацию.
    local _, _, _, _, _, _, itemSubType = GetItemInfo(itemLink)
    if itemSubType then
        local lowerSubType = string.lower(itemSubType)
        if string.find(lowerSubType, "больш") or string.find(lowerSubType, "major") then
            return "Большой символ"
        elseif string.find(lowerSubType, "мал") or string.find(lowerSubType, "minor") then
            return "Малый символ"
        end
    end

    -- Если ничего не получилось, используем tooltip как резерв.
    local tooltip = CreateFrame("GameTooltip", "GlyphTooltipScanner", UIParent, "GameTooltipTemplate")
    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
    tooltip:ClearLines()
    tooltip:SetHyperlink(itemLink)
    
    local glyphSize = nil
    for i = 1, tooltip:NumLines() do
        local text = _G["GlyphTooltipScannerTextLeft"..i]:GetText()
        if text then
            local lowerText = string.lower(text)
            -- Ищем строку с типом символа
            if (string.find(lowerText, "больш") and string.find(lowerText, "символ")) or string.find(lowerText, "major glyph") or string.find(lowerText, "major") then
                glyphSize = "Большой символ"
                break
            elseif (string.find(lowerText, "мал") and string.find(lowerText, "символ")) or string.find(lowerText, "minor glyph") or string.find(lowerText, "minor") then
                glyphSize = "Малый символ"
                break
            end
        end
    end
    
    tooltip:Hide()
    return glyphSize
end

local function RegisterGlyphsTab()
    -- Регистрируем вкладку символов
    ItemStorageBrowser:RegisterTab({
        name = "Символы",
        icon = "Interface\\Icons\\INV_Inscription_Tradeskill01",
        
        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Создаем элементы фильтрации
                tab.glyphsFiltersFrame = CreateFrame("Frame", nil, container)
                tab.glyphsFiltersFrame:SetSize(500, 90)
                tab.glyphsFiltersFrame:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)
                
                -- Выбор класса
                tab.classLabel = tab.glyphsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.classLabel:SetWidth(120)
                tab.classLabel:SetPoint("TOPLEFT", tab.glyphsFiltersFrame, "TOPLEFT", 0, 0)
                tab.classLabel:SetText("Класс:")
                tab.classLabel:SetFontObject("ChatFontNormal")
                tab.classLabel:SetJustifyH("CENTER")
                
                tab.classDropdown = CreateFrame("Frame", "ISB_GlyphsClassDropdown", tab.glyphsFiltersFrame, "UIDropDownMenuTemplate")
                tab.classDropdown:SetPoint("TOPLEFT", tab.classLabel, "BOTTOMLEFT", -20, -5)
                tab.classDropdown:SetWidth(150)
                tab.classDropdown.selectedValues = {}
                
                tab.classes = {
                    {text = "Воин", value = "Воин"},
                    {text = "Паладин", value = "Паладин"},
                    {text = "Охотник", value = "Охотник"},
                    {text = "Разбойник", value = "Разбойник"},
                    {text = "Жрец", value = "Жрец"},
                    {text = "Шаман", value = "Шаман"},
                    {text = "Маг", value = "Маг"},
                    {text = "Чернокнижник", value = "Чернокнижник"},
                    {text = "Друид", value = "Друид"},
                }
                
                UIDropDownMenu_Initialize(tab.classDropdown, function(self, level, menuList)
                    for _, class in ipairs(tab.classes) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = class.text
                        info.value = class.value
                        info.checked = tab.classDropdown.selectedValues[class.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.classDropdown.selectedValues[self.value] = not tab.classDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.classDropdown, tab.classes)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)
                
                UIDropDownMenu_SetText(tab.classDropdown, "Не выбрано")

                -- Выбор размера символа
                tab.sizeLabel = tab.glyphsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.sizeLabel:SetWidth(120)
                tab.sizeLabel:SetPoint("TOPLEFT", tab.glyphsFiltersFrame, "TOPLEFT", 180, 0)
                tab.sizeLabel:SetText("Размер:")
                tab.sizeLabel:SetFontObject("ChatFontNormal")
                tab.sizeLabel:SetJustifyH("CENTER")

                tab.sizeDropdown = CreateFrame("Frame", "ISB_GlyphsSizeDropdown", tab.glyphsFiltersFrame, "UIDropDownMenuTemplate")
                tab.sizeDropdown:SetPoint("TOPLEFT", tab.sizeLabel, "BOTTOMLEFT", -20, -5)
                tab.sizeDropdown:SetWidth(150)
                tab.sizeDropdown.selectedValues = {}

                tab.sizes = {
                    {text = "Большой", value = "Большой символ"},
                    {text = "Малый", value = "Малый символ"},
                }

                UIDropDownMenu_Initialize(tab.sizeDropdown, function(self, level, menuList)
                    for _, size in ipairs(tab.sizes) do
                        local info = UIDropDownMenu_CreateInfo()
                        info.text = size.text
                        info.value = size.value
                        info.checked = tab.sizeDropdown.selectedValues[size.value]
                        info.isNotRadio = true
                        info.keepShownOnClick = true
                        info.func = function(self)
                            tab.sizeDropdown.selectedValues[self.value] = not tab.sizeDropdown.selectedValues[self.value]
                            UpdateMultiSelectDropdownText(tab.sizeDropdown, tab.sizes)
                            tab:UpdateFilterButtonState()
                        end
                        UIDropDownMenu_AddButton(info)
                    end
                end)

                UIDropDownMenu_SetText(tab.sizeDropdown, "Не выбрано")
                
                -- Требуемый уровень
                tab.levelLabel = tab.glyphsFiltersFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tab.levelLabel:SetWidth(120)
                tab.levelLabel:SetPoint("TOPLEFT", tab.glyphsFiltersFrame, "TOPLEFT", 360, 0)
                tab.levelLabel:SetText("Требуемый уровень:")
                tab.levelLabel:SetFontObject("ChatFontNormal")
                tab.levelLabel:SetJustifyH("CENTER")
                
                -- Поля для уровней
                tab.levelInputFrame = CreateFrame("Frame", nil, tab.glyphsFiltersFrame)
                tab.levelInputFrame:SetSize(140, 30)
                tab.levelInputFrame:SetPoint("TOPLEFT", tab.levelLabel, "BOTTOMLEFT", 0, -5)

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
                
                -- Кнопки (расположены справа под фильтрами)
                tab.buttonsFrame = CreateFrame("Frame", nil, tab.glyphsFiltersFrame)
                tab.buttonsFrame:SetSize(400, 20)
                tab.buttonsFrame:SetPoint("TOP", tab.glyphsFiltersFrame, "RIGHT", 0, -25)
                
                tab.resetButton = CreateFrame("Button", nil, tab.buttonsFrame, "UIPanelButtonTemplate")
                tab.resetButton:SetSize(100, 22)
                tab.resetButton:SetPoint("LEFT", tab.buttonsFrame, "LEFT", 0, 0)
                tab.resetButton:SetText("Сбросить")
                tab.resetButton:SetScript("OnClick", function()
                    tab.classDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.classDropdown, "Не выбрано")
                    
                    tab.sizeDropdown.selectedValues = {}
                    UIDropDownMenu_SetText(tab.sizeDropdown, "Не выбрано")
                    
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
                    local hasClass = HasSelectedValues(tab.classDropdown)
                    local hasSize = HasSelectedValues(tab.sizeDropdown)
                    local hasLevel = tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""
                    
                    -- Кнопка активна только если есть хотя бы один выбранный фильтр
                    if hasClass or hasSize or hasLevel then
                        tab.filterButton:Enable()
                    else
                        tab.filterButton:Disable()
                    end
                end
                
                tab.filterButton:SetScript("OnClick", function()
                    local minLvl = tab.minLevel:GetText() ~= "" and tonumber(tab.minLevel:GetText()) or nil
                    local maxLvl = tab.maxLevel:GetText() ~= "" and tonumber(tab.maxLevel:GetText()) or nil
                    
                    -- Определяем фильтры
                    local classesToFilter = HasSelectedValues(tab.classDropdown) and tab.classDropdown.selectedValues or nil
                    local sizesToFilter = HasSelectedValues(tab.sizeDropdown) and tab.sizeDropdown.selectedValues or nil
                    
                    tab:FilterGlyphs(
                        classesToFilter,
                        sizesToFilter,
                        minLvl,
                        maxLvl
                    )
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
                tab.itemList:SetPoint("TOPLEFT", tab.glyphsFiltersFrame, "BOTTOMLEFT", 0, -20)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)
                
                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)
                
                tab.initialized = true
            end
            
            -- Показываем элементы фильтрации
            tab.glyphsFiltersFrame:Show()
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
        
        FilterGlyphs = function(tab, classes, sizes, minLevel, maxLevel)
            if not ItemStorageBrowser.database then return end
            if not tab.itemListContent then return end
        
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
                    local itemName, itemLink, itemQuality, _, _, itemType, itemSubType = GetItemInfo(item.link)
                    
                    -- Проверяем, является ли предмет символом
                    if itemType and (itemType == "Символы" or itemType == "Glyphs") then
                        
                        local matches = true
        
                        -- 1. Проверка класса (если выбраны классы)
                        if classes then
                            local classMatch = false
                            
                            -- Проверяем подтип предмета на соответствие классам
                            for classValue, selected in pairs(classes) do
                                if selected then
                                    -- Проверяем, содержит ли подтип предмета название класса
                                    if itemSubType and string.find(itemSubType, classValue) then
                                        classMatch = true
                                        break
                                    end
                                end
                            end
                            
                            matches = matches and classMatch
                        end
        
                        -- 2. Проверка размера символа (если выбраны размеры)
                        if matches and sizes then
                            local glyphSize = GetGlyphSize(item.link)
                            local sizeMatch = false
                            
                            for sizeValue, selected in pairs(sizes) do
                                if selected and glyphSize == sizeValue then
                                    sizeMatch = true
                                    break
                                end
                            end
                            
                            matches = matches and sizeMatch
                        end
        
                        -- 3. Проверка требуемого уровня (если указаны границы)
                        if matches and (minLevel or maxLevel) then
                            local requiredLevel = select(5, GetItemInfo(item.link)) or 0
                            
                            if minLevel and maxLevel then
                                -- Проверка диапазона
                                matches = matches and (requiredLevel >= minLevel and requiredLevel <= maxLevel)
                            elseif minLevel then
                                -- Только минимальный уровень
                                matches = matches and (requiredLevel >= minLevel)
                            elseif maxLevel then
                                -- Только максимальный уровень
                                matches = matches and (requiredLevel <= maxLevel)
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
                local hasFilters = (classes and next(classes) ~= nil) or 
                                 (sizes and next(sizes) ~= nil) or
                                 tab.minLevel:GetText() ~= "" or tab.maxLevel:GetText() ~= ""
                if hasFilters then
                    noResultsText:SetText("Нет символов, соответствующих фильтрам")
                else
                    noResultsText:SetText("Нет символов в хранилище")
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
                            GameTooltip:Show()
                        end)
                        itemIcon:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                        
                        -- Получаем цвет качества предмета
                        local quality = select(3, GetItemInfo(item.link)) or 1
                        local itemColor = ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].hex or "|cffffffff"
                        
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
            if tab.glyphsFiltersFrame then 
                tab.glyphsFiltersFrame:Hide()
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
    RegisterGlyphsTab()
    self:UnregisterEvent(event)
end)