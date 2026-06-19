local addonName, ItemStorageBrowser = ...

-- Инициализация базы данных
ItemStorageBrowserDB = ItemStorageBrowserDB or {
    minimapAngle = 148.2497927517446,
    transparency = 1,
}

-- Основной фрейм аддона
local frame = CreateFrame("Frame", "ItemStorageBrowserFrame", UIParent)
frame:SetSize(600, 400)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

-- Настраиваем прозрачность фона
frame:SetBackdrop({
    bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
    tile = true, tileSize = 32,
})

-- Флаг для отслеживания состояния фокуса
frame.hasFocus = false

-- Заголовок
frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
frame.title:SetText("Складской аддон гильдии Phoenix Nest")
frame.title:SetTextColor(1, 1, 1, 1)

-- Кнопка закрытия
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

-- Уровень прозрачности фона (из параметров)
local function GetFrameAlpha()
    return ItemStorageBrowserDB.transparency or 1
end

-- Функция установки фокуса
function frame:SetFocus(hasFocus)
    self.hasFocus = hasFocus
    if hasFocus then
        self:EnableKeyboard(true)
    else
        self:EnableKeyboard(false)
    end
end

-- Инициализируем прозрачность при создании
frame:SetAlpha(GetFrameAlpha())

-- Обработчик клика по фрейму
frame:SetScript("OnMouseDown", function(self)
    self:SetFocus(true)
end)

-- Обработчик потери фокуса
frame:SetScript("OnHide", function(self)
    self:SetFocus(false)
end)

-- Глобальный обработчик Esc - закрывает окно независимо от фокуса
local function OnGlobalKeyDown(_, key)
    if key == "ESCAPE" and frame:IsShown() then
        frame:Hide()
        return false -- Блокируем дальнейшую обработку Esc
    end
    return true
end

-- Регистрируем глобальный обработчик клавиш
frame:RegisterEvent("GLOBAL_KEY_DOWN")
frame:SetScript("OnEvent", function(self, event, key)
    if event == "GLOBAL_KEY_DOWN" then
        OnGlobalKeyDown(key)
    end
end)

-- Обработчик клика вне фрейма
local function OnGlobalMouseUp(_, button)
    if frame:IsShown() and frame.hasFocus then
        local mouseFocus = GetMouseFocus()
        local isChild = false
        
        -- Проверяем, является ли элемент под курсором дочерним для нашего фрейма
        if mouseFocus then
            local parent = mouseFocus:GetParent()
            while parent do
                if parent == frame then
                    isChild = true
                    break
                end
                parent = parent:GetParent()
            end
        end
        
        -- Если клик был вне фрейма и его дочерних элементов
        if not isChild and mouseFocus ~= frame then
            frame:SetFocus(false)
            -- Снимаем фокус со всех дочерних элементов
            for i, child in ipairs({frame:GetChildren()}) do
                if child.HasFocus and child:HasFocus() then
                    child:ClearFocus()
                end
            end
        end
    end
end

-- Регистрируем обработчик клика
frame:RegisterEvent("GLOBAL_MOUSE_UP")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "GLOBAL_MOUSE_UP" then
        OnGlobalMouseUp(...)
    end
end)

-- Функция загрузки базы данных
function ItemStorageBrowser:LoadDatabase()
    if not ItemStorageDB then return end
    self.database = ItemStorageDB

    -- Заполняем устаревшее поле items, если база хранит только bank/bags.
    for _, character in ipairs(self.database) do
        if not character.items then
            character.items = ItemStorageBrowser:BuildCharacterItems(character)
        end
    end
end

function ItemStorageBrowser:BuildCharacterItems(character)
    local items_by_link = {}

    local function add_items(list)
        if not list then
            return
        end
        for _, item in ipairs(list) do
            if item and item.link then
                local existing = items_by_link[item.link]
                if existing then
                    existing.count = existing.count + (item.count or 0)
                else
                    items_by_link[item.link] = {
                        link = item.link,
                        name = item.name or "",
                        count = item.count or 0,
                    }
                end
            end
        end
    end

    add_items(character.items)
    if character.bags and character.bags.items then
        add_items(character.bags.items)
    end
    if character.bank and character.bank.items then
        add_items(character.bank.items)
    end

    local result = {}
    for _, item in pairs(items_by_link) do
        table.insert(result, item)
    end
    table.sort(result, function(a, b)
        return a.name < b.name
    end)
    return result
end

-- Экспортируем основной фрейм
ItemStorageBrowser.frame = frame

-- Экспортируем функцию для применения прозрачности - просто устанавливает альфу
function ItemStorageBrowser:SetFrameTransparency(alpha)
    if self.frame then
        -- Ограничиваем значение альфы: 0 = полностью прозрачно, 1 = полностью непрозрачно
        alpha = math.max(0, math.min(1, alpha or 1))
        self.frame:SetAlpha(alpha)
    end
end

-- Инициализация при загрузке
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event)
    ItemStorageBrowser:LoadDatabase()
    self:UnregisterEvent(event)
end)

-- Команды чата
SLASH_ITEMSTORAGEBROWSER1 = "/isb"
SlashCmdList["ITEMSTORAGEBROWSER"] = function(msg)
    if msg == "" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
            frame:SetFocus(true)
        end
    elseif msg == "show" then
        frame:Show()
        frame:SetFocus(true)
    elseif msg == "hide" then
        frame:Hide()
    else
        print("Используйте: /isb, /isb show, /isb hide")
    end
end