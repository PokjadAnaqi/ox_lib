--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local contextMenus = {}
local openContextMenu = nil

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any

---@class ContextMenuArrayItem : ContextMenuItem
---@field title string

---@class ContextMenuProps
---@field id string
---@field title string
---@field menu? string
---@field onExit? fun()
---@field onBack? fun()
---@field canClose? boolean
---@field options { [string]: ContextMenuItem } | ContextMenuArrayItem[]

local useLation = GetResourceState("lation_ui") == "started"

local function closeContext(_, cb, onExit)
    if useLation then
        if not openContextMenu then return end
        exports.lation_ui:hideMenu()
    else
        if cb then cb(1) end
        lib.resetNuiFocus()

        if not openContextMenu then return end

        if (cb or onExit) and contextMenus[openContextMenu].onExit then
            contextMenus[openContextMenu].onExit()
        end

        if not cb then
            SendNUIMessage({ action = 'hideContext' })
        end
    end

    openContextMenu = nil
end

---@param id string
function lib.showContext(id)
    if type(id) == "table" and id.id then
        id = id.id
    end

    if type(id) ~= "string" then
        error(("Invalid menu ID passed to showContext: expected string, got %s"):format(type(id)))
    end

    local menu = contextMenus[id]
    if not menu then
        error(('No context menu found for id: %s'):format(id))
    end

    openContextMenu = id

    if useLation then
        exports.lation_ui:showMenu(id)
    else
        lib.setNuiFocus(false)
        SendNuiMessage(json.encode({
            action = 'showContext',
            data = {
                title = menu.title,
                canClose = menu.canClose,
                menu = menu.menu,
                options = menu.options
            }
        }, { sort_keys = true }))
    end
end

---@param context ContextMenuProps | ContextMenuProps[]
function lib.registerContext(context)
    for k, v in pairs(context) do
        local menu = type(k) == 'number' and v or context

        if not menu.id then
            error('Menu must have an ID')
        end

        contextMenus[menu.id] = menu

        if useLation and menu.options then
            for _, item in ipairs(menu.options) do
                if item.icon and type(item.icon) == 'string' and item.icon:find("^fa%-solid%s") then
                    item.icon = item.icon:gsub("^fa%-solid%s*", "fas ")
                end
            end

            exports.lation_ui:registerMenu({
                id = menu.id,
                title = menu.title or '',
                subtitle = menu.subtitle or '',
                canClose = menu.canClose ~= false,
                position = menu.position or "offcenter-right",
                onExit = type(menu.onExit) == 'function' and menu.onExit or nil,
                options = menu.options
            })
        end

        if type(k) ~= 'number' then break end
    end
end

---@return string?
function lib.getOpenContextMenu() return openContextMenu end

---@param onExit boolean?
function lib.hideContext(onExit) closeContext(nil, nil, onExit) end

RegisterNUICallback('openContext', function(data, cb)
    if data.back and contextMenus[openContextMenu].onBack then contextMenus[openContextMenu].onBack() end
    cb(1)
    lib.showContext(data.id)
end)

RegisterNUICallback('clickContext', function(id, cb)
    cb(1)

    if math.type(tonumber(id)) == 'float' then
        id = math.tointeger(id)
    elseif tonumber(id) then
        id += 1
    end

    local data = contextMenus[openContextMenu].options[id]

    if not data.event and not data.serverEvent and not data.onSelect then return end

    openContextMenu = nil

    if not useLation then
        SendNUIMessage({ action = 'hideContext' })
        lib.resetNuiFocus()
    end

    if data.onSelect then data.onSelect(data.args) end
    if data.event then TriggerEvent(data.event, data.args) end
    if data.serverEvent then TriggerServerEvent(data.serverEvent, data.args) end
end)

RegisterNUICallback('closeContext', closeContext)
