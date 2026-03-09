local addonName, ItemStorageBrowser = ...

-- Ждем инициализации системы вкладок
local function RegisterSearchTab()
    -- Регистрируем вкладку поиска
    ItemStorageBrowser:RegisterTab({
        name = "Поиск по названию",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_03",

        OnActivate = function(tab, container)
            -- Создаем элементы только если они еще не созданы
            if not tab.initialized then
                -- Поле поиска
                tab.searchBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
                tab.searchBox:SetSize(430, 20)
                tab.searchBox:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -10)
                tab.searchBox:SetAutoFocus(false)
                tab.searchBox:SetScript("OnEnterPressed", function()
                    tab:SearchItems(tab.searchBox:GetText())
                end)

                -- Кнопка поиска
                tab.searchButton = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
                tab.searchButton:SetSize(80, 22)
                tab.searchButton:SetPoint("LEFT", tab.searchBox, "RIGHT", 10, -1)
                tab.searchButton:SetText("Найти")
                tab.searchButton:SetScript("OnClick", function()
                    tab:SearchItems(tab.searchBox:GetText())
                end)

                -- Список результатов
                tab.itemList = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
                tab.itemList:SetSize(500, 300)
                tab.itemList:SetPoint("TOPLEFT", container, "TOPLEFT", 10, -40)
                tab.itemList:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -30, 10)

                tab.itemListContent = CreateFrame("Frame", nil, tab.itemList)
                tab.itemListContent:SetSize(500, 1)
                tab.itemList:SetScrollChild(tab.itemListContent)

                -- Текст по умолчанию
                tab.initialText = tab.itemListContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                tab.initialText:SetWidth(480)
                tab.initialText:SetSpacing(4)
                tab.initialText:SetPoint("TOP", tab.itemListContent, "TOP", 0, -10)
                tab.initialText:SetPoint("LEFT", tab.itemListContent, "LEFT", 10, 0)
                tab.initialText:SetPoint("RIGHT", tab.itemListContent, "RIGHT", -10, 0)
                tab.initialText:SetText(
                    "Введите частично или полностью название предмета, нажмите кнопку \"Найти\" или клавишу \"Enter\" (\"Ввод\").\n\nЕсли Вам нужно подобрать предмет по его типу или качеству, уровню и т.п. параметрам - используйте кнопки-вкладки слева: Броня, Оружие и т.д.")
                tab.initialText:SetJustifyH("CENTER")
                tab.initialText:SetJustifyV("CENTER")
                tab.initialText:SetWordWrap(true) -- Включаем перенос слов
                tab.initialText:SetNonSpaceWrap(true) -- Разрешаем перенос длинных слов без пробелов

                tab.initialized = true
            end

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

            -- Показываем начальное сообщение
            if tab.initialText then
                tab.initialText:Show()
            end
        end,

        SearchItems = function(tab, query)
            if not ItemStorageBrowser.database then
                return
            end
            if not tab.itemListContent then
                return
            end

            -- Скрываем начальное сообщение
            if tab.initialText then
                tab.initialText:Hide()
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
                    if string.find(string.lower(item.name), string.lower(query)) then
                        -- Получаем уровень предмета
                        local _, _, _, itemLevel, _, _, _, _, _, _, _, _ = GetItemInfo(item.link)
                        item.itemLevel = itemLevel or 0 -- Если не удалось получить уровень, используем 0
                        table.insert(characterItems, item)
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
                noResultsText:SetText("Поиск: \"" .. query .. "\" не дал результатов")
                noResultsText:SetJustifyH("CENTER")
                noResultsText:SetJustifyV("CENTER")
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
            -- Не уничтожаем элементы, а просто скрываем
            if tab.searchBox then
                tab.searchBox:Hide()
            end
            if tab.searchButton then
                tab.searchButton:Hide()
            end
            if tab.itemList then
                tab.itemList:Hide()
            end
            if tab.initialText then
                tab.initialText:Hide()
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
    RegisterSearchTab()
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
