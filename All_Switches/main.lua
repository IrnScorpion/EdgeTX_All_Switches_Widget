local path = "/WIDGETS/All_Switches/"
local ver, radio, maj, minor, rev, osname = getVersion()
local radio_name = radio or "TX16S"

local radioCfg = { sw = {} }
local cachedgetCustomFunction = {}
local last_model = ""
local globalLabels = {}
local modelLabels = {}
local config_availible = 0
local last_run = 0

local defaultOptions = {
  { "box_color", COLOR, BLACK },
  { "border_color", COLOR, WHITE },
  { "active_txt", COLOR, COLOR_THE_FOCUS },
  { "inactive_txt", COLOR, WHITE },
  { "refresh_ms", VALUE, 100, 50, 1000 },
  { "auto_hide", BOOL, 0 },
}

local function getSwitchIndex(name)
    if name == nil then return nil end
    local i = getFieldInfo(name)
    return i and i.id or nil
end

-- New Layered Drawing Logic for Perfect Borders
local function drawManualRoundedBox(x, y, w, h, r, fillColor, borderColor)
    local maxR = math.min(w, h) / 2
    if r > maxR then r = maxR end

    -- STEP 1: Draw the Border Layer (Slightly larger circles and rects)
    lcd.drawFilledRectangle(x + r, y, w - (2 * r), h, borderColor)
    lcd.drawFilledRectangle(x, y + r, w, h - (2 * r), borderColor)
    lcd.drawFilledCircle(x + r, y + r, r, borderColor)
    lcd.drawFilledCircle(x + w - r - 1, y + r, r, borderColor)
    lcd.drawFilledCircle(x + r, y + h - r - 1, r, borderColor)
    lcd.drawFilledCircle(x + w - r - 1, y + h - r - 1, r, borderColor)

    -- STEP 2: Draw the Inner Fill (1 pixel smaller all around)
    local innerR = math.max(0, r - 1)
    lcd.drawFilledRectangle(x + r, y + 1, w - (2 * r), h - 2, fillColor)
    lcd.drawFilledRectangle(x + 1, y + r, w - 2, h - (2 * r), fillColor)
    lcd.drawFilledCircle(x + r, y + r, innerR, fillColor)
    lcd.drawFilledCircle(x + w - r - 1, y + r, innerR, fillColor)
    lcd.drawFilledCircle(x + r, y + h - r - 1, innerR, fillColor)
    lcd.drawFilledCircle(x + w - r - 1, y + h - r - 1, innerR, fillColor)
end

local function getLabelText(switchinputname)
    if not switchinputname then return nil end
    if modelLabels and modelLabels[switchinputname] then return modelLabels[switchinputname] end
    if globalLabels and globalLabels[switchinputname] then return globalLabels[switchinputname] end
    return nil
end

local function cacheCustomFunctions()
    cachedgetCustomFunction = {}
    for i = 0, 63 do
        local mySF = model.getCustomFunction(i)
        if mySF and mySF.switch ~= 0 and mySF.active ~= 0 then
            cachedgetCustomFunction[mySF.switch] = mySF
        end
    end
end

local function loadLabelFiles(modelName)
    local gChunk = loadfile(path .. "labels/global.lua")
    globalLabels = gChunk and gChunk() or {}
    local mChunk = loadfile(path .. "labels/" .. modelName .. ".lua")
    modelLabels = mChunk and mChunk() or {}
end

local function processSwitch(widget, switch, switchcfgname, switch_value, switchType, offsetY, boxW)
    if not widget or not widget.options or not switch or not switch[switchType] then return end
    
    local fullSwitchName = switchcfgname .. switch[switchType]
    local sIdx = getSwitchIndex(fullSwitchName)
    local customFunc = sIdx and cachedgetCustomFunction[sIdx] or nil
    
    local labelText = getLabelText(switchcfgname .. switchType)
    if not labelText and customFunc and customFunc.func == 11 then
        labelText = customFunc.name
    end
    
    if labelText then
        local isActive = (switchType == "u" and switch_value < 0) or 
                         (switchType == "m" and switch_value == 0) or 
                         (switchType == "d" and switch_value > 0)

        local textColor = isActive and (widget.options.active_txt or COLOR_THE_FOCUS) or (widget.options.inactive_txt or WHITE)
        local w_text, h_text = lcd.sizeText(labelText, SMLSIZE)
        lcd.drawText(switch.switchcfgpos_x + (boxW - w_text) / 2, switch.switchcfgpos_y + offsetY, labelText, SMLSIZE + textColor)
    end
end

local function refreshWidget(widgetToRefresh)
    if not widgetToRefresh or not widgetToRefresh.options then return end
    local now = getTime() 
    local interval = (widgetToRefresh.options.refresh_ms or 100) / 10
    local info = model.getInfo()
    if not info or not info.name then return end
    
    if last_model ~= info.name or (now - last_run > interval) then
        cacheCustomFunctions()
        loadLabelFiles(info.name)
        last_model = info.name
        last_run = now
    end

    if config_availible > 0 and radioCfg and radioCfg.sw then
        for i, switch in ipairs(radioCfg.sw) do
            local sName = switch.switchcfgname
            local val = getValue(sName) or 0
            
            local hasAnyLabel = getLabelText(sName .. "u") or getLabelText(sName .. "m") or getLabelText(sName .. "d")
            
            if widgetToRefresh.options.auto_hide == 0 or hasAnyLabel then
                local pX, pY = switch.switchcfgpos_x or 0, switch.switchcfgpos_y or 0
                local bW, bH = radioCfg.switch_box_size_x or 100, radioCfg.switch_box_size_y or 50
                local rad = radioCfg.switch_box_size_radius or 6

                drawManualRoundedBox(pX, pY, bW, bH, rad, widgetToRefresh.options.box_color or BLACK, widgetToRefresh.options.border_color or WHITE)
                lcd.drawText(pX + 6, pY + 3, string.sub(sName, 2), SMLSIZE + INVERS)

                processSwitch(widgetToRefresh, switch, sName, val, "u", radioCfg.pos_switch_offset_up or 12, bW)
                processSwitch(widgetToRefresh, switch, sName, val, "m", radioCfg.pos_switch_offset_center or 24, bW)
                processSwitch(widgetToRefresh, switch, sName, val, "d", radioCfg.pos_switch_offset_down or 36, bW)
            end
        end
    end
end

local function createWidget(zone, options)
    local cleanName = string.gsub(radio_name, "-simu", "")
    local radioFile = path .. "radio/" .. cleanName .. ".lua"
    local chunk = loadfile(radioFile)
    if chunk then 
        radioCfg = chunk()
        config_availible = 1
    else
        radioCfg = { sw = {} }
        config_availible = 0
    end
    return { zone=zone, options=options }
end

local function updateWidget(widgetToUpdate, newOptions)
    widgetToUpdate.options = newOptions
end

return { name="All_Switches", options=defaultOptions, create=createWidget, update=updateWidget, refresh=refreshWidget }