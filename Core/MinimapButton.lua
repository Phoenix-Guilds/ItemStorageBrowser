local addonName, ItemStorageBrowser = ...

-- Ждем инициализации основного фрейма
local function InitializeMinimapButton()
    -- Создаем кнопку у мини-карты
    local miniMapButton = CreateFrame("Button", "ItemStorageBrowserMiniMapButton", Minimap)
    miniMapButton:SetSize(32, 32)
    miniMapButton:SetFrameStrata("MEDIUM")

    -- Текстура кнопки
    miniMapButton.icon = miniMapButton:CreateTexture(nil, "BACKGROUND")
    -- Попробуем загрузить пользовательский логотип из папки аддона: `ItemStorageBrowser/media/logo` (без расширения).
    -- Поместите, например, `logo.tga` в папку `Interface\AddOns\ItemStorageBrowser\media` и используйте путь ниже.
    local customLogoPath = "Interface\\AddOns\\ItemStorageBrowser\\media\\logo"
    local defaultIcon = "Interface\\Icons\\HordePandaren_64"
    miniMapButton.icon:SetSize(22, 22)
    miniMapButton.icon:SetPoint("CENTER")
    -- Попытка подмены: сначала задаём custom, затем делаем fallback на дефолтную иконку
    miniMapButton.icon:SetTexture(customLogoPath)
    -- Если по какой-то причине кастом не загружен, подменим дефолтом
    if not miniMapButton.icon:GetTexture() or miniMapButton.icon:GetTexture() == "" then
        miniMapButton.icon:SetTexture(defaultIcon)
    end

    -- Круглая рамка
    miniMapButton.overlay = miniMapButton:CreateTexture(nil, "OVERLAY")
    miniMapButton.overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    miniMapButton.overlay:SetSize(56, 56)
    miniMapButton.overlay:SetPoint("TOPLEFT", 0, 0)

    -- Функция для обновления позиции кнопки
    local function UpdateMinimapButtonPosition()
        local angle = ItemStorageBrowserDB.minimapAngle or 0
        local radius = 80
        local scale = Minimap:GetWidth() / 150
        
        local x = cos(angle) * radius * scale
        local y = sin(angle) * radius * scale
        
        miniMapButton:ClearAllPoints()
        miniMapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    -- Обработчик перетаскивания
    miniMapButton:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            px, py = px / scale, py / scale
            
            ItemStorageBrowserDB.minimapAngle = atan2(py - my, px - mx)
            UpdateMinimapButtonPosition()
        end)
    end)

    miniMapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        self:UnregisterHighlight()
    end)

    miniMapButton:RegisterForDrag("LeftButton")
    miniMapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    miniMapButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if ItemStorageBrowser.frame:IsShown() then
                ItemStorageBrowser.frame:Hide()
            else
                ItemStorageBrowser.frame:Show()
                ItemStorageBrowser.frame:SetFocus(true)
            end
        elseif button == "RightButton" then
            if not IsAddOnLoaded("Blizzard_OptionsPanels") then
                LoadAddOn("Blizzard_OptionsPanels")
            end
            if InterfaceOptionsFrame then
                InterfaceOptionsFrame:Show()
            end
            if InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Item Storage Browser")
            elseif InterfaceOptionsFrame_OpenToCategory then
                InterfaceOptionsFrame_OpenToCategory("Item Storage Browser")
            end
        end
    end)

    -- Глобальный обработчик Esc
    local function OnEscapePressed()
        if ItemStorageBrowser.frame:IsShown() then
            ItemStorageBrowser.frame:Hide()
            return true -- Блокируем дальнейшую обработку Esc
        end
        return false
    end

    -- Регистрируем обработчик Esc
    tinsert(UISpecialFrames, "ItemStorageBrowserFrame") -- Добавляем в стандартные фреймы для закрытия по Esc

    -- Альтернативный вариант обработки Esc через хук
    hooksecurefunc("CloseSpecialWindows", function()
        if ItemStorageBrowser.frame:IsShown() then
            ItemStorageBrowser.frame:Hide()
        end
    end)

    miniMapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Складской аддон гильдии Phoenix Nest", 1, 1, 1)
        GameTooltip:AddLine("Левый клик - открыть/закрыть аддон", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Правый клик - открыть настройки", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)

    miniMapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Инициализация позиции кнопки
    UpdateMinimapButtonPosition()

    -- Обновляем позицию при изменении размера мини-карты
    Minimap:HookScript("OnSizeChanged", UpdateMinimapButtonPosition)
end

-- Регистрируем событие для отложенной инициализации
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    InitializeMinimapButton()
    self:UnregisterEvent(event)
end)