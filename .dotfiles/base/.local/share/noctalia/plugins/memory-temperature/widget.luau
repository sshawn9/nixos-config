--!nonstrict

local function discoverSensors()
    local base = "/sys/class/hwmon/"
    local discovered = {}
    for _, entry in ipairs(noctalia.listDir(base) or {}) do
        local index = tonumber(entry:match("^hwmon(%d+)$"))
        if index then
            local directory = base .. entry .. "/"
            local name = noctalia.readFile(directory .. "name")
            local path = directory .. "temp1_input"
            if name and name:match("^%s*spd5118%s*$") and noctalia.fileExists(path) then
                table.insert(discovered, { path = path, index = index })
            end
        end
    end
    table.sort(discovered, function(a, b) return a.index < b.index end)
    return discovered
end

local sensors = discoverSensors()

local function temperatureColor(temperature)
    if temperature == nil or temperature <= 80 then
        return "#D1D1C7"
    end
    if temperature >= 90 then
        return "#D95757"
    end

    local factor = 0.25 + 0.75 * (temperature - 80) / 10
    -- Noctalia's chroma-weighted HSV blend, for Ayu dark's #D1D1C7 -> #D95757.
    -- Both hues lie in the red/yellow sector, so RGB follows directly from HSV.
    local normalChroma = 209 - 199
    local warningChroma = 217 - 87
    local saturation = (1 - factor) * normalChroma / 209 + factor * warningChroma / 217
    local brightness = 209 + (217 - 209) * factor
    local hueWeight = factor * warningChroma / ((1 - factor) * normalChroma + factor * warningChroma)
    local chroma = brightness * saturation
    return string.format("#%02X%02X%02X",
        math.floor(brightness + 0.5),
        math.floor(brightness - chroma * hueWeight + 0.5),
        math.floor(brightness - chroma + 0.5))
end

function update()
    local children = {}
    for _, sensor in ipairs(sensors) do
        local contents = noctalia.readFile(sensor.path)
        local value = contents and tonumber(contents)
        local temperature = value and value / 1000
        local text = temperature ~= nil and string.format("%.0f°C", temperature) or "--°C"
        local color = temperatureColor(temperature)
        table.insert(children, ui.glyph({ name = "temperature", color = color }))
        table.insert(children, ui.label({ text = text, color = color }))
    end
    barWidget.render(ui.row({ gap = 4, align = "center" }, children))
end

barWidget.setVisible(#sensors > 0)
noctalia.setUpdateInterval(1000)
update()
