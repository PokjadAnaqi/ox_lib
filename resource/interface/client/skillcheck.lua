--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@type promise?
local skillcheck

local useLation = GetResourceState("lation_ui") == "started"

---@alias SkillCheckDifficulity 'easy' | 'medium' | 'hard' | { areaSize: number, speedMultiplier: number }

---@param difficulty SkillCheckDifficulity | SkillCheckDifficulity[]
---@param inputs string[]?
---@return boolean?
function lib.skillCheck(difficulty, inputs)
    if useLation then
        local title = "Skill Check"
        local difficulties = {}
        
        if type(difficulty) == 'string' then
            difficulties = {difficulty}
        elseif type(difficulty) == 'table' then
            if difficulty.areaSize and difficulty.speedMultiplier then
                if difficulty.areaSize > 20 and difficulty.speedMultiplier < 1.5 then
                    difficulties = {'easy'}
                elseif difficulty.areaSize > 15 and difficulty.speedMultiplier < 2 then
                    difficulties = {'medium'}
                else
                    difficulties = {'hard'}
                end
            else
                for _, diff in ipairs(difficulty) do
                    if type(diff) == 'string' then
                        table.insert(difficulties, diff)
                    elseif type(diff) == 'table' and diff.areaSize and diff.speedMultiplier then
                        if diff.areaSize > 20 and diff.speedMultiplier < 1.5 then
                            table.insert(difficulties, 'easy')
                        elseif diff.areaSize > 15 and diff.speedMultiplier < 2 then
                            table.insert(difficulties, 'medium')
                        else
                            table.insert(difficulties, 'hard')
                        end
                    end
                end
            end
        end
        
        return exports.lation_ui:skillCheck(title, difficulties, inputs)
    end

    if skillcheck then return end
    skillcheck = promise:new()

    lib.setNuiFocus(false, true)
    SendNUIMessage({
        action = 'startSkillCheck',
        data = {
            difficulty = difficulty,
            inputs = inputs
        }
    })

    return Citizen.Await(skillcheck)
end

function lib.cancelSkillCheck()
    if not skillcheck then
        error('No skillCheck is active')
    end

    if useLation then
        exports.lation_ui:cancelSkillCheck()
    else
        SendNUIMessage({action = 'skillCheckCancel'})
    end
end

---@return boolean
function lib.skillCheckActive()
    if useLation then
        return exports.lation_ui:skillCheckActive()
    else
        return skillcheck ~= nil
    end
end

RegisterNUICallback('skillCheckOver', function(success, cb)
    cb(1)

    if skillcheck then
        if not useLation then
            lib.resetNuiFocus()
        end

        skillcheck:resolve(success)
        skillcheck = nil
    end
end)
