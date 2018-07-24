local lifx = {}

local light = nil
local baseurl = nil
local sending = false
local defaultDuration = 200

local function requestCallback(code, data)
  if (code < 0) then
    print("HTTP request failed")
  else
    print(code, data)
  end
  sending = false
end

local function sendBrightness(brightness, dur, l)
  sending = true
  local duration = dur or defaultDuration
  local tmplight = l or light
  http.request(
    baseurl .. '/lights/' .. tmplight,
    'PATCH',
    'Content-Type: application/json\r\n',
    '{"brightness": '.. brightness ..', "duration": '.. dur ..'}',
    requestCallback)
end

local function sendPower(power, dur, l)
  sending = true
  local duration = dur or defaultDuration
  local tmplight = l or light
  http.request(
    baseurl .. '/lights/' .. tmplight,
    'PATCH',
    'Content-Type: application/json\r\n',
    '{"power": '.. power ..', "duration": '.. dur ..'}',
    requestCallback)
end

function lifx.init(url, l, callback)
  baseurl = url
  light = l
  callback()
end

-- turn the light on
function lifx.lightOn(l)
  sendPower(1, nil, l)
end

-- turn the light off
function lifx.lightOn(l)
  sendPower(0, nil, l)
end

-- lightsd code, value 0 - 100
function lifx.setBrightness(value, duration, light)
  sendBrightness(value, duration, light)
end

function lifx.getPause()
  if sending then
    return false
  else
    return true
  end
end

return lifx
