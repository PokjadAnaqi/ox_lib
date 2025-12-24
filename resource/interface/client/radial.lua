--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class RadialItem
---@field icon string | {[1]: IconProp, [2]: string};
---@field label string
---@field menu? string
---@field onSelect? fun(currentMenu: string | nil, itemIndex: number) | string
---@field [string] any
---@field keepOpen? boolean
---@field iconWidth? number
---@field iconHeight? number

---@class RadialMenuItem: RadialItem
---@field id string

---@class RadialMenuProps
---@field id string
---@field items RadialItem[]
---@field [string] any

---@type table<string, RadialMenuProps>
local menus = {}

---@type RadialMenuItem[]
local menuItems = {}

---Registers a radial sub menu with predefined options.
---@param radial RadialMenuProps
function lib.registerRadial(radial)
    menus[radial.id] = radial
    radial.resource = GetInvokingResource()

    exports.lation_ui:registerRadial({
        id = radial.id,
        items = radial.items
    })
end

function lib.getCurrentRadialId()
    return exports.lation_ui:getCurrentRadialId()
end

function lib.hideRadial()
    exports.lation_ui:hideRadial()
end

---Registers an item or array of items in the global radial menu.
---@param items RadialMenuItem | RadialMenuItem[]
function lib.addRadialItem(items)
    local invokingResource = GetInvokingResource()

    items = table.type(items) == 'array' and items or { items }

    for i = 1, #items do
        local item = items[i]
        item.resource = invokingResource

        -- Convert icon format if needed (ox_lib uses different format)
        if item.icon and type(item.icon) == 'table' then
            item.icon = item.icon[1] .. ' ' .. item.icon[2]
        end

        exports.lation_ui:addRadialItem(item)
    end
end

---Removes an item from the global radial menu with the given id.
---@param id string
function lib.removeRadialItem(id)
    exports.lation_ui:removeRadialItem(id)
end

---Removes all items from the global radial menu.
function lib.clearRadialItems()
    table.wipe(menuItems)
    exports.lation_ui:clearRadialItems()
end

local isDisabled = false

---Disallow players from opening the radial menu.
---@param state boolean
function lib.disableRadial(state)
    isDisabled = state
    exports.lation_ui:disableRadial(state)
end

AddEventHandler('onClientResourceStop', function(resource)
    for i = #menuItems, 1, -1 do
        local item = menuItems[i]

        if item.resource == resource then
            table.remove(menuItems, i)
        end
    end
end)
