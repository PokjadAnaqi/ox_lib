--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class TextUIOptions
---@field position? 'right-center' | 'left-center' | 'top-center' | 'bottom-center';
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string;
---@field style? string | table;
---@field alignIcon? 'top' | 'center';

local isOpen = false
local currentText

local useLation = GetResourceState("lation_ui") == "started"

---@param text string
---@param options? TextUIOptions
function lib.showTextUI(text, options)
    if useLation then
        local lationData = {
            description = text,
            position = options and options.position or 'right-center',
            icon = options and options.icon or nil,
            iconColor = options and options.iconColor or nil
        }
        
        exports.lation_ui:showText(lationData)
        isOpen = true
        currentText = text
        return
    end

    if currentText == text then return end

    if not options then 
        options = { position = 'right-center' }
    else
        options.position = options.position or 'right-center'
    end

    options.text = text
    currentText = text

    SendNUIMessage({
        action = 'textUi',
        data = options
    })

    isOpen = true
end

function lib.hideTextUI()
    if useLation then
        exports.lation_ui:hideText()
        isOpen = false
        currentText = nil
        return
    end

    SendNUIMessage({
        action = 'textUiHide'
    })

    isOpen = false
    currentText = nil
end

---@return boolean, string | nil
function lib.isTextUIOpen()
    if useLation then
        return exports.lation_ui:isOpen(), currentText
    else
        return isOpen, currentText
    end
end
