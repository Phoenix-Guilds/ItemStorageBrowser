local addonName, ItemStorageBrowser = ...

-- Инициализация DB для параметров
ItemStorageBrowserDB = ItemStorageBrowserDB or {
    minimapAngle = 148.2497927517446,
    transparency = 1,
}

-- Создаем панель параметров с правильной регистрацией
local panel = CreateFrame("Frame", "ItemStorageBrowserOptionsPanel", UIParent)
panel.name = "Item Storage Browser"

-- Функции okay() и cancel() должны быть переопределены после создания слайдера
panel.okay = function(self)
    if self.transparencySlider then
        local value = self.transparencySlider:GetValue()
        ItemStorageBrowserDB.transparency = value / 10  -- Преобразуем обратно
    end
    if ItemStorageBrowser.frame then
        ItemStorageBrowser:SetFrameTransparency(ItemStorageBrowserDB.transparency)
    end
end

panel.cancel = function(self)
    if self.transparencySlider then
        self.transparencySlider:SetValue((ItemStorageBrowserDB.transparency or 1) * 10)
    end
end

-- Регистрируем панель в интерфейсе параметров
InterfaceOptions_AddCategory(panel)

-- Инициализируем содержимое панели при первом показе
panel:SetScript("OnShow", function(self)
    if self.initialized then return end
    
    -- Заголовок
    local title = self:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Складской аддон гильдии Phoenix Nest")
    
    -- Лейбл для ползунка
    local sliderLabel = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sliderLabel:SetPoint("TOPLEFT", 16, -60)
    sliderLabel:SetText("Прозрачность фона:")
    
    -- Создаем ползунок (0-10 с шагом 1 = 0.0-1.0 с шагом 0.1)
    local slider = CreateFrame("Slider", nil, self, "OptionsSliderTemplate")
    slider:SetSize(250, 17)
    slider:SetMinMaxValues(0, 10)
    slider:SetValueStep(1)
    slider:SetValue((ItemStorageBrowserDB.transparency or 1) * 10)
    slider:SetPoint("TOPLEFT", 16, -85)
    
    -- Текст текущего значения
    local valueText = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    valueText:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    valueText:SetWidth(50)
    valueText:SetText(string.format("%.1f", ItemStorageBrowserDB.transparency or 1))
    
    slider:SetScript("OnValueChanged", function(self, value)
        local realValue = value / 10
        valueText:SetText(string.format("%.1f", realValue))
        -- Применяем прозрачность в реальном времени
        if ItemStorageBrowser.frame then
            ItemStorageBrowser:SetFrameTransparency(realValue)
        end
    end)
    
    self.transparencySlider = slider
    
    -- Кнопка сброса позиции окна
    local resetButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    resetButton:SetSize(180, 25)
    resetButton:SetText("Центрировать окно")
    resetButton:SetPoint("TOPLEFT", 16, -130)
    resetButton:SetScript("OnClick", function()
        if ItemStorageBrowser.frame then
            ItemStorageBrowser.frame:ClearAllPoints()
            ItemStorageBrowser.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            print("Окно аддона отцентрировано.")
        end
    end)
    
    -- Описание
    local description = self:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    description:SetPoint("TOPLEFT", 16, -170)
    description:SetWidth(500)
    description:SetHeight(50)
    description:SetText("Используйте ползунок для изменения прозрачности фона аддона (0 - полностью прозрачно, 1 - полностью непрозрачно). Кнопка 'Центрировать окно' вернёт окно в центр экрана.")
    description:SetTextColor(0.7, 0.7, 0.7)
    
    self.initialized = true
end)

-- Функция для применения прозрачности - устанавливает альфу всему фрейму
function ItemStorageBrowser:SetFrameTransparency(alpha)
    if not self.frame then return end
    
    -- Ограничиваем значение альфы: 0 = полностью прозрачно, 1 = полностью непрозрачно
    alpha = math.max(0, math.min(1, alpha or 1))
    
    -- Устанавливаем альфу всему фрейму и его детям
    self.frame:SetAlpha(alpha)
end
